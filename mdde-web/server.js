const express = require('express');
const multer = require('multer');
const cors = require('cors');
const fs = require('fs-extra');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.static('.')); // 提供静态文件服务

// 配置文件上传
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // 从URL路径中提取目录名
    const dirName = req.params.dirName;
    const uploadPath = path.join(__dirname, 'scripts', dirName);
    
    // 确保目录存在
    fs.ensureDirSync(uploadPath);
    cb(null, uploadPath);
  },
  filename: function (req, file, cb) {
    // 保持原始文件名
    cb(null, file.originalname);
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 限制文件大小为10MB
  }
});

// 1. 基础脚本下载接口
app.get('/download/env-build.ps1', (req, res) => {
  const filePath = path.join(__dirname, 'env-build.ps1');
  if (fs.existsSync(filePath)) {
    res.download(filePath);
  } else {
    res.status(404).json({ error: '文件不存在' });
  }
});

app.get('/download/env-build.sh', (req, res) => {
  const filePath = path.join(__dirname, 'env-build.sh');
  if (fs.existsSync(filePath)) {
    res.download(filePath);
  } else {
    res.status(404).json({ error: '文件不存在' });
  }
});

// 2. 下载scripts目录下的脚本（整个目录）
app.get('/get/:dirName', async (req, res) => {
  try {
    const dirName = req.params.dirName;
    const scriptsDir = path.join(__dirname, 'scripts', dirName);
    
    if (!fs.existsSync(scriptsDir)) {
      return res.status(404).json({ error: `目录 ${dirName} 不存在` });
    }
    
    // 创建临时zip文件
    const archiver = require('archiver');
    const zipPath = path.join(__dirname, 'temp', `${dirName}_scripts.zip`);
    
    // 确保temp目录存在
    await fs.ensureDir(path.join(__dirname, 'temp'));
    
    const output = fs.createWriteStream(zipPath);
    const archive = archiver('zip', { zlib: { level: 9 } });
    
    output.on('close', () => {
      res.download(zipPath, `${dirName}_scripts.zip`, (err) => {
        // 下载完成后删除临时文件
        fs.removeSync(zipPath);
      });
    });
    
    archive.on('error', (err) => {
      res.status(500).json({ error: '创建压缩文件失败' });
    });
    
    archive.pipe(output);
    archive.directory(scriptsDir, false);
    archive.finalize();
    
  } catch (error) {
    console.error('下载脚本错误:', error);
    res.status(500).json({ error: '下载失败' });
  }
});

// 2.1. 下载scripts目录下的指定文件
app.get('/get/:dirName/:filename', async (req, res) => {
  try {
    const dirName = req.params.dirName;
    const filename = req.params.filename;
    const filePath = path.join(__dirname, 'scripts', dirName, filename);
    
    // 安全检查：确保路径在scripts目录内
    const normalizedPath = path.normalize(filePath);
    const scriptsDir = path.join(__dirname, 'scripts');
    if (!normalizedPath.startsWith(scriptsDir)) {
      return res.status(403).json({ error: '访问被拒绝' });
    }
    
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: `文件 ${filename} 在目录 ${dirName} 中不存在` });
    }
    
    // 检查是否为文件
    const stats = await fs.stat(filePath);
    if (!stats.isFile()) {
      return res.status(400).json({ error: `${filename} 不是一个文件` });
    }
    
    // 设置响应头
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    
    // 流式传输文件
    const fileStream = fs.createReadStream(filePath);
    fileStream.pipe(res);
    
    fileStream.on('error', (error) => {
      console.error('文件读取错误:', error);
      if (!res.headersSent) {
        res.status(500).json({ error: '文件读取失败' });
      }
    });
    
  } catch (error) {
    console.error('下载文件错误:', error);
    if (!res.headersSent) {
      res.status(500).json({ error: '下载失败' });
    }
  }
});

// 3. 上传脚本到指定目录
app.post('/upload/:dirName', upload.single('script'), async (req, res) => {
  try {
    const dirName = req.params.dirName;
    
    if (!req.file) {
      return res.status(400).json({ error: '没有上传文件' });
    }
    
    const filePath = req.file.path;
    const fileName = req.file.originalname;
    
    res.json({ 
      message: '上传成功',
      fileName: fileName,
      dirName: dirName,
      filePath: filePath
    });
    
  } catch (error) {
    console.error('上传脚本错误:', error);
    res.status(500).json({ error: '上传失败' });
  }
});

// 4. 列出可用的脚本目录
app.get('/list', async (req, res) => {
  try {
    const scriptsDir = path.join(__dirname, 'scripts');
    
    if (!fs.existsSync(scriptsDir)) {
      return res.json({ directories: [] });
    }
    
    const items = await fs.readdir(scriptsDir, { withFileTypes: true });
    const directories = items
      .filter(item => item.isDirectory())
      .map(dir => {
        const dirPath = path.join(scriptsDir, dir.name);
        return {
          name: dir.name,
          path: dirPath,
          scripts: fs.readdirSync(dirPath).filter(file => 
            fs.statSync(path.join(dirPath, file)).isFile()
          )
        };
      });
    
    res.json({ directories });
    
  } catch (error) {
    console.error('列出脚本错误:', error);
    res.status(500).json({ error: '获取列表失败' });
  }
});

// 5. 获取特定目录下的脚本列表
app.get('/list/:dirName', async (req, res) => {
  try {
    const dirName = req.params.dirName;
    const scriptsDir = path.join(__dirname, 'scripts', dirName);
    
    if (!fs.existsSync(scriptsDir)) {
      return res.status(404).json({ error: `目录 ${dirName} 不存在` });
    }
    
    const files = await fs.readdir(scriptsDir);
    const scripts = files.filter(file => 
      fs.statSync(path.join(scriptsDir, file)).isFile()
    );
    
    res.json({ 
      directory: dirName,
      scripts: scripts
    });
    
  } catch (error) {
    console.error('获取目录脚本列表错误:', error);
    res.status(500).json({ error: '获取列表失败' });
  }
});

// 6. 删除脚本文件
app.delete('/delete/:dirName/:fileName', async (req, res) => {
  try {
    const { dirName, fileName } = req.params;
    const filePath = path.join(__dirname, 'scripts', dirName, fileName);
    
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: '文件不存在' });
    }
    
    await fs.remove(filePath);
    res.json({ message: '删除成功' });
    
  } catch (error) {
    console.error('删除脚本错误:', error);
    res.status(500).json({ error: '删除失败' });
  }
});

// 健康检查接口
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        uptime: process.uptime()
    });
});

// 启动服务器
app.listen(PORT, () => {
    console.log(`🚀 MDDE Web 服务器运行在端口 ${PORT}`);
    console.log(`📁 脚本目录: ${path.join(__dirname, 'scripts')}`);
    console.log(`🌐 访问地址: http://localhost:${PORT}`);
    console.log(`💚 健康检查: http://localhost:${PORT}/health`);
    console.log(`📥 下载目录: http://localhost:${PORT}/get/{dirName}`);
    console.log(`📄 下载文件: http://localhost:${PORT}/get/{dirName}/{filename}`);
    console.log(`📤 上传文件: http://localhost:${PORT}/upload/{dirName}`);
    console.log(`📋 查看列表: http://localhost:${PORT}/list`);
});

module.exports = app;

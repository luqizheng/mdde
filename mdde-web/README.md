# MDDE Web 服务器

MDDE (Multi-Development Docker Environment) Web 服务器是一个基于 Node.js 的脚本管理平台，提供开发环境脚本的上传、下载和管理功能。

## 🚀 功能特性

### 1. 基础脚本下载
- 提供 `mdde.ps1` (Windows PowerShell) 和 `mdde.sh` (Linux/macOS) 的下载
- 访问地址：`/download/mdde.ps1` 和 `/download/mdde.sh`


### 2. 脚本下载
- **目录下载**: 通过 `GET /get/{dirName}` 下载指定目录下的所有脚本（ZIP格式）
- **文件下载**: 通过 `GET /get/{dirName}/{filename}` 下载指定目录下的特定文件
- 例如：`/get/net9` 下载整个目录，`/get/net9/script.ps1` 下载特定文件

### 3. 脚本上传
- 通过 `POST /upload/{dirName}` 上传脚本到指定目录
- 自动创建目录（如果不存在）
- 支持拖拽上传
- 例如：`/upload/net9_kudi` 创建 `scripts/net9_kudi` 目录并上传脚本

### 4. 脚本列表查询
- `GET /list` - 列出所有可用的脚本目录
- `GET /list/{dirName}` - 列出指定目录下的脚本文件

### 5. 脚本删除
- `DELETE /delete/{dirName}/{fileName}` - 删除指定的脚本文件

## 🛠️ 安装和运行

### 前置要求
- Node.js 16+ 
- npm 或 yarn

### 快速启动

1. **安装依赖**
   ```bash
   npm install
   ```

2. **启动服务器**
   ```bash
   npm start
   ```
   
   或者使用 PowerShell 脚本：
   ```powershell
   .\start.ps1
   ```

3. **访问网站**
   - 主页：http://localhost:3000
   - 管理界面：http://localhost:3000/admin.html

## 📁 目录结构

```
mdde-web/
├── server.js          # 主服务器文件
├── package.json       # 项目配置
├── start.ps1         # PowerShell 启动脚本
├── admin.html        # 管理界面
├── index.html        # 主页
├── mdde.ps1     # Windows 环境构建脚本
├── mdde.sh      # Linux/macOS 环境构建脚本
├── scripts/          # 脚本存储目录
├── ├── default/      # 默认脚本，必定和其他一起下载
├── ├── ├── run.sh      # 在容器下执行 命令
├── ├── ├── start.sh    # 启动容器
├── ├── ├── stop.sh     # 停止容器
├── ├── ├── restart.sh  # 重启容器。
│   ├── dotnet6/      # .NET 6 脚本
│   ├── dotnet9/      # .NET 9 脚本
│   └── java17/       # Java 17 脚本
└── temp/             # 临时文件目录（自动创建）
```








## 🔌 API 接口

### 基础脚本下载
```
GET /download/env-build.ps1
GET /download/env-build.sh
```

### 脚本下载
```
GET /get/{dirName}           # 下载整个目录（ZIP格式）
GET /get/{dirName}/{filename} # 下载指定文件
```
**参数：**
- `dirName`: 目录名称（如：net9, java17）
- `filename`: 文件名（如：script.ps1, run.sh）

**示例：**
- `/get/dotnet9` - 下载 dotnet9 目录下的所有脚本
- `/get/dotnet9/example.ps1` - 下载 dotnet9 目录下的 example.ps1 文件

**响应：** ZIP 文件下载

### 脚本上传
```
POST /upload/{dirName}
```
**参数：**
- `dirName`: 目标目录名称
- `script`: 脚本文件（multipart/form-data）

**响应：**
```json
{
  "message": "上传成功",
  "fileName": "script.ps1",
  "dirName": "net9_kudi",
  "filePath": "/path/to/file"
}
```

### 脚本列表查询
```
GET /list
```
**响应：**
```json
{
  "directories": [
    {
      "name": "net9",
      "path": "/path/to/scripts/net9",
      "scripts": ["script1.ps1", "script2.sh"]
    }
  ]
}
```

```
GET /list/{dirName}
```
**响应：**
```json
{
  "directory": "net9",
  "scripts": ["script1.ps1", "script2.sh"]
}
```

### 脚本删除
```
DELETE /delete/{dirName}/{fileName}
```
**响应：**
```json
{
  "message": "删除成功"
}
```

## 🌐 使用示例

### 使用 curl 上传脚本
```bash
curl -X POST -F "script=@my-script.ps1" http://localhost:3000/upload/net9_kudi
```

### 使用 curl 下载脚本目录
```bash
curl -O -J http://localhost:3000/get/net9
```

### 使用 curl 获取脚本列表
```bash
curl http://localhost:3000/list
```

## 🔧 配置选项

### 环境变量
- `PORT`: 服务器端口（默认：3000）

### 文件大小限制
- 单个脚本文件最大：10MB

### 支持的文件类型
- PowerShell: `.ps1`
- Bash: `.sh`
- Batch: `.bat`, `.cmd`
- Python: `.py`
- JavaScript: `.js`
- 文本文件: `.txt`, `.md`
- 其他类型文件

## 🚨 注意事项

1. **安全性**: 当前版本没有身份验证，请在内网环境使用
2. **文件覆盖**: 上传同名文件会覆盖现有文件
3. **目录删除**: 删除目录操作不可恢复
4. **临时文件**: 下载时创建的 ZIP 文件会在下载完成后自动删除

## 🐛 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 查看端口占用
   netstat -ano | findstr :3000
   
   # 修改端口
   set PORT=3001
   npm start
   ```

2. **权限问题**
   - 确保对 `scripts` 目录有读写权限
   - Windows 下可能需要以管理员身份运行

3. **依赖安装失败**
   ```bash
   # 清除缓存
   npm cache clean --force
   
   # 重新安装
   rm -rf node_modules package-lock.json
   npm install
   ```

## 📝 更新日志

### v1.0.0
- 初始版本
- 支持脚本上传、下载、列表查询
- 提供 Web 管理界面
- 支持拖拽上传
- 自动目录创建

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

# MDDE Web 服务器 API 使用示例

## 🚀 快速开始

### 1. 启动服务器
```bash
# 安装依赖
npm install

# 启动服务器
npm start
```

服务器将在 http://localhost:3000 启动

## 📥 下载功能

### 下载整个目录（ZIP格式）
```bash
# 使用 curl
curl -O "http://localhost:3000/get/dotnet9"

# 使用 PowerShell
Invoke-WebRequest -Uri "http://localhost:3000/get/dotnet9" -OutFile "dotnet9_scripts.zip"

# 使用 wget
wget "http://localhost:3000/get/dotnet9" -O "dotnet9_scripts.zip"
```

### 下载特定文件
```bash
# 使用 curl
curl -O "http://localhost:3000/get/dotnet9/example.ps1"

# 使用 PowerShell
Invoke-WebRequest -Uri "http://localhost:3000/get/dotnet9/example.ps1" -OutFile "example.ps1"

# 使用 wget
wget "http://localhost:3000/get/dotnet9/example.ps1" -O "example.ps1"
```

## 📤 上传功能

### 上传文件到指定目录
```bash
# 使用 curl
curl -X POST -F "script=@local_script.ps1" "http://localhost:3000/upload/dotnet9"

# 使用 PowerShell
$form = @{
    script = Get-Item "local_script.ps1"
}
Invoke-RestMethod -Uri "http://localhost:3000/upload/dotnet9" -Method Post -Form $form
```

## 📋 查询功能

### 获取所有目录列表
```bash
# 使用 curl
curl "http://localhost:3000/list"

# 使用 PowerShell
Invoke-RestMethod -Uri "http://localhost:3000/list" -Method Get
```

### 获取特定目录的文件列表
```bash
# 使用 curl
curl "http://localhost:3000/list/dotnet9"

# 使用 PowerShell
Invoke-RestMethod -Uri "http://localhost:3000/list/dotnet9" -Method Get
```

## 🗑️ 删除功能

### 删除指定文件
```bash
# 使用 curl
curl -X DELETE "http://localhost:3000/delete/dotnet9/example.ps1"

# 使用 PowerShell
Invoke-RestMethod -Uri "http://localhost:3000/delete/dotnet9/example.ps1" -Method Delete
```

## 🔍 健康检查

### 检查服务器状态
```bash
# 使用 curl
curl "http://localhost:3000/health"

# 使用 PowerShell
Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get
```

## 📱 前端使用示例

### JavaScript 下载文件
```javascript
// 下载整个目录
async function downloadDirectory(dirName) {
    try {
        const response = await fetch(`/get/${dirName}`);
        if (response.ok) {
            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `${dirName}_scripts.zip`;
            a.click();
            window.URL.revokeObjectURL(url);
        }
    } catch (error) {
        console.error('下载失败:', error);
    }
}

// 下载特定文件
async function downloadFile(dirName, filename) {
    try {
        const response = await fetch(`/get/${dirName}/${filename}`);
        if (response.ok) {
            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = filename;
            a.click();
            window.URL.revokeObjectURL(url);
        }
    } catch (error) {
        console.error('下载失败:', error);
    }
}
```

### JavaScript 上传文件
```javascript
async function uploadFile(dirName, file) {
    try {
        const formData = new FormData();
        formData.append('script', file);
        
        const response = await fetch(`/upload/${dirName}`, {
            method: 'POST',
            body: formData
        });
        
        if (response.ok) {
            const result = await response.json();
            console.log('上传成功:', result);
        }
    } catch (error) {
        console.error('上传失败:', error);
    }
}
```

## 🧪 测试脚本

### PowerShell 测试
```powershell
# 运行测试脚本
.\test-new-api.ps1
```

### Bash 测试
```bash
# 运行测试脚本
chmod +x test-new-api.sh
./test-new-api.sh
```

## 📊 响应格式

### 成功响应
```json
{
    "message": "操作成功",
    "fileName": "example.ps1",
    "dirName": "dotnet9",
    "filePath": "/path/to/file"
}
```

### 错误响应
```json
{
    "error": "错误描述"
}
```

### 目录列表响应
```json
{
    "directories": [
        {
            "name": "dotnet9",
            "path": "/path/to/dotnet9",
            "scripts": ["example.ps1", "run.sh"]
        }
    ]
}
```

## 🔒 安全特性

- **路径遍历防护**: 新API端点包含安全检查，防止访问scripts目录外的文件
- **文件类型验证**: 确保下载的是文件而不是目录
- **错误处理**: 完善的错误处理和状态码返回

## 🚨 注意事项

1. **文件大小限制**: 上传文件大小限制为10MB
2. **临时文件**: 下载目录时创建的ZIP文件会在下载完成后自动删除
3. **目录创建**: 上传到不存在的目录时会自动创建
4. **错误处理**: 所有API都包含适当的错误处理和状态码

## 📞 支持

如果遇到问题，请检查：
1. 服务器是否正在运行
2. 端口3000是否被占用
3. 文件路径是否正确
4. 网络连接是否正常

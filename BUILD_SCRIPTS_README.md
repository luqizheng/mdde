# MDDE 跨平台构建脚本使用指南

本目录包含用于构建 MDDE 命令行工具的跨平台构建脚本，支持 Windows、Linux 和 macOS 平台的编译，以及 Windows 安装包的生成。

## 📄 脚本说明

### build-installer.ps1 (PowerShell 脚本)
- **适用平台**: Windows (PowerShell 5.1+)
- **功能**: 使用 Docker 进行跨平台编译，生成 Windows 安装包
- **依赖**: Docker Desktop, Inno Setup (可选)

### build-installer.sh (Bash 脚本)  
- **适用平台**: Linux, macOS, Windows (WSL)
- **功能**: 使用 Docker 进行跨平台编译，支持 Windows 安装包生成
- **依赖**: Docker, Wine (生成 Windows 安装包时需要)

## 🚀 快速开始

### Windows 用户 (PowerShell)

```powershell
# 显示帮助信息
.\build-installer.ps1 -Help

# 完整构建（所有平台 + Windows 安装包）
.\build-installer.ps1

# 只构建，跳过安装包生成
.\build-installer.ps1 -SkipInstaller

# 清理构建文件
.\build-installer.ps1 -Clean
```

### Linux/macOS 用户 (Bash)

```bash
# 添加执行权限
chmod +x build-installer.sh

# 显示帮助信息
./build-installer.sh --help

# 完整构建（所有平台）
./build-installer.sh

# 只构建，跳过安装包生成
./build-installer.sh --skip-installer

# 清理构建文件  
./build-installer.sh --clean
```

## 🛠️ 构建环境要求

### 必需软件

1. **Docker**
   - Windows: Docker Desktop
   - Linux: Docker Engine
   - macOS: Docker Desktop
   - 确保 Docker 服务正在运行

2. **Git** (用于克隆项目)

### 可选软件

1. **Windows 安装包生成** (仅限 Windows)
   - Inno Setup 6.x
   - 下载地址: https://jrsoftware.org/isinfo.php
   - 安装后确保 `ISCC.exe` 在系统 PATH 中

2. **Wine** (Linux/macOS 生成 Windows 安装包时需要)
   - Ubuntu/Debian: `sudo apt install wine`
   - macOS: `brew install wine`

## 📦 支持的编译目标

| 平台 | 架构 | 输出文件 | 说明 |
|------|------|----------|------|
| Windows | x64 | mdde.exe | 包含安装包生成 |
| Linux | x64 | mdde | 静态链接可执行文件 |
| macOS | Intel x64 | mdde | 兼容 Intel 处理器 |
| macOS | Apple Silicon | mdde | 兼容 M1/M2 处理器 |

## 📁 输出结构

构建完成后，产物会保存在 `release-builds/` 目录中：

```
release-builds/
├── windows-x64/
│   └── mdde.exe
├── linux-x64/
│   └── mdde
├── macos-x64/
│   └── mdde
├── macos-arm64/
│   └── mdde
├── installers/
│   └── MDDE-Setup-v0.1.0-x64.exe
└── build-info.json
```

## ⚙️ 脚本参数

### PowerShell 脚本参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `-Help` | Switch | - | 显示帮助信息 |
| `-Clean` | Switch | - | 清理构建文件 |
| `-SkipBuild` | Switch | - | 跳过编译步骤 |
| `-SkipInstaller` | Switch | - | 跳过安装包生成 |
| `-Verbose` | Switch | - | 显示详细输出 |
| `-OutputDir` | String | release-builds | 输出目录 |
| `-DockerImage` | String | luqizheng/mdde-cmd-building-env:latest | Docker 镜像 |
| `-Version` | String | 0.1.0 | 版本号 |

### Bash 脚本参数

| 参数 | 说明 |
|------|------|
| `-h, --help` | 显示帮助信息 |
| `-c, --clean` | 清理构建文件 |
| `-s, --skip-build` | 跳过编译步骤 |
| `-i, --skip-installer` | 跳过安装包生成 |
| `-v, --verbose` | 显示详细输出 |
| `-o, --output DIR` | 指定输出目录 |
| `-d, --docker IMAGE` | 指定 Docker 镜像 |
| `--version VERSION` | 指定版本号 |

## 🔧 自定义构建

### 修改 Docker 镜像

如果需要使用自定义的构建镜像：

```bash
# PowerShell
.\build-installer.ps1 -DockerImage "your-registry/custom-image:tag"

# Bash  
./build-installer.sh --docker "your-registry/custom-image:tag"
```

### 修改输出目录

```bash
# PowerShell
.\build-installer.ps1 -OutputDir "custom-output"

# Bash
./build-installer.sh --output "custom-output"
```

### 修改版本号

```bash
# PowerShell  
.\build-installer.ps1 -Version "1.0.0"

# Bash
./build-installer.sh --version "1.0.0"
```

## 🐛 故障排除

### 常见问题

**Q: Docker 镜像拉取失败**
```
A: 检查网络连接和 Docker 服务状态
   docker version
   docker pull luqizheng/mdde-cmd-building-env:latest
```

**Q: 编译失败，提示找不到目标平台**
```
A: Docker 镜像可能不包含所需的交叉编译工具链
   确保使用正确的构建镜像
```

**Q: Windows 安装包生成失败**
```
A: 检查 Inno Setup 是否正确安装
   确保 ISCC.exe 在系统 PATH 中
   或者使用 -SkipInstaller 参数跳过安装包生成
```

**Q: 权限不足错误**
```
A: 在 Windows 上以管理员身份运行 PowerShell
   在 Linux/macOS 上确保有 Docker 权限
```

### 调试技巧

1. **使用详细模式查看具体错误**
   ```bash
   # PowerShell
   .\build-installer.ps1 -Verbose
   
   # Bash
   ./build-installer.sh --verbose
   ```

2. **分步执行**
   ```bash
   # 先只拉取镜像和编译
   .\build-installer.ps1 -SkipInstaller
   
   # 然后单独生成安装包
   .\build-installer.ps1 -SkipBuild
   ```

3. **检查构建信息**
   ```bash
   # 查看构建结果详情
   cat release-builds/build-info.json
   ```

## 📝 构建日志

脚本会生成详细的构建信息文件 `build-info.json`，包含：
- 构建版本和时间
- 使用的 Docker 镜像
- 生成的文件列表和校验和
- 文件大小统计

## 🤝 贡献

如果发现脚本问题或需要改进，请：
1. 提交 Issue 描述问题
2. 或者直接提交 Pull Request
3. 提供详细的错误信息和环境信息

## 📄 许可证

本脚本使用 MIT 许可证，与主项目保持一致。

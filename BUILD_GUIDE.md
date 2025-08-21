# MDDE 构建和打包指南

本文档介绍如何使用提供的脚本构建和打包 MDDE 项目。

## 📁 脚本文件概览

### 统一入口脚本
- **`make-package.sh`** - Linux/macOS 统一入口
- **`make-package.bat`** - Windows 统一入口

### 平台特定脚本
- **`build.sh`** - Linux/macOS 构建脚本
- **`build.ps1`** - Windows PowerShell 构建脚本  
- **`package.sh`** - 高级多平台打包脚本

## 🚀 快速开始

### 一键构建（推荐）

**Linux/macOS:**
```bash
./make-package.sh
```

**Windows:**
```cmd
make-package.bat
```

### 手动选择脚本

**Linux/macOS 基础构建:**
```bash
chmod +x build.sh
./build.sh
```

**Linux/macOS 高级打包:**
```bash
chmod +x package.sh
./package.sh
```

**Windows PowerShell:**
```powershell
.\build.ps1
```

## ⚙️ 详细使用说明

### build.sh (Linux/macOS)

基础构建脚本，支持以下功能：

```bash
# 完整构建流程
./build.sh

# 清理构建目录
./build.sh --clean

# 安装编译目标
./build.sh --install-targets

# 显示帮助信息
./build.sh --help
```

**功能特性:**
- 自动检测和安装 Rust 构建目标
- 支持 Linux x64 构建
- 支持 Windows 交叉编译（需要工具链）
- 支持 macOS 构建（仅在 macOS 上）
- 自动创建压缩包和安装脚本

### build.ps1 (Windows)

Windows PowerShell 构建脚本：

```powershell
# 完整构建流程
.\build.ps1

# 清理构建目录
.\build.ps1 -Clean

# 安装编译目标
.\build.ps1 -InstallTargets

# 显示帮助信息
.\build.ps1 -Help
```

**功能特性:**
- Windows 原生构建
- 支持 Linux 交叉编译（需要工具链）
- 自动创建 ZIP 压缩包
- 生成 Windows 安装脚本

### package.sh (高级打包)

功能最全面的打包脚本：

```bash
# 完整构建和打包
./package.sh

# 仅清理
./package.sh --clean

# 仅构建，不打包
./package.sh --build-only

# 仅打包已构建文件
./package.sh --package-only

# 安装构建目标
./package.sh --targets
```

**高级功能:**
- 自动环境检测
- Docker 交叉编译支持
- 智能平台检测
- 生成校验和文件
- 详细的构建报告

## 📦 输出文件结构

构建完成后，会生成以下目录结构：

```
项目根目录/
├── release-builds/          # 构建产物
│   ├── linux-x64/
│   │   └── mdde
│   ├── windows-x64/
│   │   └── mdde.exe
│   ├── macos-x64/
│   │   └── mdde
│   └── macos-arm64/
│       └── mdde
├── packages/                # 打包产物
│   ├── mdde-linux-x64-v0.1.0.tar.gz
│   ├── mdde-windows-x64-v0.1.0.zip
│   ├── mdde-macos-x64-v0.1.0.tar.gz
│   ├── mdde-macos-arm64-v0.1.0.tar.gz
│   └── SHA256SUMS           # 校验和文件
```

### 安装包内容

每个安装包包含：
- 可执行文件 (`mdde` 或 `mdde.exe`)
- 安装脚本 (`install.sh` 或 `install.bat`)
- 文档文件 (`README.md`, `README_EN.md`, `LICENSE`)
- 变更日志 (`CHANGELOG.md` - 如果存在)

## 🔧 环境要求

### 基本要求
- **Rust 1.70+** - 必需
- **Git** - 推荐
- **tar** - Linux/macOS 打包
- **zip** - Windows 打包

### 交叉编译要求

**Linux 交叉编译到 Windows:**
```bash
# 安装交叉编译工具
sudo apt install gcc-mingw-w64
# 或者使用 cross 工具
cargo install cross
```

**使用 Docker 交叉编译:**
```bash
# 安装 cross 工具
cargo install cross
# 使用 package.sh 脚本将自动检测并使用
```

### macOS 构建要求
- 必须在 macOS 系统上构建 macOS 版本
- 支持 Intel 和 Apple Silicon 双架构

## 🐛 故障排除

### 常见问题

**1. 权限错误**
```bash
# 给脚本执行权限
chmod +x build.sh package.sh make-package.sh
```

**2. Rust 目标未安装**
```bash
# 手动安装目标
rustup target add x86_64-unknown-linux-gnu
rustup target add x86_64-pc-windows-msvc
```

**3. 交叉编译失败**
- 检查是否安装了必要的工具链
- 尝试使用 Docker 交叉编译
- 在目标平台上进行原生编译

**4. PowerShell 执行策略错误**
```powershell
# 临时允许脚本执行
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### 调试模式

大多数脚本支持详细输出，查看构建过程：

```bash
# 启用详细输出
RUST_LOG=debug ./package.sh

# 查看 Cargo 详细输出
./build.sh --verbose
```

## 🔍 验证构建结果

### 检查二进制文件
```bash
# 查看文件信息
file release-builds/linux-x64/mdde
ldd release-builds/linux-x64/mdde  # Linux 依赖检查

# 运行版本检查
./release-builds/linux-x64/mdde --version
```

### 验证安装包
```bash
# 验证校验和
cd packages
sha256sum -c SHA256SUMS

# 测试安装包
tar -tzf mdde-linux-x64-v0.1.0.tar.gz
```

## 📊 性能优化

### 构建优化
- 使用 `cargo build --release` 进行优化构建
- 启用 LTO (Link Time Optimization)
- 设置 `RUSTFLAGS="-C target-cpu=native"` 进行本地优化

### 并行构建
```bash
# 设置并行构建作业数
export CARGO_BUILD_JOBS=4
```

## 🤝 贡献指南

如果您想改进构建脚本：

1. **测试变更** - 在所有支持的平台上测试
2. **保持兼容性** - 确保向后兼容
3. **更新文档** - 更新本指南
4. **添加注释** - 在脚本中添加清晰的注释

## 📞 支持

如果遇到构建问题：

1. 检查环境要求
2. 查看故障排除部分
3. 提交 Issue 到项目仓库
4. 包含完整的错误日志和环境信息

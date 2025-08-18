# MDDE Windows 安装包制作指南

## 🎯 概述

本指南介绍如何为 MDDE CLI 工具制作 Windows 安装包。安装包将自动处理环境变量配置，使用户可以在任何位置直接使用 `mdde` 命令。

## ⚡ 快速开始

### 1. 准备环境
```powershell
# 检查 Rust 安装
cargo --version

# 检查 Inno Setup 安装
# 下载地址: https://jrsoftware.org/isinfo.php
```

### 2. 一键生成安装包
```powershell
# 在 mdde-cmd 目录下运行
.\create-installer.ps1
```

### 3. 测试安装包
- 找到 `installer\output\` 目录下的 `.exe` 文件
- 右键选择"以管理员身份运行"
- 按照向导完成安装
- 打开新的命令提示符，测试 `mdde --version`

## 📋 详细步骤

### 步骤 1: 检查环境依赖

**必需软件:**
- Rust 1.70+ (`cargo --version`)
- Inno Setup 6.x (`iscc` 命令可用)

**安装 Inno Setup:**
1. 访问 https://jrsoftware.org/isinfo.php
2. 下载并安装最新版本
3. 确保安装路径添加到系统 PATH

### 步骤 2: 准备项目文件

确保项目目录结构正确:
```
mdde-cmd/
├── src/                    # Rust 源代码
├── Cargo.toml             # 项目配置
├── create-installer.ps1   # 一键打包脚本
├── build-installer.ps1    # 详细构建脚本
└── installer/
    ├── mdde-setup.iss     # Inno Setup 脚本
    ├── installer-info.txt # 安装前说明
    ├── installer-post.txt # 安装后说明
    └── README.md          # 详细文档
```

### 步骤 3: 执行构建

**简单方式:**
```powershell
.\create-installer.ps1
```

**详细控制:**
```powershell
# 查看帮助
.\build-installer.ps1 -Help

# 清理之前的构建
.\build-installer.ps1 -Clean

# 完整构建
.\build-installer.ps1

# 仅生成安装包（跳过 Rust 编译）
.\build-installer.ps1 -SkipBuild
```

### 步骤 4: 验证安装包

生成的安装包位于 `installer\output\MDDE-Setup-v0.1.0-x64.exe`

**测试流程:**
1. 在测试机器上运行安装包
2. 选择安装路径（默认: `C:\Program Files\MDDE\`）
3. 确保选中"添加到系统 PATH 环境变量"
4. 完成安装
5. 打开新的命令提示符
6. 测试命令: `mdde --version`, `mdde doctor`

## 🔧 安装包功能说明

### 自动安装功能
- ✅ 复制 `mdde.exe` 到 Program Files
- ✅ 自动添加安装目录到系统 PATH 环境变量
- ✅ 创建开始菜单快捷方式
- ✅ 可选创建桌面快捷方式
- ✅ 安装完成后运行 `mdde doctor` 检查环境

### 环境变量处理
安装程序会：
1. 检查 PATH 中是否已存在安装路径
2. 如果不存在，自动添加到系统 PATH
3. 刷新环境变量，使更改立即生效

### 卸载功能
- ✅ 完全移除程序文件
- ✅ 自动从 PATH 环境变量中移除安装路径
- ✅ 清理注册表项和快捷方式
- ✅ 运行 `mdde clean --all` 清理 Docker 资源

## 🎨 自定义安装包

### 修改应用信息
编辑 `installer/mdde-setup.iss`:
```ini
[Setup]
AppName=Your App Name
AppVersion=1.0.0
AppPublisher=Your Company
AppPublisherURL=https://your-website.com
```

### 添加图标
将图标文件放置为 `installer/mdde-icon.ico`，或修改脚本中的路径。

### 自定义安装页面
修改 `installer/installer-info.txt` 和 `installer/installer-post.txt` 文件内容。

## 🚨 注意事项

### 权限要求
- 安装程序需要管理员权限来修改系统 PATH
- 用户应该右键选择"以管理员身份运行"

### 兼容性
- 支持 Windows 10 及更高版本
- 仅支持 64 位系统
- 需要 Docker Desktop（运行时）

### 安全考虑
- 安装包会修改系统环境变量
- 建议对安装包进行数字签名
- 用户应该从可信来源下载安装包

## 🐛 故障排除

### 构建失败
```powershell
# 检查 Rust 安装
cargo --version

# 检查 Inno Setup
where iscc

# 清理并重新构建
.\build-installer.ps1 -Clean
.\build-installer.ps1
```

### 安装失败
- 确保以管理员身份运行
- 检查磁盘空间是否足够
- 确保没有被杀毒软件阻止

### PATH 环境变量未生效
- 关闭并重新打开命令提示符
- 重启计算机
- 手动检查系统环境变量设置

## 📊 构建输出

成功构建后将产生:
- `installer/output/MDDE-Setup-v0.1.0-x64.exe` - 主安装包
- 构建日志和临时文件

安装包大小通常在 2-5 MB 之间，具体取决于 Rust 二进制文件大小。

## 🚀 分发安装包

### 发布清单
- [ ] 在多个 Windows 版本上测试
- [ ] 验证环境变量自动配置
- [ ] 测试卸载流程
- [ ] 检查 Docker 依赖提示
- [ ] 准备用户安装指南

### 发布渠道
- GitHub Releases
- 公司内部分发系统
- 软件下载站点

---

**提示**: 首次制作安装包时，建议在虚拟机中进行完整测试，确保安装和卸载流程都能正常工作。


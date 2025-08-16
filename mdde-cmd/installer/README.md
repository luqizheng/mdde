# MDDE Windows 安装包

这个目录包含创建 MDDE Windows 安装包所需的所有文件。

## 📁 文件说明

- `mdde-setup.iss` - Inno Setup 安装脚本主文件
- `installer-info.txt` - 安装前显示的信息
- `installer-post.txt` - 安装完成后显示的信息
- `output/` - 生成的安装包输出目录（自动创建）

## 🛠️ 构建需求

### 必需软件
1. **Rust 工具链** - 用于编译 MDDE CLI 工具
   - 下载地址: https://rustup.rs/
   - 验证安装: `cargo --version`

2. **Inno Setup** - 用于生成 Windows 安装程序
   - 下载地址: https://jrsoftware.org/isinfo.php
   - 推荐版本: Inno Setup 6.x
   - 安装后确保 `ISCC.exe` 可以在 PATH 中找到

### 可选软件
- **Docker Desktop** - 运行时需要（用户安装时需要）

## 🚀 构建安装包

### 方法一：一键构建（推荐）
```powershell
# 在 mdde-cmd 目录下运行
.\create-installer.ps1
```

### 方法二：详细构建
```powershell
# 在 mdde-cmd 目录下运行
.\build-installer.ps1

# 其他选项
.\build-installer.ps1 -Help        # 显示帮助
.\build-installer.ps1 -Clean       # 清理构建文件
.\build-installer.ps1 -SkipBuild   # 跳过 Rust 编译
```

## 📋 构建流程

1. **检查依赖** - 验证 Rust 和 Inno Setup 是否已安装
2. **编译 Rust 项目** - 使用 `cargo build --release` 编译
3. **准备安装文件** - 复制必要的文件到安装器目录
4. **编译安装程序** - 使用 Inno Setup 生成 `.exe` 安装包
5. **验证输出** - 检查生成的安装包是否正确

## 📦 安装包功能

### 安装过程
- ✅ 安装 MDDE CLI 工具到 `Program Files\MDDE\`
- ✅ 自动添加到系统 PATH 环境变量
- ✅ 创建开始菜单快捷方式
- ✅ 可选创建桌面图标
- ✅ 运行系统检查 (`mdde doctor`)

### 卸载过程
- ✅ 完全移除程序文件
- ✅ 自动从 PATH 环境变量中移除
- ✅ 清理注册表项
- ✅ 移除快捷方式

## 🎯 安装包特性

### 用户界面
- 现代化的安装向导界面
- 中文和英文双语支持
- 详细的安装前后说明
- 可自定义安装路径

### 系统集成
- 自动环境变量配置
- 系统路径检查和清理
- 兼容 Windows 10+ 系统
- 支持 64 位系统

### 安全特性
- 数字签名支持（需要代码签名证书）
- 管理员权限检查
- 安全的路径操作
- 完整的错误处理

## 🔧 自定义安装包

### 修改应用信息
编辑 `mdde-setup.iss` 文件中的 `[Setup]` 部分：
```ini
AppName=MDDE (Multi Docker Development Environment)
AppVersion=0.1.0
AppPublisher=Your Company
AppPublisherURL=https://your-website.com
```

### 添加额外文件
在 `[Files]` 部分添加新文件：
```ini
Source: "path\to\your\file"; DestDir: "{app}"; Flags: ignoreversion
```

### 自定义安装选项
在 `[Tasks]` 部分添加新任务：
```ini
Name: "your_task"; Description: "Your Description"; GroupDescription: "Options:"
```

### 修改图标
替换 `mdde-icon.ico` 文件，或在安装脚本中指定新的图标路径。

## 🐛 故障排除

### 常见问题

**Q: 编译失败，提示找不到 Rust**
```
A: 确保已安装 Rust 工具链，并且 cargo 命令可用
   下载地址: https://rustup.rs/
```

**Q: 找不到 Inno Setup 编译器**
```
A: 确保已安装 Inno Setup，并且 ISCC.exe 在系统 PATH 中
   或者安装到标准位置: Program Files (x86)\Inno Setup 6\
```

**Q: 安装包运行时提示权限不足**
```
A: 安装程序需要管理员权限来修改系统 PATH 环境变量
   右键点击安装包，选择"以管理员身份运行"
```

**Q: PATH 环境变量没有自动添加**
```
A: 检查是否选择了"添加到系统 PATH 环境变量"选项
   也可以手动添加安装目录到 PATH
```

### 调试技巧

1. **详细日志** - 在安装时添加 `/LOG` 参数查看详细日志
2. **测试安装** - 使用虚拟机测试完整的安装和卸载流程
3. **权限检查** - 确保以管理员身份运行安装程序
4. **路径验证** - 安装后打开新的命令提示符测试 `mdde` 命令

## 📄 许可证

本安装包使用 MIT 许可证，详见项目根目录的 LICENSE 文件。

## 🤝 贡献

欢迎提交问题报告和改进建议到项目的 GitHub 仓库。

---

**注意**: 生成安装包前请确保项目已经经过充分测试，并且所有依赖项都已正确配置。


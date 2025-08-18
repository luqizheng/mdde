# MDDE 命令行工具

[![Build and Release](https://github.com/luqizheng/mdde/actions/workflows/build.yml/badge.svg)](https://github.com/luqizheng/mdde/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个基于 Rust 编写的跨平台命令行工具，用于管理 Docker 多语言开发环境。

## 🚀 功能特性

- **Docker 集成**: 完整的 Docker 命令行包装器
- **HTTP 客户端**: 支持文件上传、下载、列表等操作
- **配置管理**: TOML 配置文件和环境变量支持
- **错误处理**: 完善的错误类型和转换系统
- **工具函数**: 文件系统、验证、格式化等实用功能

## 🛠️ 安装和运行

### 方式一：下载预编译二进制文件（推荐）

1. **前往 [Releases 页面](https://github.com/luqizheng/mdde/releases/latest) 下载对应平台的二进制文件**

   - **Linux (x64)**: `mdde-linux-x64` 或 `mdde-linux-x64.tar.gz`
   - **Windows (x64)**: `mdde-windows-x64.exe` 或 `mdde-windows-x64.zip`
   - **macOS (Intel)**: `mdde-macos-x64` 或 `mdde-macos-x64.tar.gz`
   - **macOS (Apple Silicon)**: `mdde-macos-arm64` 或 `mdde-macos-arm64.tar.gz`

2. **安装二进制文件**

   **Linux/macOS:**
   ```bash
   # 下载后重命名并移动到 PATH 目录
   mv mdde-linux-x64 /usr/local/bin/mdde
   chmod +x /usr/local/bin/mdde
   
   # 或者对于 macOS
   mv mdde-macos-x64 /usr/local/bin/mdde
   chmod +x /usr/local/bin/mdde
   ```

   **Windows:**
   ```powershell
   # 将 mdde-windows-x64.exe 重命名为 mdde.exe
   # 并将其移动到 PATH 环境变量中的目录
   ```

3. **验证安装**
   ```bash
   mdde --help
   mdde version
   ```

### 方式二：从源码构建

#### 前置要求
- Rust 1.70+
- Docker (已安装并添加到 PATH)

#### 构建步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/luqizheng/mdde.git
   cd mdde-cmd
   ```

2. **构建项目**
   ```bash
   cargo build --release
   ```

3. **安装到系统**
   ```bash
   cargo install --path .
   ```

4. **运行示例**
   ```bash
   # Docker 命令示例
   cargo run --example docker_usage
   
   # 基本使用示例
   cargo run --example basic_usage
   ```

## ⚙️ 配置管理

### 配置管理
- **`.mdde.env` 文件** (当前工作目录)
- **默认配置** (如果环境变量文件不存在)

### 配置文件位置

#### Windows
- 环境变量文件: `当前工作目录\.mdde.env`

#### Linux/macOS
- 环境变量文件: `当前工作目录\.mdde.env`

### 环境变量文件 (.mdde.env)
```bash
# 复制示例文件
cp .mdde.env.example .mdde.env

# 编辑配置
host=http://your-server:3000
container_name=my-project
debug_port=5000
workspace=./my-workspace
```

**重要**: `.mdde.env` 文件是唯一的配置文件，适合项目特定的配置。

### 环境变量文件格式 (.mdde.env)
```bash
host=http://192.168.2.5:3000
container_name=my-container
debug_port=5000
workspace=./my-workspace
```

## 🔌 使用方法

### 基本命令
```bash
# 初始化配置
mdde init http://localhost:3000

# 创建开发环境
mdde create dotnet9 --name my-project

# 启动环境
mdde start my-project

# 查看状态
mdde status

# 查看日志
mdde logs my-project

# 停止环境
mdde stop my-project
```

### Docker 操作
```bash
# 检查 Docker 状态
mdde docker check

# 列出容器
mdde docker ps

# 执行命令
mdde docker exec my-container "ls -la"
```

## 🧪 测试

```bash
# 运行所有测试
cargo test

# 运行特定测试
cargo test config

# 运行集成测试
cargo test --test integration_tests
```

## 📁 项目结构

```
mdde-cmd/
├── src/
│   ├── main.rs          # 主程序入口
│   ├── lib.rs           # 库入口
│   ├── error.rs         # 错误定义
│   ├── config.rs        # 配置管理 (.mdde.env)
│   ├── http.rs          # HTTP 客户端
│   ├── docker.rs        # Docker 命令包装器
│   ├── cli.rs           # CLI 定义
│   ├── commands/        # 命令实现
│   └── utils.rs         # 工具函数
├── examples/             # 示例程序
├── tests/               # 集成测试
├── .mdde.env.example    # 环境变量文件示例
├── Cargo.toml           # 项目配置
└── README.md            # 项目文档
```

## 🔒 安全特性

- **路径遍历防护**: 防止访问系统目录外的文件
- **文件类型验证**: 确保操作的是正确的文件类型
- **错误处理**: 完善的错误处理和状态码返回

## 🚨 注意事项

1. **Docker 依赖**: 需要系统已安装 Docker 并添加到 PATH
2. **权限要求**: 某些 Docker 操作可能需要管理员权限
3. **网络配置**: HTTP 客户端需要网络连接
4. **配置优先级**: `.mdde.env` 文件会覆盖其他配置

## 🚀 CI/CD 流程

本项目使用 GitHub Actions 进行自动化构建和发布：

### 自动构建

- **触发条件**: 推送到 `main`、`develop` 分支或创建 Pull Request
- **构建平台**: Linux x64、Windows x64、macOS Intel、macOS Apple Silicon
- **构建产物**: 自动上传到 GitHub Actions Artifacts

### 自动发布

- **触发条件**: 推送 `v*` 格式的 Git 标签（如 `v1.0.0`）
- **发布内容**: 
  - 跨平台二进制文件
  - 压缩包格式（tar.gz 和 zip）
  - 自动生成发布说明

### 创建新版本

1. **更新版本号**
   ```bash
   # 更新 mdde-cmd/Cargo.toml 中的版本号
   sed -i 's/version = "0.1.0"/version = "0.2.0"/' mdde-cmd/Cargo.toml
   ```

2. **提交并创建标签**
   ```bash
   git add .
   git commit -m "chore: bump version to v0.2.0"
   git tag v0.2.0
   git push origin main --tags
   ```

3. **自动发布**
   - GitHub Actions 将自动构建所有平台
   - 创建新的 Release 页面
   - 上传二进制文件和压缩包

### 开发工作流

```bash
# 1. Fork 并克隆项目
git clone https://github.com/your-username/mdde.git
cd mdde

# 2. 创建功能分支
git checkout -b feature/your-feature

# 3. 进行开发和测试
cd mdde-cmd
cargo test
cargo clippy -- -D warnings
cargo fmt -- --check

# 4. 提交更改
git commit -m "feat: add your feature"
git push origin feature/your-feature

# 5. 创建 Pull Request
```

### 本地构建

如果需要本地构建当前平台的版本：

```bash
# 进入项目目录
cd mdde-cmd

# 构建发布版本
cargo build --release

# 安装到系统
cargo install --path .
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. **报告问题**: 使用 [Issue 模板](https://github.com/luqizheng/mdde/issues/new) 报告 bug 或请求新功能
2. **代码贡献**: 
   - Fork 项目并创建功能分支
   - 确保代码通过所有测试和检查
   - 提交 Pull Request 等待审核
3. **文档改进**: 欢迎改进文档和示例代码

## 📄 许可证

MIT License


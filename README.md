# MDDE 命令行工具

[![Build and Release](https://github.com/luqizheng/mdde/actions/workflows/build.yml/badge.svg)](https://github.com/luqizheng/mdde/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**语言**: [English](README_EN.md) | [中文](README.md)

一个基于 Rust 编写的跨平台命令行工具，用于管理 Docker 多语言开发环境。

## 🚀 功能特性

- **Docker 集成**: 完整的 Docker 和 Docker Compose 管理
- **模板系统**: 从远程服务器下载开发环境模板
- **多格式输出**: 支持 Table、JSON、YAML 格式输出
- **国际化支持**: 内置多语言支持系统
- **系统诊断**: 内置环境检查和诊断功能
- **配置管理**: 灵活的环境变量配置系统

## 🏗️ 系统架构

### 架构概述

MDDE 是一个基于模板的 Docker 多语言开发环境管理工具，通过 HTTP 客户端从远程服务器下载 docker-compose 模板，实现快速环境搭建。

### 工作原理

1. **初始化配置**: 使用 `mdde init` 设置远程模板服务器地址
2. **创建环境**: 使用 `mdde create` 下载指定的 docker-compose 模板
3. **环境管理**: 通过 Docker Compose 管理容器生命周期
4. **配置存储**: 所有配置存储在 `.mdde/cfg.env` 文件中

### 文件结构

```
项目目录/
├── .mdde/
│   ├── cfg.env              # 环境变量配置
│   └── docker-compose.yml   # Docker Compose 配置
├── .gitignore              # 自动更新忽略 .mdde/ 目录
└── 其他项目文件...
```

### 模板服务器

默认模板服务器：`https://raw.githubusercontent.com/luqizheng/mdde-dockerifle/refs/heads/main`

支持的开发环境类型：
- **dotnet**: .NET 开发环境（sdk6.0, sdk8.0, sdk9.0等）
- **java**: Java 开发环境（openjdk11, openjdk17, openjdk21等）
- **nodejs**: Node.js 开发环境（node18, node20, node22等）
- **python**: Python 开发环境（python311, yolo-11等）

## 🛠️ 安装和运行

### 方式一：下载预编译二进制文件（推荐）

1. **前往 [Releases 页面](https://github.com/luqizheng/mdde/releases/latest) 下载对应平台的二进制文件**

   - **Linux (x64)**: `mdde-linux-x64` 或 `mdde-linux-x64.tar.gz`
   - **Linux (CentOS 7 兼容)**: `mdde-linux-x64-centos7` 或 `mdde-linux-x64-centos7.tar.gz`
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
- Docker Compose (已安装并添加到 PATH)

#### 构建步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/luqizheng/mdde.git
   cd mdde/mdde-cmd
   ```

2. **构建项目**
   ```bash
   cargo build --release
   ```

3. **安装到系统**
   ```bash
   cargo install --path .
   ```

## ⚙️ 配置管理

### 配置文件

MDDE 使用 `.mdde/cfg.env` 文件存储配置信息：

```bash
host=https://raw.githubusercontent.com/luqizheng/mdde-dockerifle/refs/heads/main
container_name=my-project
app_port=8080
workspace=/path/to/workspace
```

### 配置项说明

- **host**: 模板服务器地址
- **container_name**: 容器名称
- **app_port**: 应用端口号
- **workspace**: 工作目录路径

### 自动配置

- 创建 `.mdde/cfg.env` 文件时，MDDE 会自动更新 `.gitignore` 文件
- 忽略整个 `.mdde/` 目录，避免配置文件被提交到版本控制

## 🔌 使用方法

### 基本工作流程

```bash
# 1. 初始化配置
mdde init

# 2. 创建开发环境
mdde create dotnet/sdk8.0 --name my-dotnet-app --app_port 8080:80

# 3. 启动环境
mdde start

# 4. 查看状态
mdde status

# 5. 进入容器
mdde exec

# 6. 停止环境
mdde stop
```

### 命令详解

#### 初始化
```bash
cd 源码
# 交互式初始化
mdde init

# 指定服务器地址
mdde init --host https://your-server.com
```

#### 创建环境
```bash
# 交互式创建
mdde create

# 指定参数创建，源码和执行mdde的目录不同。 用 --workspace 指定源码位置。
mdde create java/openjdk17 --name my-java-app --app_port 8080:8080 --workspace ./src
# 或者
mdde create java/openjdk17
```

#### 环境管理
```bash
# 启动环境（前台）
mdde start

# 启动环境（后台）
mdde start --detach

# 停止环境
mdde stop

# 停止并删除容器
mdde stop --remove

# 重启环境
mdde restart
```

#### 容器操作
```bash
# 进入容器（默认 bash）
mdde exec

# 指定shell
mdde exec /bin/sh

# 在容器中执行命令
mdde run ls -la
mdde run npm install
```

#### 状态和日志
```bash
# 查看状态（表格格式）
mdde status

# JSON 格式输出
mdde status --format json

# YAML 格式输出
mdde status --format yaml

# 查看日志
mdde logs

# 查看最后50行日志
mdde logs 50

# 实时跟踪日志
mdde logs --follow
```

#### 清理操作
```bash
# 清理所有未使用资源
mdde clean --all

# 只清理镜像
mdde clean --images

# 只清理容器
mdde clean --containers

# 只清理数据卷
mdde clean --volumes
```

#### 系统诊断
```bash
# 检查系统环境
mdde doctor
```

#### 环境变量管理
```bash
# 查看所有环境变量
mdde env --ls

# 设置环境变量
mdde env --set "host=https://new-server.com"

# 删除环境变量
mdde env --del container_name
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
│   ├── main.rs              # 主程序入口
│   ├── lib.rs               # 库入口
│   ├── cli.rs               # CLI 定义和命令路由
│   ├── config.rs            # 配置管理（.mdde/cfg.env）
│   ├── error.rs             # 错误类型定义
│   ├── http.rs              # HTTP 客户端实现
│   ├── docker.rs            # Docker 命令包装器
│   ├── i18n.rs              # 国际化支持
│   ├── utils.rs             # 工具函数
│   └── commands/            # 命令实现
│       ├── mod.rs
│       ├── init.rs          # 初始化命令
│       ├── create.rs        # 创建环境命令
│       ├── start.rs         # 启动命令
│       ├── stop.rs          # 停止命令
│       ├── status.rs        # 状态查看命令
│       ├── logs.rs          # 日志查看命令
│       ├── exec.rs          # 进入容器命令
│       ├── run.rs           # 执行命令
│       ├── clean.rs         # 清理命令
│       ├── doctor.rs        # 系统诊断命令
│       ├── env.rs           # 环境变量管理命令
│       ├── version.rs       # 版本信息命令
│       └── restart.rs       # 重启命令
├── examples/                # 示例程序
├── tests/                   # 集成测试
├── Cargo.toml               # 项目配置
└── README.md                # 项目文档
```

## 🔒 技术栈

- **语言**: Rust 2021 Edition
- **CLI框架**: clap 4.4 (derive feature)
- **异步运行时**: tokio 1.35 (full features)
- **HTTP客户端**: reqwest 0.11 (json, multipart features)
- **序列化**: serde, serde_json, serde_yaml, toml
- **错误处理**: thiserror, anyhow
- **日志**: tracing, tracing-subscriber
- **其他**: colored, indicatif, dirs, walkdir

## 🚨 注意事项

### 系统要求
1. **Docker**: 必须安装 Docker 并确保在 PATH 中可用
2. **Docker Compose**: 必须安装 Docker Compose
3. **网络连接**: 需要能够访问模板服务器

### 系统兼容性说明

**Linux 发行版支持:**
- **现代发行版**: 使用 `mdde-linux-x64` (Ubuntu 18.04+, CentOS 8+, Rocky Linux 8+, 等)
- **CentOS 7 / RHEL 7**: 专门使用 `mdde-linux-x64-centos7` 兼容版本
- **其他老旧系统**: 建议使用 CentOS 7 兼容版本或从源码编译

**OpenSSL 版本兼容性:**
- `mdde-linux-x64`: 需要 OpenSSL 3.0+ (现代系统)
- `mdde-linux-x64-centos7`: 兼容 OpenSSL 1.0.x (CentOS 7 系统)

如遇到 `libssl.so.3: cannot open shared object file` 错误，请下载 CentOS 7 兼容版本。

### 使用注意
1. **配置文件**: `.mdde/cfg.env` 包含敏感配置，已自动加入 `.gitignore`
2. **权限要求**: 某些 Docker 操作可能需要管理员权限
3. **端口冲突**: 创建环境时注意避免端口冲突

### 故障排除
```bash
# 使用诊断命令检查环境
mdde doctor

# 检查 Docker 状态
docker --version
docker-compose --version
docker info
```

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

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. **报告问题**: 使用 [Issue 模板](https://github.com/luqizheng/mdde/issues/new) 报告 bug 或请求新功能
2. **代码贡献**: 
   - Fork 项目并创建功能分支
   - 确保代码通过所有测试和检查
   - 提交 Pull Request 等待审核
3. **文档改进**: 欢迎改进文档和示例代码

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

## 📄 许可证

MIT License
# MDDE 命令行工具

一个基于 Rust 编写的跨平台命令行工具，用于管理 Docker 多语言开发环境。

## 🚀 功能特性

- **Docker 集成**: 完整的 Docker 命令行包装器
- **HTTP 客户端**: 支持文件上传、下载、列表等操作
- **配置管理**: TOML 配置文件和环境变量支持
- **错误处理**: 完善的错误类型和转换系统
- **工具函数**: 文件系统、验证、格式化等实用功能

## 🛠️ 安装和运行

### 前置要求
- Rust 1.70+
- Docker (已安装并添加到 PATH)

### 快速开始

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd mdde-cmd
   ```

2. **构建项目**
   ```bash
   cargo build --release
   ```

3. **运行示例**
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
mdde_host=http://your-server:3000
container_name=my-project
debug_port=5000
workspace=./my-workspace
```

**重要**: `.mdde.env` 文件是唯一的配置文件，适合项目特定的配置。

### 环境变量文件格式 (.mdde.env)
```bash
mdde_host=http://192.168.2.5:3000
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

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License


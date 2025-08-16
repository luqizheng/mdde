# MDDE - 多语言 Docker 开发环境

一个全面的基于 Docker 的开发环境管理系统，提供命令行工具和 Web 服务，用于创建、管理和编排隔离的开发环境。

## 🌟 功能特性

### 核心能力
- **多语言支持**: .NET Core、Java、Node.js、Python 开发环境
- **命令行界面**: 基于 Rust 的 CLI 工具进行环境管理
- **Web 管理**: Node.js Web 服务器用于脚本分发和管理
- **跨平台**: 支持 Windows、Linux 和 macOS
- **Docker 集成**: 完整的 Docker 生态系统集成

### 核心组件
- **mdde-cmd**: 用于环境生命周期管理的 Rust CLI 工具
- **mdde-web**: 用于脚本共享和管理的 Node.js Web 服务器
- **dev-docker**: 多语言预配置 Docker 环境

## 🚀 快速开始

### 前置要求
- 已安装并运行 Docker Desktop
- Rust 1.70+ (用于 mdde-cmd)
- Node.js 22+ (用于 mdde-web)
- PowerShell 5.1+ (Windows) 或 Bash (Linux/macOS)

### 1. 克隆仓库
```bash
git clone <repository-url>
cd docker-dev
```

### 2. 启动 MDDE Web 服务器
```bash
cd mdde-web
npm install
npm start
```

### 3. 构建并使用 CLI 工具
```bash
cd mdde-cmd
cargo build --release

# 初始化配置
./target/release/mdde init http://localhost:3000

# 创建开发环境
./target/release/mdde create dotnet9 --name my-project

# 启动环境
./target/release/mdde start my-project
```

### 4. 使用预配置环境
```bash
# 进入特定语言环境
cd dev-docker/dotnet

# 创建开发环境
.\create-dev-env.ps1

# 在环境中运行命令
.\run-cmd.ps1 dotnet restore
.\run-cmd.ps1 dotnet build
```

## 🏗️ 项目结构

```
docker-dev/
├── mdde-cmd/                    # Rust CLI 工具
│   ├── src/                     # 源代码
│   ├── examples/                # 使用示例
│   ├── tests/                   # 测试套件
│   ├── Cargo.toml              # Rust 项目配置
│   └── README.md               # CLI 文档
├── mdde-web/                    # Node.js Web 服务器
│   ├── server.js               # Express 服务器
│   ├── index.html              # Web 界面
│   ├── admin.html              # 管理界面
│   ├── scripts/                # 脚本存储
│   ├── package.json            # Node.js 依赖
│   └── Dockerfile              # Web 服务器 Docker 镜像
└── dev-docker/                 # 预配置环境
    ├── dotnet/                 # .NET 开发环境
    │   ├── net3.1_sdk/        # .NET 3.1 SDK
    │   └── net9_sdk/          # .NET 9 SDK
    ├── java/                   # Java 开发环境
    ├── nodejs/                 # Node.js 开发环境
    │   └── node22/            # Node.js 22
    └── python/                 # Python 开发环境
```

## 🛠️ 组件概览

### MDDE CLI 工具 (Rust)
用于管理 Docker 开发环境的强大命令行界面。

**主要特性:**
- 环境生命周期管理（创建、启动、停止、重启）
- 支持 TOML 的配置管理
- 与 Web 服务器通信的 HTTP 客户端
- 跨平台兼容性
- 全面的错误处理

**命令:**
```bash
mdde init <server-url>          # 初始化配置
mdde create <env-type>          # 创建新环境
mdde start <env-name>           # 启动环境
mdde stop <env-name>            # 停止环境
mdde restart <env-name>         # 重启环境
mdde status                     # 查看所有环境状态
mdde logs <env-name>            # 查看环境日志
mdde clean                      # 清理未使用的 Docker 资源
mdde doctor                     # 系统健康检查
mdde version                    # 显示版本信息
```

### MDDE Web 服务器 (Node.js)
基于 Web 的脚本管理和分发平台。

**主要特性:**
- 脚本上传和下载
- 基于目录的组织
- ZIP 归档创建
- RESTful API
- Web 管理界面
- CORS 支持

**API 端点:**
- `GET /download/{script}` - 下载基础脚本
- `GET /get/{dirName}` - 以 ZIP 格式下载脚本目录
- `POST /upload/{dirName}` - 上传脚本到目录
- `GET /list` - 列出所有脚本目录
- `GET /list/{dirName}` - 列出目录中的脚本
- `DELETE /delete/{dirName}/{fileName}` - 删除脚本

### 开发环境

#### .NET Core 环境
- **版本**: .NET 3.1, .NET 9
- **特性**: ASP.NET Core、Blazor、控制台应用程序
- **默认端口**: 5001

#### Java 环境
- **版本**: Java 17+
- **特性**: Spring Boot、Maven、Gradle 支持
- **默认端口**: 8081
- **调试端口**: 5005

#### Node.js 环境
- **版本**: Node.js 22
- **特性**: Express、TypeScript、pnpm 支持
- **默认端口**: 3000

#### Python 环境
- **版本**: Python 3.11+
- **特性**: Flask、FastAPI、Django 支持
- **默认端口**: 5000

## 📖 使用示例

### 创建 .NET 开发环境
```bash
# 使用 CLI 工具
mdde create dotnet9 --name myapp --port 5001 --workspace ./myapp

# 使用预配置环境
cd dev-docker/dotnet
.\create-dev-env.ps1
```

### 管理多个环境
```bash
# 列出所有运行的环境
mdde status

# 启动多个环境
mdde start frontend
mdde start backend
mdde start database

# 查看特定环境的日志
mdde logs backend --follow
```

### 基于 Web 的脚本管理
```bash
# 启动 Web 服务器
cd mdde-web
npm start

# 访问 Web 界面
# http://localhost:3000 - 主界面
# http://localhost:3000/admin.html - 管理界面

# API 使用示例
curl http://localhost:3000/list
curl http://localhost:3000/get/dotnet9
```

## 🔧 配置

### CLI 配置
CLI 工具使用 `.mdde.env` 文件进行配置:

```bash
# .mdde.env
mdde_host=http://localhost:3000
container_name=my-project
debug_port=5000
workspace=./workspace
```

### Web 服务器配置
通过环境变量配置 Web 服务器:

```bash
PORT=3000                       # 服务器端口
NODE_ENV=production            # 环境模式
```

### Docker 环境配置
每个环境使用 `docker-compose.yml` 和 `.env` 文件:

```bash
# .dev.env (由 create-dev-env.ps1 创建)
CONTAINER_NAME=my-project
APP_PORT=5001
workspace=C:\path\to\workspace
```

## 🧪 测试

### CLI 工具测试
```bash
cd mdde-cmd
cargo test                      # 运行所有测试
cargo test --test integration   # 集成测试
```

### Web 服务器测试
```bash
cd mdde-web
npm test                        # 运行测试套件
```

## 🐳 Docker 支持

### 构建自定义镜像
```bash
# 构建 .NET 环境
cd dev-docker/dotnet/net9_sdk
.\build-image.ps1

# 构建 Node.js 环境
cd dev-docker/nodejs/node22
.\build-image.ps1

# 构建 Web 服务器镜像
cd mdde-web
.\docker-build.ps1
```

### 使用 Docker Compose 运行
```bash
# 使用 docker-compose 启动环境
docker-compose --env-file .dev.env up -d

# 查看日志
docker-compose --env-file .dev.env logs -f

# 停止环境
docker-compose --env-file .dev.env down
```

## 🔒 安全特性

- **路径遍历保护**: 防止访问允许目录之外的文件
- **文件类型验证**: 确保只处理适当的文件
- **输入验证**: 全面的参数验证
- **错误处理**: 安全的错误响应，不泄露敏感信息
- **非 root 容器**: 所有环境都使用非特权用户运行

## 📊 性能特性

- **高性能**: Rust CLI 提供原生性能
- **内存安全**: 编译时内存安全检查
- **异步 I/O**: Node.js Web 服务器支持高并发
- **资源效率**: 优化的 Docker 镜像，开销最小
- **快速启动**: 静态链接和优化的容器启动

## 🤝 贡献

我们欢迎贡献！请按照以下步骤：

1. Fork 仓库
2. 创建功能分支: `git checkout -b feature/new-feature`
3. 进行更改并添加测试
4. 确保所有测试通过: `cargo test` 和 `npm test`
5. 提交更改: `git commit -am 'Add new feature'`
6. 推送到分支: `git push origin feature/new-feature`
7. 提交 pull request

### 开发环境设置
```bash
# 克隆和设置
git clone <repository-url>
cd docker-dev

# 设置 CLI 开发
cd mdde-cmd
cargo build
cargo test

# 设置 Web 开发
cd ../mdde-web
npm install
npm run dev
```

## 📝 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 🆘 支持

- **问题反馈**: 通过 GitHub Issues 报告错误和请求功能
- **文档**: 每个组件的 README 中都有详细文档
- **示例**: 查看 `examples/` 目录获取使用示例

## 🔮 路线图

- [ ] 自定义环境的插件系统
- [ ] Kubernetes 支持
- [ ] CI/CD 集成模板
- [ ] 性能监控仪表板
- [ ] 多用户身份验证
- [ ] 环境模板市场

---

**MDDE** - 为全球团队简化基于 Docker 的开发环境。
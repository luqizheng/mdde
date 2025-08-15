# Docker 多语言开发环境

这是一个基于Docker的多语言开发环境解决方案，支持.NET Core、Java、Node.js和Python开发。

## 快速开始

### 1. 环境要求

- Windows 10/11
- Docker Desktop
- PowerShell 5.1+

### 2. 选择开发语言

进入对应的语言目录，例如：

```powershell
cd dev-docker\dotnet
```

### 3. 创建开发环境

运行环境创建脚本：

```powershell
.\create-dev-env.ps1
```

按提示输入：
- 源码目录路径
- 容器名称（可选）
- 应用端口（可选）

### 4. 使用开发环境

使用通用命令执行脚本：

```powershell
# .NET Core
.\run-cmd.ps1 dotnet restore
.\run-cmd.ps1 dotnet build
.\run-cmd.ps1 dotnet run

# Java
.\run-cmd.ps1 mvn clean install
.\run-cmd.ps1 mvn spring-boot:run

# Node.js
.\run-cmd.ps1 npm install
.\run-cmd.ps1 npm run dev

# Python
.\run-cmd.ps1 pip install -r requirements.txt
.\run-cmd.ps1 python app.py
```

## 支持的语言

### .NET Core 9
- 位置：`./dev-docker/dotnet/`
- 端口：5001 (默认)
- 特性：支持ASP.NET Core、Blazor、Console应用

### Java 17
- 位置：`./dev-docker/java/`
- 端口：8081 (默认)
- 调试端口：5005
- 特性：支持Spring Boot、Maven、Gradle

### Node.js 18
- 位置：`./dev-docker/nodejs/`
- 端口：3000 (默认)
- 特性：支持Express、React、Vue、TypeScript

### Python 3.11
- 位置：`./dev-docker/python/`
- 端口：5000 (默认)
- 特性：支持Flask、FastAPI、Django

## 管理脚本

### 通用管理脚本

```powershell
# 启动所有开发环境
.\mdde-web\dev.ps1 start

# 启动特定语言环境
.\mdde-web\dev.ps1 start dotnet

# 停止所有环境
.\mdde-web\dev.ps1 stop

# 查看状态
.\mdde-web\dev.ps1 status

# 查看日志
.\mdde-web\dev.ps1 logs

# 清理环境
.\scripts\dev.ps1 clean
```

### 便捷脚本

每种语言都提供了便捷脚本：

```powershell
# .NET Core
.\build.ps1      # 构建项目
.\run.ps1        # 运行项目
.\restore.ps1    # 还原包

# 其他语言类似
```

## 目录结构

```
docker-dev/
├── docker-compose.yml          # 主配置文件
├── README.md                   # 说明文档
├── scripts/                    # 管理脚本
│   └── dev.ps1                # 通用环境管理
├── dotnet/                     # .NET Core环境
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── create-dev-env.ps1     # 环境创建
│   ├── run-cmd.ps1            # 命令执行
│   ├── build.ps1              # 构建脚本
│   ├── run.ps1                # 运行脚本
│   ├── restore.ps1            # 包还原脚本
│   └── workspace/             # 示例项目
├── java/                       # Java环境
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── create-dev-env.ps1
│   ├── run-cmd.ps1
│   └── workspace/
├── nodejs/                     # Node.js环境
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── create-dev-env.ps1
│   ├── run-cmd.ps1
│   └── workspace/
└── python/                     # Python环境
    ├── Dockerfile
    ├── docker-compose.yml
    ├── create-dev-env.ps1
    ├── run-cmd.ps1
    └── workspace/
```

## 使用流程

### 1. 环境创建
```powershell
# 进入语言目录
cd dotnet

# 运行环境创建脚本
.\create-dev-env.ps1

# 按提示输入配置信息
```

### 2. 开发使用
```powershell
# 使用通用命令执行脚本
.\run-cmd.ps1 dotnet restore
.\run-cmd.ps1 dotnet build
.\run-cmd.ps1 dotnet run
```

### 3. 环境管理
```powershell
# 启动环境
docker-compose --env-file .dev.env up -d

# 停止环境
docker-compose --env-file .dev.env down

# 查看日志
docker-compose --env-file .dev.env logs -f
```

## 优势

1. **标准化**: 每种语言都有统一的环境创建和使用方式
2. **灵活性**: 可以自定义容器名称、端口等配置
3. **易用性**: 简单的脚本接口，无需记忆复杂的docker命令
4. **可维护性**: 环境配置集中管理，便于团队协作
5. **扩展性**: 可以轻松添加新的语言环境支持

## 故障排除

### 常见问题

1. **端口冲突**: 修改`.dev.env`文件中的端口配置
2. **容器未启动**: 检查Docker Desktop是否运行
3. **权限问题**: 确保PowerShell以管理员身份运行

### 调试技巧

```powershell
# 查看容器状态
docker ps

# 查看容器日志
docker logs <container-name>

# 进入容器调试
docker exec -it <container-name> bash
```

## 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 许可证

MIT License

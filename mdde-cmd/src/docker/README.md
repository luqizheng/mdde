# Docker 模块使用说明

## 概述

`DockerCommand` 是一个Rust模块，提供了调用Docker命令行的功能。它使用 `std::process::Command` 来执行Docker命令，并提供了友好的错误处理和结果解析。

## 特性

- ✅ 调用真实的Docker命令行
- ✅ 完整的错误处理
- ✅ 中文错误消息
- ✅ 支持所有常用Docker操作
- ✅ 类型安全的API设计
- ✅ 详细的文档和示例

## 安装要求

- Rust 1.56+
- 系统已安装Docker
- Docker在系统PATH中

## 使用方法

### 1. 基本导入

```rust
use mdde_cmd::docker::{DockerCommand, DockerError};
```

### 2. 检查Docker安装

```rust
match DockerCommand::check_installed() {
    Ok(installed) => {
        if installed {
            println!("Docker已安装");
        } else {
            println!("Docker未安装");
        }
    }
    Err(e) => println!("检查失败: {}", e),
}
```

### 3. 获取Docker信息

```rust
// 获取版本
let version = DockerCommand::version()?;
println!("Docker版本: {}", version);

// 获取系统信息
let info = DockerCommand::info()?;
println!("Docker信息: {}", info);
```

### 4. 容器管理

```rust
// 列出所有容器
let containers = DockerCommand::ps_all()?;
println!("容器列表: {}", containers);

// 检查容器是否存在
let exists = DockerCommand::container_exists("my_container")?;
if exists {
    println!("容器存在");
}

// 检查容器是否运行
let running = DockerCommand::container_running("my_container")?;
if running {
    println!("容器正在运行");
}
```

### 5. 容器操作

```rust
// 启动容器
let result = DockerCommand::start_container("my_container")?;
println!("{}", result);

// 停止容器
let result = DockerCommand::stop_container("my_container")?;
println!("{}", result);

// 重启容器
let result = DockerCommand::restart_container("my_container")?;
println!("{}", result);

// 删除容器
let result = DockerCommand::rm_container("my_container", false)?;
println!("{}", result);
```

### 6. 在容器中执行命令

```rust
// 执行简单命令
let output = DockerCommand::exec_command("my_container", "ls -la")?;
println!("命令输出: {}", output);

// 执行复杂命令
let output = DockerCommand::exec_command("my_container", "echo 'Hello World' && date")?;
println!("命令输出: {}", output);
```

### 7. 获取容器信息

```rust
// 获取容器日志
let logs = DockerCommand::logs("my_container", Some(10))?;
println!("容器日志: {}", logs);

// 获取容器详细信息
let info = DockerCommand::inspect("my_container")?;
println!("容器信息: {}", info);
```

### 8. 镜像操作

```rust
// 拉取镜像
let result = DockerCommand::pull_image("hello-world")?;
println!("{}", result);

// 构建镜像
let result = DockerCommand::build_image("./dockerfile_path", "my_image:latest")?;
println!("{}", result);
```

### 9. 运行新容器

```rust
// 运行简单容器
let result = DockerCommand::run_container(
    "hello-world",
    "test_container",
    None,        // 端口映射
    None,        // 卷映射
    None,        // 环境变量
    true,        // 后台运行
)?;
println!("{}", result);

// 运行带端口映射的容器
let result = DockerCommand::run_container(
    "nginx:latest",
    "web_server",
    Some("8080:80"),     // 端口映射
    Some("/host/path:/container/path"), // 卷映射
    Some("ENV_VAR=value"), // 环境变量
    true,                 // 后台运行
)?;
println!("{}", result);
```

## 错误处理

所有函数都返回 `Result<T, DockerError>`，其中 `DockerError` 包含以下错误类型：

```rust
pub enum DockerError {
    CommandFailed(String),        // 命令执行失败
    OutputParseFailed(String),    // 输出解析失败
    DockerNotInstalled,           // Docker未安装
    ContainerNotFound(String),    // 容器不存在
    ContainerNotRunning(String),  // 容器未运行
}
```

### 错误处理示例

```rust
use std::error::Error;

fn main() -> Result<(), Box<dyn Error>> {
    match DockerCommand::start_container("nonexistent_container") {
        Ok(result) => println!("{}", result),
        Err(DockerError::ContainerNotFound(name)) => {
            println!("容器 {} 不存在", name);
        }
        Err(DockerError::CommandFailed(msg)) => {
            println!("命令执行失败: {}", msg);
        }
        Err(e) => println!("其他错误: {}", e),
    }
    Ok(())
}
```

## 异步支持

如果需要异步执行Docker命令，可以使用 `tokio::process::Command`：

```rust
use tokio::process::Command;

pub async fn docker_version_async() -> Result<String, DockerError> {
    let output = Command::new("docker")
        .arg("--version")
        .output()
        .await
        .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
    
    if output.status.success() {
        String::from_utf8(output.stdout)
            .map_err(|e| DockerError::OutputParseFailed(e.to_string()))
    } else {
        Err(DockerError::CommandFailed("Docker版本命令执行失败".to_string()))
    }
}
```

## 测试

运行测试：

```bash
cargo test docker
```

注意：测试需要系统已安装Docker，某些测试可能会失败。

## 示例

查看完整的使用示例：

```bash
cargo run --example docker_usage
```

## 注意事项

1. **安全性**: 直接执行Docker命令可能存在安全风险，请确保在受信任的环境中运行
2. **权限**: 某些Docker命令可能需要管理员权限
3. **路径**: 确保Docker在系统PATH中
4. **版本兼容性**: 不同版本的Docker可能有不同的命令输出格式

## 贡献

欢迎提交Issue和Pull Request来改进这个模块！

## 许可证

MIT License

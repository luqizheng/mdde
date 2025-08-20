use crate::config::Config;
use crate::error::MddeError;
use crate::http::MddeClient;
use colored::*;
use std::collections::HashMap;
use std::io::{self, Write};
use std::path::PathBuf;
use tracing::info;

/// 验证应用端口格式是否为 number:number
fn validate_app_port(port_mapping: &str) -> Result<(u16, u16), MddeError> {
    let parts: Vec<&str> = port_mapping.split(':').collect();
    
    if parts.len() != 2 {
        return Err(MddeError::InvalidPortFormat(format!(
            "应用端口格式错误: '{}'. 应为 host_port:container_port 格式，例如: 8080:80",
            port_mapping
        )));
    }
    
    let host_port = parts[0].parse::<u16>().map_err(|_| {
        MddeError::InvalidPortFormat(format!(
            "无效的主机端口: '{}'. 必须是 1-65535 之间的数字",
            parts[0]
        ))
    })?;
    
    let container_port = parts[1].parse::<u16>().map_err(|_| {
        MddeError::InvalidPortFormat(format!(
            "无效的容器端口: '{}'. 必须是 1-65535 之间的数字",
            parts[1]
        ))
    })?;
    
    if host_port == 0 || container_port == 0 {
        return Err(MddeError::InvalidPortFormat(
            "端口号不能为 0".to_string()
        ));
    }
    
    Ok((host_port, container_port))
}

pub async fn execute(
    dev_env: Option<String>,
    name: Option<String>,
    app_port: Option<String>,
    workspace: Option<String>,
    mut config: Config,
) -> Result<(), MddeError> {
    // 获取开发环境类型，如果没有提供则交互式询问
    let dev_env = match dev_env {
        Some(env) => {
            if env.trim().is_empty() {
                get_dev_env_interactively()?
            } else {
                env
            }
        }
        None => get_dev_env_interactively()?,
    };

    // 获取环境名称，如果没有提供则交互式询问
    let name = match name {
        Some(n) => {
            if n.trim().is_empty() {
                get_name_interactively()?
            } else {
                n
            }
        }
        None => get_name_interactively()?,
    };

    info!("创建开发环境: {} ({})", name.clone(), dev_env);

    // 验证应用端口格式
    let validated_app_port = if let Some(ref port_str) = app_port {
        let (host_port, container_port) = validate_app_port(port_str)?;
        Some((host_port, container_port, port_str.clone()))
    } else {
        None
    };

    // 确定工作目录
    let workspace_path = workspace
        .map(PathBuf::from)
        .unwrap_or_else(|| std::env::current_dir().unwrap_or_else(|_| PathBuf::from(".")));

    // 创建 HTTP 客户端
    let client = MddeClient::new(&config.host);

    // 确保 .mdde 目录存在
    let mdde_dir = workspace_path.join(".mdde");
    tokio::fs::create_dir_all(&mdde_dir).await?;

    // 下载 docker-compose.yml 文件
    let compose_content = client.download_script(&dev_env, "docker-compose.yml").await?;
    
    // 保存 docker-compose.yml 文件
    let compose_path = mdde_dir.join("docker-compose.yml");
    tokio::fs::write(&compose_path, compose_content).await?;
    println!("{}", "✓ 已下载 docker-compose.yml".green());

    // 下载 Dockerfile 文件（如果存在）
    match client.download_script(&dev_env, "Dockerfile").await {
        Ok(dockerfile_content) => {
            let dockerfile_path = mdde_dir.join("Dockerfile");
            tokio::fs::write(&dockerfile_path, dockerfile_content).await?;
            println!("{}", "✓ 已下载 Dockerfile".green());
        }
        Err(MddeError::HttpStatus(404)) => {
            // Dockerfile 不存在，这是正常情况
            println!("{}", "ℹ Dockerfile 不存在，使用默认镜像".yellow());
        }
        Err(e) => {
            // 其他错误，记录但不中断流程
            println!("{}", format!("⚠ 下载 Dockerfile 失败: {}", e).yellow());
        }
    }

    // 更新环境变量文件
    let mut env_vars = Config::load_env_file().await?;
    env_vars.insert("container_name".to_string(), name.clone());
    if let Some((_, _, port_str)) = &validated_app_port {
        env_vars.insert("app_port".to_string(), port_str.clone());
    }
    env_vars.insert("workspace".to_string(), workspace_path.to_string_lossy().to_string());
    
    Config::save_env_file(&env_vars).await?;

    // 更新配置
    let mut updates = HashMap::new();
    updates.insert("container_name".to_string(), name.clone());
    if let Some((_, _, port_str)) = &validated_app_port {
        updates.insert("app_port".to_string(), port_str.clone());
    }
    updates.insert("workspace".to_string(), workspace_path.to_string_lossy().to_string());
    config.update(updates).await?;

    println!("{}", "✓ 开发环境创建成功".green());
    println!("环境名称: {}", name);
    println!("环境类型: {}", dev_env);
    println!("工作目录: {}", workspace_path.display());
    if let Some((host_port, container_port, port_str)) = &validated_app_port {
        println!("应用端口: {} (主机端口:{} -> 容器端口:{})", port_str, host_port, container_port);
    }
    println!("配置文件: .mdde/docker-compose.yml");
    println!("环境变量文件: .mdde/cfg.env");
    
    // 检查是否下载了 Dockerfile
    let dockerfile_path = mdde_dir.join("Dockerfile");
    if dockerfile_path.exists() {
        println!("自定义镜像: .mdde/Dockerfile");
    }

    println!("\n{}", "下一步操作:".yellow());
    println!("1. 启动环境: mdde start");
    println!("2. 查看状态: mdde status");
    println!("3. 查看日志: mdde logs");

    Ok(())
}

/// 交互式获取开发环境类型
fn get_dev_env_interactively() -> Result<String, MddeError> {
    println!("{}", "请选择开发环境类型:".cyan());
    println!("可用选项:");
    println!("  - dotnet9      (.NET 9 开发环境)");
    println!("  - dotnet8      (.NET 8 开发环境)");
    println!("  - dotnet6      (.NET 6 开发环境)");
    println!("  - java21       (Java 21 开发环境)");
    println!("  - java18       (Java 18 开发环境)");
    println!("  - java11       (Java 11 开发环境)");
    println!("  - node22       (Node.js 22 开发环境)");
    println!("  - node20       (Node.js 20 开发环境)");
    println!("  - node18       (Node.js 18 开发环境)");
    println!("  - python312    (Python 3.12 开发环境)");
    println!("  - python311    (Python 3.11 开发环境)");
    
    print!("请输入开发环境类型: ");
    io::stdout().flush().map_err(|e| MddeError::Io(e))?;

    let mut input = String::new();
    io::stdin().read_line(&mut input).map_err(|e| MddeError::Io(e))?;
    
    let dev_env = input.trim();
    
    if dev_env.is_empty() {
        return Err(MddeError::InvalidInput("开发环境类型不能为空".to_string()));
    }

    // 验证输入的环境类型是否有效
    let valid_envs = [
        "dotnet9", "dotnet8", "dotnet6",
        "java21", "java18", "java11",
        "node22", "node20", "node18",
        "python312", "python311"
    ];
    
    if !valid_envs.contains(&dev_env) {
        return Err(MddeError::InvalidInput(format!(
            "无效的开发环境类型: '{}'. 请选择有效的环境类型", dev_env
        )));
    }
    
    Ok(dev_env.to_string())
}

/// 交互式获取环境名称
fn get_name_interactively() -> Result<String, MddeError> {
    println!("{}", "请输入环境名称:".cyan());
    print!("环境名称 (用于标识容器): ");
    io::stdout().flush().map_err(|e| MddeError::Io(e))?;

    let mut input = String::new();
    io::stdin().read_line(&mut input).map_err(|e| MddeError::Io(e))?;
    
    let name = input.trim();
    
    if name.is_empty() {
        return Err(MddeError::InvalidInput("环境名称不能为空".to_string()));
    }

    // 验证名称格式（只允许字母数字和连字符）
    if !name.chars().all(|c| c.is_alphanumeric() || c == '-' || c == '_') {
        return Err(MddeError::InvalidInput(
            "环境名称只能包含字母、数字、连字符和下划线".to_string()
        ));
    }
    
    Ok(name.to_string())
}

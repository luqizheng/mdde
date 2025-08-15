use crate::config::Config;
use crate::error::MddeError;
use crate::http::MddeClient;
use colored::*;
use std::collections::HashMap;
use std::path::PathBuf;
use tracing::info;

pub async fn execute(
    dev_env: String,
    name: String,
    debug_port: Option<u16>,
    workspace: Option<String>,
    mut config: Config,
) -> Result<(), MddeError> {
    info!("创建开发环境: {} ({})", name.clone(), dev_env);

    // 确定工作目录
    let workspace_path = workspace
        .map(PathBuf::from)
        .unwrap_or_else(|| std::env::current_dir().unwrap_or_else(|_| PathBuf::from(".")));

    // 创建 HTTP 客户端
    let client = MddeClient::new(&config.mdde_host);

    // 下载 docker-compose.yml 文件
    let compose_content = client.download_script(&dev_env, "docker-compose.yml").await?;
    
    // 保存 docker-compose.yml 文件
    let compose_path = workspace_path.join("docker-compose.yml");
    tokio::fs::write(&compose_path, compose_content).await?;

    // 更新环境变量文件
    let mut env_vars = Config::load_env_file().await?;
    env_vars.insert("container_name".to_string(), name.clone());
    if let Some(port) = debug_port {
        env_vars.insert("debug_port".to_string(), port.to_string());
    }
    env_vars.insert("workspace".to_string(), workspace_path.to_string_lossy().to_string());
    
    Config::save_env_file(&env_vars).await?;

    // 更新配置
    let mut updates = HashMap::new();
    updates.insert("container_name".to_string(), name.clone());
    if let Some(port) = debug_port {
        updates.insert("debug_port".to_string(), port.to_string());
    }
    updates.insert("workspace".to_string(), workspace_path.to_string_lossy().to_string());
    config.update(updates).await?;

    println!("{}", "✓ 开发环境创建成功".green());
    println!("环境名称: {}", name);
    println!("环境类型: {}", dev_env);
    println!("工作目录: {}", workspace_path.display());
    if let Some(port) = debug_port {
        println!("调试端口: {}", port);
    }
    println!("配置文件: docker-compose.yml");
    println!("环境变量文件: .mdde.env");

    println!("\n{}", "下一步操作:".yellow());
    println!("1. 启动环境: mdde start {}", name);
    println!("2. 查看状态: mdde status");
    println!("3. 查看日志: mdde logs {}", name);

    Ok(())
}

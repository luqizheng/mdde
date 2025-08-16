use crate::config::Config;
use crate::error::MddeError;
use colored::*;
use std::collections::HashMap;
use tracing::info;

pub async fn execute(host: String, mut config: Config) -> Result<(), MddeError> {
    info!("初始化 mdde 配置，服务器地址: {}", host);

    // 更新配置
    let mut updates = HashMap::new();
    updates.insert("mdde_host".to_string(), host.clone());
    config.update(updates).await?;

    // 创建环境变量文件
    let mut env_vars = HashMap::new();
    env_vars.insert("mdde_host".to_string(), host.clone());
    
    Config::save_env_file(&env_vars).await?;

    println!("{}", "✓ mdde 配置初始化成功".green());
    println!("服务器地址: {}", host);
    println!("环境变量文件已创建: .mdde/cfg.env");

    Ok(())
}

use crate::config::Config;
use crate::error::MddeError;
use colored::*;
use tracing::info;

pub async fn execute(name: String, config: Config) -> Result<(), MddeError> {
    info!("重启开发环境: {}", name);

    println!("{}", "重启开发环境...".yellow());

    // 先停止环境
    crate::commands::stop::execute(name.clone(), false, config.clone()).await?;
    
    // 等待一下确保完全停止
    tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
    
    // 再启动环境
    crate::commands::start::execute(name.clone(), true, config).await?;

    println!("{}", "✓ 开发环境重启成功".green());
    println!("环境名称: {}", name);

    Ok(())
}

use crate::config::Config;
use crate::error::MddeError;
use crate::i18n;
use colored::*;
use tracing::info;

pub async fn execute( config: Config) -> Result<(), MddeError> {
    let name = config.container_name.clone().unwrap_or("default".to_string());

    info!("重启开发环境: {}", name.clone());

    println!("{}", i18n::t("restarting_environment").yellow());

    // 先停止环境
    crate::commands::stop::execute(false, config.clone()).await?;
    
    // 等待一下确保完全停止
    tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
    
    // 再启动环境
    crate::commands::start::execute(true, config).await?;

    println!("{}", i18n::t("restart_success").green());
    println!("{}", i18n::tf("environment_name", &[&name]));

    Ok(())
}

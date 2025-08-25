use crate::config::Config;
use crate::error::MddeError;
use crate::i18n;
use crate::utils::DEFAULT_HOST;
use colored::*;
use std::collections::HashMap;
use std::io::{self, Write};
use tracing::info;

pub async fn execute(host: Option<String>, mut config: Config) -> Result<(), MddeError> {
    // 获取服务器地址，如果没有提供则交互式询问
    let host = match host {
        Some(h) => {
            if h.trim().is_empty() {
                get_host_interactively()?
            } else {
                h
            }
        }
        None => get_host_interactively()?,
    };

    info!("初始化 mdde 配置，服务器地址: {}", host);

    // 验证URL格式
    validate_url(&host)?;

    // 更新配置
    let mut updates = HashMap::new();
    updates.insert("host".to_string(), host.clone());
    config.update(updates).await?;

    // 创建环境变量文件
    let mut env_vars = HashMap::new();
    env_vars.insert("host".to_string(), host.clone());

    Config::save_env_file(&env_vars).await?;

    println!("{}", i18n::t("init_success").green());
    println!("{}", i18n::tf("server_address", &[&host]));
    println!("{}", i18n::t("env_file_created"));

    Ok(())
}

/// 交互式获取服务器地址
fn get_host_interactively() -> Result<String, MddeError> {
    println!("{}", i18n::t("enter_server_address").cyan());
    print!("{}", i18n::t("default_address"));
    io::stdout().flush().map_err(MddeError::Io)?;

    let mut input = String::new();
    io::stdin().read_line(&mut input).map_err(MddeError::Io)?;

    let host = input.trim();

    if host.is_empty() {
        Ok(DEFAULT_HOST.to_string())
    } else {
        Ok(host.to_string())
    }
}

/// 验证URL格式
fn validate_url(url: &str) -> Result<(), MddeError> {
    if !url.starts_with("http://") && !url.starts_with("https://") {
        return Err(MddeError::InvalidArgument(
            i18n::t("url_must_start_with").to_string(),
        ));
    }

    // 使用 url crate 进行更严格的验证
    match url::Url::parse(url) {
        Ok(_) => Ok(()),
        Err(_) => Err(MddeError::InvalidArgument(
            i18n::t("invalid_url_format").to_string(),
        )),
    }
}

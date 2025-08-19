use crate::config::Config;
use crate::error::MddeError;
use crate::i18n;
use colored::*;
use std::process::Command;
use tracing::info;

pub async fn execute(_config: Config) -> Result<(), MddeError> {
    info!("执行系统诊断");

    println!("{}", "🔍 MDDE 系统诊断".blue().bold());
    println!("{}", "=".repeat(50));

    // 检查 Docker
    check_docker()?;

    // 检查 Docker Compose
    check_docker_compose()?;

    // 检查网络连接
    check_network_connection(&_config).await?;

    // 检查配置文件
    check_config_files()?;

    println!("{}", "=".repeat(50));
    println!("{}", "✓ 诊断完成".green());

    Ok(())
}

fn check_docker() -> Result<(), MddeError> {
    println!("{}", "\n🐳 检查 Docker...".cyan());

    let output = Command::new("docker").arg("--version").output();
    match output {
        Ok(output) if output.status.success() => {
            let version = String::from_utf8_lossy(&output.stdout);
            println!("{}", i18n::t("docker_installed").green());
            println!("{}", i18n::tf("docker_version", &[&version.trim()]));
        }
        _ => {
            println!("{}", i18n::t("docker_not_installed").red());
            println!("{}", i18n::t("install_docker"));
            return Err(MddeError::Docker("Docker 未安装".to_string()));
        }
    }

    // 检查 Docker 服务状态
    let output = Command::new("docker").arg("info").output();
    match output {
        Ok(output) if output.status.success() => {
            println!("{}", i18n::t("docker_running").green());
        }
        _ => {
            println!("{}", i18n::t("docker_not_running").red());
            println!("{}", i18n::t("start_docker"));
            return Err(MddeError::Docker("Docker 服务未运行".to_string()));
        }
    }

    Ok(())
}

fn check_docker_compose() -> Result<(), MddeError> {
    println!("{}", format!("\n{}", i18n::t("check_docker_compose")).cyan());

    let output = Command::new("docker-compose").arg("--version").output();
    match output {
        Ok(output) if output.status.success() => {
            let version = String::from_utf8_lossy(&output.stdout);
            println!("{}", i18n::t("docker_compose_installed").green());
            println!("{}", i18n::tf("docker_version", &[&version.trim()]));
        }
        _ => {
            println!("{}", i18n::t("docker_compose_not_installed").red());
            println!("{}", i18n::t("install_docker_compose"));
            return Err(MddeError::Docker("Docker Compose 未安装".to_string()));
        }
    }

    Ok(())
}

async fn check_network_connection(config: &Config) -> Result<(), MddeError> {
    println!("{}", format!("\n{}", i18n::t("check_network")).cyan());

    let client = reqwest::Client::new();
    let response = client.get(&config.host).send().await;

    match response {
        Ok(response) if response.status().is_success() => {
            println!("{}", i18n::t("network_ok").green());
            println!("{}", i18n::tf("network_server", &[&config.host]));
        }
        Ok(response) => {
            println!("{}", i18n::t("server_response_error").yellow());
            println!("{}", i18n::tf("status_code", &[&response.status()]));
            println!("{}", i18n::tf("network_server", &[&config.host]));
        }
        Err(e) => {
            println!("{}", i18n::t("network_failed").red());
            println!("{}", i18n::tf("error_msg", &[&e]));
            println!("{}", i18n::tf("network_server", &[&config.host]));
        }
    }

    Ok(())
}

fn check_config_files() -> Result<(), MddeError> {
    println!("{}", format!("\n{}", i18n::t("check_config_files")).cyan());

    // 检查当前目录的配置文件
    let current_dir = std::env::current_dir()?;
    let compose_file = current_dir.join("docker-compose.yml");
    let env_file = current_dir.join(".mdde").join("cfg.env");

    if compose_file.exists() {
        println!("{}", i18n::t("docker_compose_exists").green());
    } else {
        println!("{}", i18n::t("docker_compose_not_exists").yellow());
        println!("{}", i18n::tf("current_dir", &[&current_dir.display()]));
    }

    if env_file.exists() {
        println!("{}", i18n::t("mdde_env_exists").green());
    } else {
        println!("{}", i18n::t("mdde_env_not_exists").yellow());
        println!("{}", i18n::tf("current_dir", &[&current_dir.display()]));
    }

    Ok(())
}

use crate::config::Config;
use crate::error::MddeError;
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
            println!("{}", "✓ Docker 已安装".green());
            println!("  版本: {}", version.trim());
        }
        _ => {
            println!("{}", "✗ Docker 未安装或无法访问".red());
            println!("  请安装 Docker Desktop 或 Docker Engine");
            return Err(MddeError::Docker("Docker 未安装".to_string()));
        }
    }

    // 检查 Docker 服务状态
    let output = Command::new("docker").arg("info").output();
    match output {
        Ok(output) if output.status.success() => {
            println!("{}", "✓ Docker 服务运行正常".green());
        }
        _ => {
            println!("{}", "✗ Docker 服务未运行".red());
            println!("  请启动 Docker 服务");
            return Err(MddeError::Docker("Docker 服务未运行".to_string()));
        }
    }

    Ok(())
}

fn check_docker_compose() -> Result<(), MddeError> {
    println!("{}", "\n📦 检查 Docker Compose...".cyan());

    let output = Command::new("docker-compose").arg("--version").output();
    match output {
        Ok(output) if output.status.success() => {
            let version = String::from_utf8_lossy(&output.stdout);
            println!("{}", "✓ Docker Compose 已安装".green());
            println!("  版本: {}", version.trim());
        }
        _ => {
            println!("{}", "✗ Docker Compose 未安装".red());
            println!("  请安装 Docker Compose");
            return Err(MddeError::Docker("Docker Compose 未安装".to_string()));
        }
    }

    Ok(())
}

async fn check_network_connection(config: &Config) -> Result<(), MddeError> {
    println!("{}", "\n🌐 检查网络连接...".cyan());

    let client = reqwest::Client::new();
    let response = client.get(&config.host).send().await;

    match response {
        Ok(response) if response.status().is_success() => {
            println!("{}", "✓ 网络连接正常".green());
            println!("  服务器: {}", config.host);
        }
        Ok(response) => {
            println!("{}", "⚠ 服务器响应异常".yellow());
            println!("  状态码: {}", response.status());
            println!("  服务器: {}", config.host);
        }
        Err(e) => {
            println!("{}", "✗ 网络连接失败".red());
            println!("  错误: {}", e);
            println!("  服务器: {}", config.host);
        }
    }

    Ok(())
}

fn check_config_files() -> Result<(), MddeError> {
    println!("{}", "\n📁 检查配置文件...".cyan());

    // 检查当前目录的配置文件
    let current_dir = std::env::current_dir()?;
    let compose_file = current_dir.join("docker-compose.yml");
    let env_file = current_dir.join(".mdde.env");

    if compose_file.exists() {
        println!("{}", "✓ docker-compose.yml 存在".green());
    } else {
        println!("{}", "⚠ docker-compose.yml 不存在".yellow());
        println!("  当前目录: {}", current_dir.display());
    }

    if env_file.exists() {
        println!("{}", "✓ .mdde.env 存在".green());
    } else {
        println!("{}", "⚠ .mdde.env 不存在".yellow());
        println!("  当前目录: {}", current_dir.display());
    }

    Ok(())
}

use crate::config::Config;
use crate::error::MddeError;
use colored::*;
use std::process::Command;
use tracing::info;

pub async fn execute(
    follow: bool,
    tail: Option<usize>,
    since: Option<String>,
    _config: Config,
) -> Result<(), MddeError> {

    let name =_config.container_name.clone();

    info!("查看开发环境日志: {}", name.clone().unwrap_or_default());

    // 检查 docker-compose.yml 文件是否存在
    let compose_file = std::env::current_dir()?.join("docker-compose.yml");
    if !compose_file.exists() {
        return Err(MddeError::FileOperation("docker-compose.yml 文件不存在".to_string()));
    }

    // 检查 .mdde.env 文件是否存在
    let env_file = std::env::current_dir()?.join(".mdde.env");
    if !env_file.exists() {
        return Err(MddeError::FileOperation(".mdde.env 文件不存在".to_string()));
    }

    // 构建 docker-compose 命令
    let mut cmd = Command::new("docker-compose");
    cmd.arg("--env-file").arg(".mdde.env");
    cmd.arg("logs");

    if follow {
        cmd.arg("-f");
    }

    if let Some(lines) = tail {
        cmd.arg("--tail").arg(lines.to_string());
    }

    if let Some(time) = since {
        cmd.arg("--since").arg(time);
    }

    println!("{}", "查看开发环境日志...".yellow());
    println!("命令: {}", format!("{:?}", cmd).cyan());

    if follow {
        // 实时跟踪日志
        println!("{}", "实时跟踪日志 (按 Ctrl+C 停止)...".cyan());
        let mut child = cmd.spawn()?;
        child.wait()?;
    } else {
        // 一次性查看日志
        let output = cmd.output()?;

        if output.status.success() {
            let logs_output = String::from_utf8_lossy(&output.stdout);
            if logs_output.trim().is_empty() {
                println!("{}", "暂无日志输出".yellow());
            } else {
                println!("{}", logs_output);
            }
        } else {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(MddeError::Docker(format!("获取日志失败: {}", stderr)));
        }
    }

    Ok(())
}

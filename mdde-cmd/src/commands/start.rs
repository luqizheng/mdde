use crate::config::Config;
use crate::error::MddeError;
use colored::*;
use std::process::Command;
use tracing::info;

pub async fn execute(detach: bool, _config: Config) -> Result<(), MddeError> {
    let name =_config.container_name.clone();

    info!("启动开发环境: {}", name.clone().unwrap_or_default());

    // 检查 docker-compose.yml 文件是否存在
    let compose_file = std::env::current_dir()?.join(".mdde").join("docker-compose.yml");
    if !compose_file.exists() {
        return Err(MddeError::FileOperation("docker-compose.yml 文件不存在".to_string()));
    }

    // 检查 .mdde.env 文件是否存在
    let env_file = std::env::current_dir()?.join(".mdde").join("cfg.env");
    if !env_file.exists() {
        return Err(MddeError::FileOperation(".mdde/cfg.env 文件不存在".to_string()));
    }

    // 构建 docker-compose 命令
    let mut cmd = Command::new("docker-compose");
    cmd.arg("--env-file").arg(".mdde/cfg.env");
    cmd.arg("--file").arg(".mdde/docker-compose.yml");
    if detach {
        cmd.arg("up").arg("-d");
    } else {
        cmd.arg("up");
    }

    println!("{}", "启动开发环境...".yellow());
    println!("命令: {}", format!("{:?}", cmd).cyan());

    // 执行命令
    let output = cmd.output()?;

    if output.status.success() {
        println!("{}", "✓ 开发环境启动成功".green());
        if detach {
            println!("环境已在后台运行");
            println!("查看日志: mdde logs");
            println!("查看状态: mdde status");
        }
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(MddeError::Docker(format!("启动失败: {}", stderr)));
    }

    Ok(())
}

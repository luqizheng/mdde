use crate::config::Config;
use crate::error::MddeError;
use colored::*;
use std::process::Command;
use tracing::info;

pub async fn execute(remove: bool, _config: Config) -> Result<(), MddeError> {
    let name =_config.container_name.clone().unwrap_or("default".to_string());

    info!("停止开发环境: {}", name.clone());

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
    
    if remove {
        cmd.arg("down").arg("--volumes");
    } else {
        cmd.arg("down");
    }

    println!("{}", "停止开发环境...".yellow());
    println!("命令: {}", format!("{:?}", cmd).cyan());

    // 执行命令
    let output = cmd.output()?;

    if output.status.success() {
        println!("{}", "✓ 开发环境已停止".green());
        if remove {
            println!("容器和卷已删除");
        }
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(MddeError::Docker(format!("停止失败: {}", stderr)));
    }

    Ok(())
}

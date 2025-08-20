use crate::config::Config;
use crate::docker::DockerCommand;
use crate::error::MddeError;
use colored::*;
use tracing::info;

pub async fn execute(shell: String, config: Config) -> Result<(), MddeError> {
    let container_name = config
        .container_name
        .clone()
        .unwrap_or("default".to_string());

    info!(
        "进入容器 {} 进行交互式操作，使用 shell: {}",
        container_name, shell
    );

    println!(
        "{}",
        format!("正在进入容器 {} 进行交互式操作...", container_name).blue()
    );
    println!("{}", format!("使用 shell: {}", shell).cyan());
    println!("{}", "提示：输入 'exit' 或按 Ctrl+D 退出容器".yellow());

    // 检查容器是否正在运行
    if !DockerCommand::container_running(&container_name)? {
        return Err(MddeError::ContainerNotRunning(container_name));
    }

    // 进入容器进行交互式操作
    match DockerCommand::exec_interactive(&container_name, &shell) {
        Ok(_) => {
            println!("{}", "✓ 已退出容器".green());
        }
        Err(e) => {
            println!("{}", format!("✗ 进入容器失败: {}", e).red());
            return Err(MddeError::Docker(e.to_string()));
        }
    }

    Ok(())
}

use crate::config::Config;
use crate::error::MddeError;
use crate::docker::DockerCommand;
use colored::*;
use tracing::info;

pub async fn execute(command: Vec<String>, config: Config) -> Result<(), MddeError> {
    let container_name = config.container_name.clone().unwrap_or("default".to_string());
    
    if command.is_empty() {
        return Err(MddeError::InvalidInput("请提供要执行的命令".to_string()));
    }
    
    let command_str = command.join(" ");
    info!("在容器 {} 中执行命令: {}", container_name, command_str);
    
    println!("{}", format!("在容器 {} 中执行命令: {}", container_name, command_str).blue());
    
    // 检查容器是否正在运行
    if !DockerCommand::container_running(&container_name)? {
        return Err(MddeError::ContainerNotRunning(container_name));
    }
    
    // 执行命令
    match DockerCommand::exec_command(&container_name, &command_str) {
        Ok(output) => {
            if !output.trim().is_empty() {
                println!("{}", output);
            }
            println!("{}", "✓ 命令执行成功".green());
        }
        Err(e) => {
            println!("{}", format!("✗ 命令执行失败: {}", e).red());
            return Err(MddeError::Docker(e.to_string()));
        }
    }
    
    Ok(())
}

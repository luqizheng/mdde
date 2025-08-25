use crate::config::Config;
use crate::docker::DockerCommand;
use crate::error::MddeError;
use crate::i18n;
use colored::*;
use tracing::info;

pub async fn execute(command: Vec<String>, config: Config) -> Result<(), MddeError> {
    let container_name = config
        .container_name
        .clone()
        .unwrap_or("default".to_string());

    if command.is_empty() {
        return Err(MddeError::InvalidInput(i18n::t("provide_command").to_string()));
    }

    let command_str = command.join(" ");
    info!("{}", i18n::tf("execute_command_in_container", &[&container_name, &command_str]));

    println!(
        "{}",
        i18n::tf("execute_command_in_container", &[&container_name, &command_str]).blue()
    );

    // 检查容器是否正在运行
    if !DockerCommand::container_running(&container_name)? {
        return Err(MddeError::ContainerNotRunning(container_name));
    }

    // 执行命令，实时输出
    match DockerCommand::exec_command_stream(&container_name, &command_str) {
        Ok(()) => {
            println!("{}", i18n::t("command_success").green());
        }
        Err(e) => {
            println!("{}", i18n::tf("command_failed", &[&e]).red());
            return Err(MddeError::Docker(e.to_string()));
        }
    }

    Ok(())
}

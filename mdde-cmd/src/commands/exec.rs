use crate::config::Config;
use crate::docker::DockerCommand;
use crate::error::MddeError;
use crate::i18n;
use colored::*;
use tracing::info;

pub async fn execute(shell: String, config: Config) -> Result<(), MddeError> {
    let container_name = config
        .container_name
        .clone()
        .unwrap_or("default".to_string());

    info!(
        "{}", 
        i18n::tf("enter_container_interactive", &[&container_name, &shell])
    );

    println!(
        "{}",
        i18n::tf("entering_container", &[&container_name]).blue()
    );
    println!("{}", i18n::tf("using_shell", &[&shell]).cyan());
    println!("{}", i18n::t("exit_hint").yellow());

    // 检查容器是否正在运行
    if !DockerCommand::container_running(&container_name)? {
        return Err(MddeError::ContainerNotRunning(container_name));
    }

    // 进入容器进行交互式操作
    match DockerCommand::exec_interactive(&container_name, &shell) {
        Ok(_) => {
            println!("{}", i18n::t("exited_container").green());
        }
        Err(e) => {
            println!("{}", i18n::tf("enter_container_failed", &[&e]).red());
            return Err(MddeError::Docker(e.to_string()));
        }
    }

    Ok(())
}

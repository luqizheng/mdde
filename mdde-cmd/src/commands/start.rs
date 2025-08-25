use crate::config::Config;
use crate::docker::DockerCommand;
use crate::error::MddeError;
use crate::i18n;
use colored::*;
use tracing::info;

pub async fn execute(detach: bool, _config: Config) -> Result<(), MddeError> {
    let name = _config.container_name.clone();

    info!("{}", i18n::tf("start_env_name", &[&name.clone().unwrap_or_default()]));

    println!("{}", i18n::t("starting_environment").yellow());

    // 使用新的实时输出方法启动环境
    match DockerCommand::start_environment_stream(detach) {
        Ok(()) => {
            println!("{}", i18n::t("environment_started").green());
            if detach {
                println!("{}", i18n::t("running_in_background"));
                println!("{}", i18n::t("view_logs"));
                println!("{}", i18n::t("view_status"));
            }
        }
        Err(e) => {
            return Err(MddeError::Docker(i18n::tf("start_failed", &[&e])));
        }
    }

    Ok(())
}

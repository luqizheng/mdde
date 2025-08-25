use crate::config::Config;
use crate::error::MddeError;
use crate::i18n;
use colored::*;
use std::process::Command;
use tracing::info;

pub async fn execute(remove: bool, _config: Config) -> Result<(), MddeError> {
    let name = _config
        .container_name
        .clone()
        .unwrap_or("default".to_string());

    info!("{}", i18n::tf("stop_env_name", &[&name]));

    // 检查 docker-compose.yml 文件是否存在
    let compose_file = std::env::current_dir()?
        .join(".mdde")
        .join("docker-compose.yml");
    if !compose_file.exists() {
        return Err(MddeError::FileOperation(
            i18n::t("docker_compose_not_exists").to_string(),
        ));
    }

    // 检查 .mdde.env 文件是否存在
    let env_file = std::env::current_dir()?.join(".mdde").join("cfg.env");
    if !env_file.exists() {
        return Err(MddeError::FileOperation(
            i18n::t("mdde_cfg_env_not_exists").to_string(),
        ));
    }

    // 构建 docker-compose 命令
    let mut cmd = Command::new("docker-compose");
    cmd.arg("--env-file").arg(".mdde/cfg.env");
    cmd.arg("--file").arg(".mdde/docker-compose.yml");

    if remove {
        cmd.arg("down").arg("--volumes");
    } else {
        cmd.arg("down");
    }

    println!("{}", i18n::t("stopping_environment").yellow());
    println!("{}", i18n::tf("command", &[&format!("{:?}", cmd).cyan()]));

    // 执行命令
    let output = cmd.output()?;

    if output.status.success() {
        println!("{}", i18n::t("environment_stopped").green());
        if remove {
            println!("{}", i18n::t("containers_volumes_removed"));
        }
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(MddeError::Docker(i18n::tf("stop_failed", &[&stderr])));
    }

    Ok(())
}

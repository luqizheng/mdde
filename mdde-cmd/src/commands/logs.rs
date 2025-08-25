use crate::config::Config;
use crate::error::MddeError;
use crate::i18n;
use colored::*;
use std::process::Command;
use tracing::info;

pub async fn execute(
    lines: Option<usize>,
    tail: Option<usize>,
    all: bool,
    follow: bool,
    config: Config,
) -> Result<(), MddeError> {
    // 从环境变量文件获取容器名称
    let env_vars = Config::load_env_file().await?;
    let container_name = env_vars.get("container_name")
        .or(config.container_name.as_ref())
        .ok_or_else(|| MddeError::EnvironmentNotFound(
            i18n::t("container_name_not_found").to_string()
        ))?;

    info!("{}", i18n::tf("view_container_logs", &[&container_name]));

    // 构建 docker logs 命令
    let mut cmd = Command::new("docker");
    cmd.arg("logs");
    cmd.arg(container_name);

    // 处理参数
    if follow {
        cmd.arg("-f");
    }

    // 确定要显示的行数：位置参数优先，然后是 --tail，最后是默认值
    let display_lines = lines.or(tail);

    if all {
        // 显示所有日志，不添加 --tail 参数
        println!(
            "{}",
            i18n::tf("show_all_logs", &[&container_name]).yellow()
        );
    } else if let Some(num_lines) = display_lines {
        cmd.arg("--tail").arg(num_lines.to_string());
        println!(
            "{}",
            i18n::tf("show_last_n_logs", &[&num_lines, &container_name]).yellow()
        );
    } else {
        // 默认显示最后 50 行
        cmd.arg("--tail").arg("50");
        println!(
            "{}",
            i18n::tf("show_last_50_logs", &[&container_name]).yellow()
        );
    }

    println!(
        "{}",
        i18n::tf("execute_command_label", &[&format!(
            "docker logs {}",
            if follow {
                format!("-f {}", container_name)
            } else if all {
                container_name.to_string()
            } else {
                format!("--tail {} {}", display_lines.unwrap_or(50), container_name)
            }
        ).cyan()])
    );

    if follow {
        // 实时跟踪日志
        println!("{}", i18n::t("follow_logs_realtime").green());
        let mut child = cmd.spawn()?;
        let status = child.wait()?;

        if !status.success() {
            return Err(MddeError::Docker(
                i18n::tf("get_logs_failed", &[&container_name])
            ));
        }
    } else {
        // 一次性查看日志
        let output = cmd.output()?;

        if output.status.success() {
            let logs_output = String::from_utf8_lossy(&output.stdout);
            if logs_output.trim().is_empty() {
                println!("{}", i18n::t("no_log_output").yellow());
                println!("{}", i18n::t("container_not_running_hint"));
            } else {
                println!("{}", logs_output);
            }
        } else {
            let stderr = String::from_utf8_lossy(&output.stderr);
            if stderr.contains("No such container") {
                return Err(MddeError::ContainerNotRunning(
                    i18n::tf("container_not_exists", &[&container_name])
                ));
            } else {
                return Err(MddeError::Docker(i18n::tf("get_logs_error", &[&stderr])));
            }
        }
    }

    Ok(())
}

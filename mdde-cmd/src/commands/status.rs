use crate::cli::OutputFormat;
use crate::config::Config;
use crate::error::MddeError;
use crate::i18n;
use colored::*;
use serde_json::json;
use std::process::Command;
use tracing::info;

pub async fn execute(format: OutputFormat, _config: Config) -> Result<(), MddeError> {
    info!("查看开发环境状态");

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

    // 获取 docker-compose 状态
    let mut cmd = Command::new("docker-compose");
    cmd.arg("--env-file").arg(".mdde/cfg.env");
    cmd.arg("--file").arg(".mdde/docker-compose.yml");
    cmd.arg("ps");

    let output = cmd.output()?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(MddeError::Docker(format!("获取状态失败: {}", stderr)));
    }

    let status_output = String::from_utf8_lossy(&output.stdout);

    match format {
        OutputFormat::Table => {
            println!("{}", i18n::t("environment_status").yellow());
            println!("{}", status_output);
        }
        OutputFormat::Json => {
            // 解析状态输出并转换为 JSON
            let status_info = parse_status_output(&status_output);
            let json_output = json!({
                "status": "success",
                "data": status_info
            });
            println!("{}", serde_json::to_string_pretty(&json_output)?);
        }
        OutputFormat::Yaml => {
            // 解析状态输出并转换为 YAML
            let status_info = parse_status_output(&status_output);
            let yaml_output = serde_yaml::to_string(&status_info)
                .map_err(MddeError::Yaml)?;
            println!("{}", yaml_output);
        }
    }

    Ok(())
}

fn parse_status_output(output: &str) -> serde_json::Value {
    let lines: Vec<&str> = output.lines().collect();
    let mut containers = Vec::new();

    for line in lines.iter().skip(1) {
        if line.trim().is_empty() {
            continue;
        }

        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 4 {
            let container = json!({
                "name": parts[0],
                "command": parts[1],
                "service": parts[2],
                "state": parts[3],
                "ports": if parts.len() > 4 { parts[4] } else { "" }
            });
            containers.push(container);
        }
    }

    json!({
        "containers": containers,
        "total": containers.len()
    })
}

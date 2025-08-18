use crate::config::Config;
use crate::error::MddeError;
use crate::i18n;
use colored::*;
use std::process::Command;
use tracing::info;

pub async fn execute(
    all: bool,
    images: bool,
    containers: bool,
    volumes: bool,
    _config: Config,
) -> Result<(), MddeError> {
    info!("清理 Docker 资源");

    if all {
        println!("{}", i18n::t("clean_all_resources").yellow());
        
        // 清理所有未使用的资源
        let mut cmd = Command::new("docker");
        cmd.arg("system").arg("prune").arg("-a").arg("-f");
        
        let output = cmd.output()?;
        if output.status.success() {
            let result = String::from_utf8_lossy(&output.stdout);
            println!("{}", i18n::t("clean_completed").green());
            println!("{}", result);
        } else {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(MddeError::Docker(format!("清理失败: {}", stderr)));
        }
    } else {
        // 分别清理不同类型的资源
        if images {
            println!("{}", i18n::t("clean_images").yellow());
            let mut cmd = Command::new("docker");
            cmd.arg("image").arg("prune").arg("-f");
            
            let output = cmd.output()?;
            if output.status.success() {
                let result = String::from_utf8_lossy(&output.stdout);
                println!("{}", i18n::t("images_clean_completed").green());
                println!("{}", result);
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(MddeError::Docker(format!("镜像清理失败: {}", stderr)));
            }
        }

        if containers {
            println!("{}", i18n::t("clean_containers").yellow());
            let mut cmd = Command::new("docker");
            cmd.arg("container").arg("prune").arg("-f");
            
            let output = cmd.output()?;
            if output.status.success() {
                let result = String::from_utf8_lossy(&output.stdout);
                println!("{}", i18n::t("containers_clean_completed").green());
                println!("{}", result);
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(MddeError::Docker(format!("容器清理失败: {}", stderr)));
            }
        }

        if volumes {
            println!("{}", i18n::t("clean_volumes").yellow());
            let mut cmd = Command::new("docker");
            cmd.arg("volume").arg("prune").arg("-f");
            
            let output = cmd.output()?;
            if output.status.success() {
                let result = String::from_utf8_lossy(&output.stdout);
                println!("{}", i18n::t("volumes_clean_completed").green());
                println!("{}", result);
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(MddeError::Docker(format!("卷清理失败: {}", stderr)));
            }
        }

        if !images && !containers && !volumes {
            println!("{}", i18n::t("specify_resource_type").yellow());
            println!("{}", i18n::t("use_all_flag"));
            println!("{}", i18n::t("use_images_flag"));
            println!("{}", i18n::t("use_containers_flag"));
            println!("{}", i18n::t("use_volumes_flag"));
        }
    }

    Ok(())
}

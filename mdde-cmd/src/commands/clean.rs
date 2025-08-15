use crate::config::Config;
use crate::error::MddeError;
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
        println!("{}", "清理所有未使用的 Docker 资源...".yellow());
        
        // 清理所有未使用的资源
        let mut cmd = Command::new("docker");
        cmd.arg("system").arg("prune").arg("-a").arg("-f");
        
        let output = cmd.output()?;
        if output.status.success() {
            let result = String::from_utf8_lossy(&output.stdout);
            println!("{}", "✓ 清理完成".green());
            println!("{}", result);
        } else {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(MddeError::Docker(format!("清理失败: {}", stderr)));
        }
    } else {
        // 分别清理不同类型的资源
        if images {
            println!("{}", "清理未使用的镜像...".yellow());
            let mut cmd = Command::new("docker");
            cmd.arg("image").arg("prune").arg("-f");
            
            let output = cmd.output()?;
            if output.status.success() {
                let result = String::from_utf8_lossy(&output.stdout);
                println!("{}", "✓ 镜像清理完成".green());
                println!("{}", result);
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(MddeError::Docker(format!("镜像清理失败: {}", stderr)));
            }
        }

        if containers {
            println!("{}", "清理未使用的容器...".yellow());
            let mut cmd = Command::new("docker");
            cmd.arg("container").arg("prune").arg("-f");
            
            let output = cmd.output()?;
            if output.status.success() {
                let result = String::from_utf8_lossy(&output.stdout);
                println!("{}", "✓ 容器清理完成".green());
                println!("{}", result);
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(MddeError::Docker(format!("容器清理失败: {}", stderr)));
            }
        }

        if volumes {
            println!("{}", "清理未使用的卷...".yellow());
            let mut cmd = Command::new("docker");
            cmd.arg("volume").arg("prune").arg("-f");
            
            let output = cmd.output()?;
            if output.status.success() {
                let result = String::from_utf8_lossy(&output.stdout);
                println!("{}", "✓ 卷清理完成".green());
                println!("{}", result);
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(MddeError::Docker(format!("卷清理失败: {}", stderr)));
            }
        }

        if !images && !containers && !volumes {
            println!("{}", "请指定要清理的资源类型".yellow());
            println!("使用 --all 清理所有资源");
            println!("使用 --images 清理镜像");
            println!("使用 --containers 清理容器");
            println!("使用 --volumes 清理卷");
        }
    }

    Ok(())
}

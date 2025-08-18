use crate::config::Config;
use crate::error::MddeError;
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
        .or_else(|| config.container_name.as_ref())
        .ok_or_else(|| MddeError::EnvironmentNotFound(
            "未找到容器名称，请先运行 'mdde create' 创建环境或使用 'mdde env --set container_name=your_name' 设置容器名".to_string()
        ))?;

    info!("查看容器日志: {}", container_name);

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
        println!("{}", format!("显示容器 {} 的所有日志...", container_name).yellow());
    } else if let Some(num_lines) = display_lines {
        cmd.arg("--tail").arg(num_lines.to_string());
        println!("{}", format!("显示容器 {} 的最后 {} 行日志...", container_name, num_lines).yellow());
    } else {
        // 默认显示最后 50 行
        cmd.arg("--tail").arg("50");
        println!("{}", format!("显示容器 {} 的最后 50 行日志...", container_name).yellow());
    }

    println!("执行命令: {}", format!("docker logs {}", 
        if follow { format!("-f {}", container_name) } 
        else if all { container_name.to_string() }
        else { format!("--tail {} {}", display_lines.unwrap_or(50), container_name) }
    ).cyan());

    if follow {
        // 实时跟踪日志
        println!("{}", "实时跟踪日志 (按 Ctrl+C 停止)...".green());
        let mut child = cmd.spawn()?;
        let status = child.wait()?;
        
        if !status.success() {
            return Err(MddeError::Docker(format!(
                "获取日志失败，容器 '{}' 可能不存在或未运行", container_name
            )));
        }
    } else {
        // 一次性查看日志
        let output = cmd.output()?;

        if output.status.success() {
            let logs_output = String::from_utf8_lossy(&output.stdout);
            if logs_output.trim().is_empty() {
                println!("{}", "暂无日志输出".yellow());
                println!("提示: 容器可能未运行或没有产生日志输出");
            } else {
                println!("{}", logs_output);
            }
        } else {
            let stderr = String::from_utf8_lossy(&output.stderr);
            if stderr.contains("No such container") {
                return Err(MddeError::ContainerNotRunning(format!(
                    "容器 '{}' 不存在。请检查容器名称或先启动容器", container_name
                )));
            } else {
                return Err(MddeError::Docker(format!("获取日志失败: {}", stderr)));
            }
        }
    }

    Ok(())
}

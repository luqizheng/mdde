use std::process::Command;
use std::error::Error;
use std::fmt;

/// Docker命令执行器
pub struct DockerCommand;

/// Docker错误类型
#[derive(Debug)]
pub enum DockerError {
    CommandFailed(String),
    OutputParseFailed(String),
    DockerNotInstalled,
    ContainerNotFound(String),
    ContainerNotRunning(String),
}

impl fmt::Display for DockerError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            DockerError::CommandFailed(msg) => write!(f, "Docker命令执行失败: {}", msg),
            DockerError::OutputParseFailed(msg) => write!(f, "输出解析失败: {}", msg),
            DockerError::DockerNotInstalled => write!(f, "Docker未安装或不在PATH中"),
            DockerError::ContainerNotFound(name) => write!(f, "容器不存在: {}", name),
            DockerError::ContainerNotRunning(name) => write!(f, "容器未运行: {}", name),
        }
    }
}

impl Error for DockerError {}

impl DockerCommand {
    /// 检查Docker是否已安装
    pub fn check_installed() -> Result<bool, DockerError> {
        match Command::new("docker").arg("--version").output() {
            Ok(output) => Ok(output.status.success()),
            Err(_) => Err(DockerError::DockerNotInstalled),
        }
    }

    /// 获取Docker版本信息
    pub fn version() -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("--version")
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            String::from_utf8(output.stdout)
                .map_err(|e| DockerError::OutputParseFailed(e.to_string()))
        } else {
            Err(DockerError::CommandFailed("Docker版本命令执行失败".to_string()))
        }
    }

    /// 获取Docker系统信息
    pub fn info() -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("info")
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            String::from_utf8(output.stdout)
                .map_err(|e| DockerError::OutputParseFailed(e.to_string()))
        } else {
            Err(DockerError::CommandFailed("Docker信息命令执行失败".to_string()))
        }
    }

    /// 列出所有容器
    pub fn ps_all() -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("ps")
            .arg("-a")
            .arg("--format")
            .arg("table {{.Names}}\t{{.Status}}\t{{.Image}}")
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            String::from_utf8(output.stdout)
                .map_err(|e| DockerError::OutputParseFailed(e.to_string()))
        } else {
            Err(DockerError::CommandFailed("Docker ps命令执行失败".to_string()))
        }
    }

    /// 列出运行中的容器
    pub fn ps_running() -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("ps")
            .arg("--format")
            .arg("table {{.Names}}\t{{.Status}}\t{{.Image}}")
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            String::from_utf8(output.stdout)
                .map_err(|e| DockerError::OutputParseFailed(e.to_string()))
        } else {
            Err(DockerError::CommandFailed("Docker ps命令执行失败".to_string()))
        }
    }

    /// 检查容器是否存在
    pub fn container_exists(name: &str) -> Result<bool, DockerError> {
        let output = Command::new("docker")
            .arg("ps")
            .arg("-a")
            .arg("--filter")
            .arg(format!("name=^{}$", name))
            .arg("--format")
            .arg("{{.Names}}")
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            let output_str = String::from_utf8(output.stdout)
                .map_err(|e| DockerError::OutputParseFailed(e.to_string()))?;
            Ok(!output_str.trim().is_empty())
        } else {
            Err(DockerError::CommandFailed("检查容器存在性失败".to_string()))
        }
    }

    /// 检查容器是否正在运行
    pub fn container_running(name: &str) -> Result<bool, DockerError> {
        let output = Command::new("docker")
            .arg("ps")
            .arg("--filter")
            .arg(format!("name=^{}$", name))
            .arg("--format")
            .arg("{{.Names}}")
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            let output_str = String::from_utf8(output.stdout)
                .map_err(|e| DockerError::OutputParseFailed(e.to_string()))?;
            Ok(!output_str.trim().is_empty())
        } else {
            Err(DockerError::CommandFailed("检查容器运行状态失败".to_string()))
        }
    }

    /// 启动容器
    pub fn start_container(name: &str) -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("start")
            .arg(name)
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            Ok(format!("容器 {} 启动成功", name))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("启动容器失败: {}", error_msg)))
        }
    }

    /// 停止容器
    pub fn stop_container(name: &str) -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("stop")
            .arg(name)
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            Ok(format!("容器 {} 停止成功", name))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("停止容器失败: {}", error_msg)))
        }
    }

    /// 重启容器
    pub fn restart_container(name: &str) -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("restart")
            .arg(name)
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            Ok(format!("容器 {} 重启成功", name))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("重启容器失败: {}", error_msg)))
        }
    }

    /// 在容器中执行命令
    pub fn exec_command(container: &str, command: &str) -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("exec")
            .arg(container)
            .arg("sh")
            .arg("-c")
            .arg(command)
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            String::from_utf8(output.stdout)
                .map_err(|e| DockerError::OutputParseFailed(e.to_string()))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("执行命令失败: {}", error_msg)))
        }
    }

    /// 进入容器进行交互式操作
    pub fn exec_interactive(container: &str, shell: &str) -> Result<(), DockerError> {
        use std::process::Stdio;
        
        let mut cmd = Command::new("docker");
        cmd.arg("exec")
            .arg("-it")
            .arg(container)
            .arg(shell)
            .stdin(Stdio::inherit())
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit());
        
        let status = cmd.status()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if status.success() {
            Ok(())
        } else {
            Err(DockerError::CommandFailed(format!("交互式执行失败，退出代码: {}", 
                status.code().unwrap_or(-1))))
        }
    }

    /// 获取容器日志
    pub fn logs(container: &str, tail: Option<u32>) -> Result<String, DockerError> {
        let mut cmd = Command::new("docker");
        cmd.arg("logs");
        
        if let Some(lines) = tail {
            cmd.arg("--tail").arg(lines.to_string());
        }
        
        cmd.arg(container);
        
        let output = cmd.output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            String::from_utf8(output.stdout)
                .map_err(|e| DockerError::OutputParseFailed(e.to_string()))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("获取容器日志失败: {}", error_msg)))
        }
    }

    /// 获取容器状态信息
    pub fn inspect(container: &str) -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("inspect")
            .arg(container)
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            String::from_utf8(output.stdout)
                .map_err(|e| DockerError::OutputParseFailed(e.to_string()))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("获取容器信息失败: {}", error_msg)))
        }
    }

    /// 删除容器
    pub fn rm_container(name: &str, force: bool) -> Result<String, DockerError> {
        let mut cmd = Command::new("docker");
        cmd.arg("rm");
        
        if force {
            cmd.arg("-f");
        }
        
        cmd.arg(name);
        
        let output = cmd.output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            Ok(format!("容器 {} 删除成功", name))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("删除容器失败: {}", error_msg)))
        }
    }

    /// 构建镜像
    pub fn build_image(path: &str, tag: &str) -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("build")
            .arg("-t")
            .arg(tag)
            .arg(path)
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            Ok(format!("镜像 {} 构建成功", tag))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("构建镜像失败: {}", error_msg)))
        }
    }

    /// 拉取镜像
    pub fn pull_image(image: &str) -> Result<String, DockerError> {
        let output = Command::new("docker")
            .arg("pull")
            .arg(image)
            .output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            Ok(format!("镜像 {} 拉取成功", image))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("拉取镜像失败: {}", error_msg)))
        }
    }

    /// 运行容器
    pub fn run_container(
        image: &str,
        name: &str,
        ports: Option<&str>,
        volumes: Option<&str>,
        env: Option<&str>,
        detach: bool,
    ) -> Result<String, DockerError> {
        let mut cmd = Command::new("docker");
        cmd.arg("run");
        
        if detach {
            cmd.arg("-d");
        }
        
        if let Some(port_mapping) = ports {
            cmd.arg("-p").arg(port_mapping);
        }
        
        if let Some(volume_mapping) = volumes {
            cmd.arg("-v").arg(volume_mapping);
        }
        
        if let Some(env_vars) = env {
            cmd.arg("-e").arg(env_vars);
        }
        
        cmd.arg("--name").arg(name);
        cmd.arg(image);
        
        let output = cmd.output()
            .map_err(|e| DockerError::CommandFailed(e.to_string()))?;
        
        if output.status.success() {
            Ok(format!("容器 {} 启动成功", name))
        } else {
            let error_msg = String::from_utf8_lossy(&output.stderr);
            Err(DockerError::CommandFailed(format!("启动容器失败: {}", error_msg)))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_check_docker_installed() {
        let result = DockerCommand::check_installed();
        // 这个测试可能失败，取决于系统是否安装了Docker
        assert!(result.is_ok());
    }

    #[test]
    fn test_docker_version() {
        let result = DockerCommand::version();
        // 这个测试可能失败，取决于系统是否安装了Docker
        if result.is_ok() {
            let version = result.unwrap();
            assert!(version.contains("Docker"));
        }
    }
}

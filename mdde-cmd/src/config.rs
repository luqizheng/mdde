use crate::error::MddeError;
use crate::utils::DEFAULT_HOST;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use tokio::fs;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub host: String,
    pub container_name: Option<String>,
    pub app_port: Option<u16>,
    pub workspace: Option<PathBuf>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            host: DEFAULT_HOST.to_string(),
            container_name: None,
            app_port: None,
            workspace: None,
        }
    }
}

impl Config {
    /// 加载配置文件
    pub async fn load() -> Result<Self, MddeError> {
        // 从 .mdde.env 文件加载配置
        let env_vars = Self::load_env_file().await?;

        let mut config = Config::default();

        // 从环境变量文件覆盖配置
        if let Some(host) = env_vars.get("host") {
            config.host = host.clone();
        }
        if let Some(container_name) = env_vars.get("container_name") {
            config.container_name = Some(container_name.clone());
        }
        if let Some(app_port) = env_vars.get("app_port") {
            if let Ok(port) = app_port.parse::<u16>() {
                config.app_port = Some(port);
            }
        }
        if let Some(workspace) = env_vars.get("workspace") {
            config.workspace = Some(PathBuf::from(workspace));
        }

        Ok(config)
    }

    /// 保存配置文件
    pub async fn save(&self) -> Result<(), MddeError> {
        let mut env_vars = HashMap::new();

        // 将配置转换为环境变量格式
        env_vars.insert("host".to_string(), self.host.clone());
        if let Some(container_name) = &self.container_name {
            env_vars.insert("container_name".to_string(), container_name.clone());
        }
        if let Some(app_port) = self.app_port {
            env_vars.insert("app_port".to_string(), app_port.to_string());
        }
        if let Some(workspace) = &self.workspace {
            env_vars.insert(
                "workspace".to_string(),
                workspace.to_string_lossy().to_string(),
            );
        }

        // 保存到 cfg.env 文件
        Self::save_env_file(&env_vars).await
    }

    /// 更新配置
    pub async fn update(&mut self, updates: HashMap<String, String>) -> Result<(), MddeError> {
        for (key, value) in updates {
            match key.as_str() {
                "host" => self.host = value,
                "container_name" => self.container_name = Some(value),
                "app_port" => {
                    self.app_port = Some(
                        value
                            .parse()
                            .map_err(|_| MddeError::InvalidArgument("无效的端口号".to_string()))?,
                    );
                }
                "workspace" => self.workspace = Some(PathBuf::from(value)),
                _ => return Err(MddeError::InvalidArgument(format!("未知配置项: {}", key))),
            }
        }

        self.save().await
    }

    // /// 获取配置文件路径
    // pub fn get_config_path() -> Result<PathBuf, MddeError> {
    //     #[cfg(target_os = "windows")]
    //     {
    //         let app_data = std::env::var("APPDATA")
    //             .map_err(|_| MddeError::Config("无法获取 APPDATA 环境变量".to_string()))?;
    //         Ok(PathBuf::from(app_data).join("mdde").join("config.toml"))
    //     }

    //     #[cfg(not(target_os = "windows"))]
    //     {
    //         let config_dir = dirs::config_dir()
    //             .ok_or_else(|| MddeError::Config("无法获取配置目录".to_string()))?;
    //         Ok(config_dir.join("mdde").join("config.toml"))
    //     }
    // }

    /// 获取环境变量文件路径
    pub fn get_env_file_path() -> Result<PathBuf, MddeError> {
        let path = std::env::current_dir()?.join(".mdde").join("cfg.env");
        Ok(path)
    }

    /// 加载环境变量文件
    pub async fn load_env_file() -> Result<HashMap<String, String>, MddeError> {
        let env_path = Self::get_env_file_path()?;

        if !env_path.exists() {
            return Ok(HashMap::new());
        }

        let content = fs::read_to_string(&env_path).await?;
        let mut env_vars = HashMap::new();

        for line in content.lines() {
            let line = line.trim();
            if !line.is_empty() && !line.starts_with('#') {
                if let Some((key, value)) = line.split_once('=') {
                    env_vars.insert(key.trim().to_string(), value.trim().to_string());
                }
            }
        }

        Ok(env_vars)
    }

    /// 保存环境变量文件
    pub async fn save_env_file(env_vars: &HashMap<String, String>) -> Result<(), MddeError> {
        let env_path = Self::get_env_file_path()?;

        // 确保 .mdde 目录存在
        if let Some(parent) = env_path.parent() {
            fs::create_dir_all(parent).await?;
        }

        let mut content = String::new();
        for (key, value) in env_vars {
            content.push_str(&format!("{}={}\n", key, value));
        }

        fs::write(&env_path, content).await?;

        // 更新 .gitignore 文件
        Self::update_gitignore().await?;

        Ok(())
    }

    /// 更新 .gitignore 文件
    pub async fn update_gitignore() -> Result<(), MddeError> {
        let gitignore_path = std::env::current_dir()?.join(".gitignore");

        // 检查 .gitignore 是否存在
        if !gitignore_path.exists() {
            return Ok(());
        }

        let content = fs::read_to_string(&gitignore_path).await?;

        // 检查是否已经包含 .mdde 目录
        if content.contains(".mdde") {
            return Ok(());
        }

        // 添加 .mdde 目录到 .gitignore
        let mut new_content = content;
        if !new_content.ends_with('\n') {
            new_content.push('\n');
        }
        new_content.push_str("\n# MDDE 配置目录\n.mdde/\n");

        fs::write(&gitignore_path, new_content).await?;

        Ok(())
    }
}

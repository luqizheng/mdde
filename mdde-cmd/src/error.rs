use thiserror::Error;

#[derive(Error, Debug)]
pub enum MddeError {
    #[error("配置错误: {0}")]
    Config(String),

    #[error("HTTP 请求失败: {0}")]
    Http(#[from] reqwest::Error),

    #[error("HTTP 状态错误: {0}")]
    HttpStatus(u16),

    #[error("IO 错误: {0}")]
    Io(#[from] std::io::Error),

    #[error("TOML 解析错误: {0}")]
    Toml(#[from] toml::de::Error),

    #[error("TOML 序列化错误: {0}")]
    TomlSer(#[from] toml::ser::Error),

    #[error("JSON 序列化错误: {0}")]
    Json(#[from] serde_json::Error),

    #[error("YAML 序列化错误: {0}")]
    Yaml(#[from] serde_yaml::Error),

    #[error("Docker 操作失败: {0}")]
    Docker(String),

    #[error("环境不存在: {0}")]
    EnvironmentNotFound(String),

    #[error("无效的参数: {0}")]
    InvalidArgument(String),

    #[error("网络错误: {0}")]
    Network(String),

    #[error("文件操作失败: {0}")]
    FileOperation(String),

    #[error("未知错误: {0}")]
    Unknown(String),
}

impl From<String> for MddeError {
    fn from(err: String) -> Self {
        MddeError::Unknown(err)
    }
}

impl From<&str> for MddeError {
    fn from(err: &str) -> Self {
        MddeError::Unknown(err.to_string())
    }
}

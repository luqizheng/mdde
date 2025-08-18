use mdde::{Config, http::MddeClient, MddeError};

#[tokio::test]
async fn test_config_default() {
    let config = Config::default();
    assert_eq!(config.host, "http://192.168.2.5:3000");
    assert!(config.container_name.is_none());
    assert!(config.app_port.is_none());
    assert!(config.workspace.is_none());
}

#[tokio::test]
async fn test_config_save_and_load() {
    let mut config = Config::default();
    config.host = "http://localhost:3000".to_string();
    
    // 保存配置
    assert!(config.save().await.is_ok());
    
    // 重新加载配置
    let loaded_config = Config::load().await.unwrap();
    assert_eq!(loaded_config.host, "http://localhost:3000");
}

#[tokio::test]
async fn test_mdde_client_creation() {
    let client = MddeClient::new("http://localhost:3000");
    assert_eq!(client.get_base_url(), "http://localhost:3000");
}

#[tokio::test]
async fn test_utils_functions() {
    use mdde::utils;
    
    // 测试端口验证
    assert!(utils::is_valid_port(8080));
    assert!(!utils::is_valid_port(0));
    assert!(!utils::is_valid_port(70000));
    
    // 测试 URL 验证
    assert!(utils::is_valid_url("http://localhost:3000"));
    assert!(utils::is_valid_url("https://example.com"));
    assert!(!utils::is_valid_url("ftp://example.com"));
    
    // 测试文件名清理
    let cleaned = utils::sanitize_filename("test file (1).txt");
    assert_eq!(cleaned, "test_file__1_.txt");
    
    // 测试文件大小格式化
    assert_eq!(utils::format_file_size(1024), "1.0 KB");
    assert_eq!(utils::format_file_size(1048576), "1.0 MB");
}

#[tokio::test]
async fn test_error_conversions() {
    let error = MddeError::InvalidArgument("测试错误".to_string());
    assert_eq!(error.to_string(), "无效的参数: 测试错误");
    
    let string_error: MddeError = "字符串错误".into();
    assert_eq!(string_error.to_string(), "未知错误: 字符串错误");
}

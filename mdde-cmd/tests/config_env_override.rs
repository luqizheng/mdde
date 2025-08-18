use mdde::config::Config;
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use tempfile::tempdir;

#[tokio::test]
async fn test_config_load_with_env_override() {
    // 创建临时目录
    let temp_dir = tempdir().unwrap();
    let current_dir = std::env::current_dir().unwrap();
    
    // 临时切换到测试目录
    std::env::set_current_dir(&temp_dir).unwrap();
    
    // 创建 .mdde.env 文件
    let env_content = "host=http://localhost:8080\n";
    fs::write(".mdde.env", env_content).unwrap();
    
    // 测试配置加载
    let config = Config::load().await.unwrap();
    
    // 验证 host 被 .mdde.env 覆盖
    assert_eq!(config.host, "http://localhost:8080");
    
    // 清理
    fs::remove_file(".mdde.env").unwrap();
    std::env::set_current_dir(current_dir).unwrap();
}

#[tokio::test]
async fn test_config_load_without_env_file() {
    // 确保当前目录没有 .mdde.env 文件
    let env_path = Config::get_env_file_path().unwrap();
    if env_path.exists() {
        fs::remove_file(env_path).unwrap();
    }
    
    // 测试配置加载
    let config = Config::load().await.unwrap();
    
    // 验证使用默认值
    assert_eq!(config.host, "http://192.168.2.5:3000");
}

#[tokio::test]
async fn test_env_file_parsing() {
    let temp_dir = tempdir().unwrap();
    let current_dir = std::env::current_dir().unwrap();
    
    // 临时切换到测试目录
    std::env::set_current_dir(&temp_dir).unwrap();
    
    // 创建包含注释和空行的 .mdde.env 文件
    let env_content = r#"# 这是注释行
host=http://test-server:9000

# 空行应该被忽略
container_name=test-container
debug_port=5000
"#;
    
    fs::write(".mdde.env", env_content).unwrap();
    
    // 测试环境变量文件加载
    let env_vars = Config::load_env_file().await.unwrap();
    
    // 验证解析结果
    assert_eq!(env_vars.get("host"), Some(&"http://test-server:9000".to_string()));
    assert_eq!(env_vars.get("container_name"), Some(&"test-container".to_string()));
    assert_eq!(env_vars.get("debug_port"), Some(&"5000".to_string()));
    
    // 验证注释和空行被忽略
    assert!(!env_vars.contains_key("#"));
    assert!(!env_vars.contains_key(""));
    
    // 清理
    fs::remove_file(".mdde.env").unwrap();
    std::env::set_current_dir(current_dir).unwrap();
}

#[tokio::test]
async fn test_config_save_and_load() {
    let temp_dir = tempdir().unwrap();
    let current_dir = std::env::current_dir().unwrap();
    
    // 临时切换到测试目录
    std::env::set_current_dir(&temp_dir).unwrap();
    
    // 创建测试配置
    let mut test_config = Config::default();
    test_config.host = "http://test-server:9000".to_string();
    test_config.container_name = Some("test-container".to_string());
    test_config.debug_port = Some(5000);
    test_config.workspace = Some(PathBuf::from("./test-workspace"));
    
    // 保存配置
    test_config.save().await.unwrap();
    
    // 验证 .mdde.env 文件被创建
    assert!(Path::new(".mdde.env").exists());
    
    // 重新加载配置
    let loaded_config = Config::load().await.unwrap();
    
    // 验证配置被正确保存和加载
    assert_eq!(loaded_config.host, "http://test-server:9000");
    assert_eq!(loaded_config.container_name, Some("test-container".to_string()));
    assert_eq!(loaded_config.debug_port, Some(5000));
    assert_eq!(loaded_config.workspace, Some(PathBuf::from("./test-workspace")));
    
    // 清理
    fs::remove_file(".mdde.env").unwrap();
    std::env::set_current_dir(current_dir).unwrap();
}

use crate::config::Config;
use crate::error::MddeError;
use colored::*;
use tracing::info;

pub async fn execute(
    set: Option<String>,
    ls: bool,
    del: Option<String>,
    _config: Config,
) -> Result<(), MddeError> {
    // 检查参数冲突
    let operations_count = [set.is_some(), ls, del.is_some()].iter().filter(|&&x| x).count();
    
    if operations_count == 0 {
        return Err(MddeError::InvalidArgument(
            "请指定至少一个操作: --set, --ls, 或 --del".to_string()
        ));
    }
    
    if operations_count > 1 {
        return Err(MddeError::InvalidArgument(
            "只能同时使用一个操作选项".to_string()
        ));
    }

    // 执行相应操作
    if ls {
        list_env_vars().await
    } else if let Some(key_value) = set {
        set_env_var(&key_value).await
    } else if let Some(key) = del {
        delete_env_var(&key).await
    } else {
        Ok(())
    }
}

/// 显示所有环境变量
async fn list_env_vars() -> Result<(), MddeError> {
    info!("显示环境变量配置");

    let env_vars = Config::load_env_file().await?;
    
    if env_vars.is_empty() {
        println!("{}", "环境变量文件为空或不存在".yellow());
        println!("文件位置: .mdde/cfg.env");
        return Ok(());
    }

    println!("{}", "环境变量配置 (.mdde/cfg.env):".cyan());
    println!("{}", "================================".cyan());
    
    // 按键名排序显示
    let mut sorted_vars: Vec<_> = env_vars.iter().collect();
    sorted_vars.sort_by_key(|(key, _)| *key);
    
    for (key, value) in sorted_vars {
        println!("{}={}", key.green(), value);
    }
    
    println!("\n总共 {} 个环境变量", env_vars.len());
    
    Ok(())
}

/// 设置环境变量
async fn set_env_var(key_value: &str) -> Result<(), MddeError> {
    // 解析 key=value 格式
    let (key, value) = parse_key_value(key_value)?;
    
    info!("设置环境变量: {}={}", key, value);

    // 加载现有环境变量
    let mut env_vars = Config::load_env_file().await?;
    
    // 检查是否是更新现有变量
    let is_update = env_vars.contains_key(&key);
    
    // 设置新值
    env_vars.insert(key.clone(), value.clone());
    
    // 保存到文件
    Config::save_env_file(&env_vars).await?;
    
    if is_update {
        println!("{}", "✓ 环境变量已更新".green());
    } else {
        println!("{}", "✓ 环境变量已添加".green());
    }
    println!("{}={}", key.cyan(), value);
    
    Ok(())
}

/// 删除环境变量
async fn delete_env_var(key: &str) -> Result<(), MddeError> {
    info!("删除环境变量: {}", key);

    // 加载现有环境变量
    let mut env_vars = Config::load_env_file().await?;
    
    // 检查变量是否存在
    if !env_vars.contains_key(key) {
        return Err(MddeError::InvalidArgument(format!(
            "环境变量 '{}' 不存在", key
        )));
    }
    
    // 删除变量
    let old_value = env_vars.remove(key).unwrap();
    
    // 保存到文件
    Config::save_env_file(&env_vars).await?;
    
    println!("{}", "✓ 环境变量已删除".green());
    println!("已删除: {}={}", key.cyan(), old_value.strikethrough());
    
    Ok(())
}

/// 解析 key=value 格式
fn parse_key_value(input: &str) -> Result<(String, String), MddeError> {
    let parts: Vec<&str> = input.splitn(2, '=').collect();
    
    if parts.len() != 2 {
        return Err(MddeError::InvalidArgument(format!(
            "无效的格式: '{}'. 应为 key=value 格式，例如: host=http://localhost:3000", 
            input
        )));
    }
    
    let key = parts[0].trim().to_string();
    let value = parts[1].trim().to_string();
    
    if key.is_empty() {
        return Err(MddeError::InvalidArgument(
            "环境变量名不能为空".to_string()
        ));
    }
    
    // 验证环境变量名格式（只允许字母数字和下划线）
    if !key.chars().all(|c| c.is_alphanumeric() || c == '_') {
        return Err(MddeError::InvalidArgument(
            "环境变量名只能包含字母、数字和下划线".to_string()
        ));
    }
    
    Ok((key, value))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_key_value() {
        // 正常情况
        assert_eq!(
            parse_key_value("host=http://localhost:3000").unwrap(),
            ("host".to_string(), "http://localhost:3000".to_string())
        );
        
        // 包含等号的值
        assert_eq!(
            parse_key_value("query=a=b&c=d").unwrap(),
            ("query".to_string(), "a=b&c=d".to_string())
        );
        
        // 空值
        assert_eq!(
            parse_key_value("empty=").unwrap(),
            ("empty".to_string(), "".to_string())
        );
        
        // 错误情况
        assert!(parse_key_value("no_equals").is_err());
        assert!(parse_key_value("=no_key").is_err());
        assert!(parse_key_value("invalid-key=value").is_err());
    }
}

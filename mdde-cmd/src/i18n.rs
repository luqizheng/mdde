use std::collections::HashMap;
use std::env;
use std::sync::{OnceLock, RwLock};

/// 支持的语言类型
#[derive(Debug, Clone, PartialEq)]
pub enum Language {
    English,
    Chinese,
}

impl Language {
    fn from_str(s: &str) -> Self {
        if s.starts_with("zh") || s.starts_with("cn") {
            Language::Chinese
        } else {
            Language::English
        }
    }
}

/// 全局语言设置
static LANGUAGE: RwLock<Option<Language>> = RwLock::new(None);

/// 初始化语言设置
pub fn init_language() {
    let lang = detect_system_language();
    if let Ok(mut language) = LANGUAGE.write() {
        if language.is_none() {
            *language = Some(lang);
        }
    }
}

/// 获取当前语言
pub fn get_language() -> Language {
    if let Ok(language) = LANGUAGE.read() {
        language.clone().unwrap_or(Language::English)
    } else {
        Language::English
    }
}

/// 设置语言
pub fn set_language(lang: Language) {
    if let Ok(mut language) = LANGUAGE.write() {
        *language = Some(lang);
    }
}

/// 检测系统语言
fn detect_system_language() -> Language {
    // 检查 LANG 环境变量
    if let Ok(lang) = env::var("LANG") {
        return Language::from_str(&lang.to_lowercase());
    }

    // 检查 LC_ALL 环境变量
    if let Ok(lang) = env::var("LC_ALL") {
        return Language::from_str(&lang.to_lowercase());
    }

    // 检查 LANGUAGE 环境变量
    if let Ok(lang) = env::var("LANGUAGE") {
        return Language::from_str(&lang.to_lowercase());
    }

    // Windows 系统检查
    #[cfg(target_os = "windows")]
    {
        use std::process::Command;
        if let Ok(output) = Command::new("powershell")
            .args(&["-Command", "Get-Culture | Select-Object -ExpandProperty Name"])
            .output()
        {
            if let Ok(locale) = String::from_utf8(output.stdout) {
                return Language::from_str(&locale.trim().to_lowercase());
            }
        }
    }

    // 默认英文
    Language::English
}

/// 翻译键类型
pub type MessageKey = &'static str;

/// 消息翻译映射
fn get_messages() -> &'static HashMap<MessageKey, (String, String)> {
    static MESSAGES: OnceLock<HashMap<MessageKey, (String, String)>> = OnceLock::new();
    
    MESSAGES.get_or_init(|| {
        let mut messages = HashMap::new();
        
        // 配置相关
        messages.insert("current_config", ("Current config: {:#?}".to_string(), "当前配置: {:#?}".to_string()));
        
        // 清理相关
        messages.insert("clean_all_resources", ("Cleaning all unused Docker resources...".to_string(), "清理所有未使用的 Docker 资源...".to_string()));
        messages.insert("clean_completed", ("✓ Cleanup completed".to_string(), "✓ 清理完成".to_string()));
        messages.insert("clean_images", ("Cleaning unused images...".to_string(), "清理未使用的镜像...".to_string()));
        messages.insert("images_clean_completed", ("✓ Images cleanup completed".to_string(), "✓ 镜像清理完成".to_string()));
        messages.insert("clean_containers", ("Cleaning unused containers...".to_string(), "清理未使用的容器...".to_string()));
        messages.insert("containers_clean_completed", ("✓ Containers cleanup completed".to_string(), "✓ 容器清理完成".to_string()));
        messages.insert("clean_volumes", ("Cleaning unused volumes...".to_string(), "清理未使用的卷...".to_string()));
        messages.insert("volumes_clean_completed", ("✓ Volumes cleanup completed".to_string(), "✓ 卷清理完成".to_string()));
        messages.insert("specify_resource_type", ("Please specify the resource type to clean".to_string(), "请指定要清理的资源类型".to_string()));
        messages.insert("use_all_flag", ("Use --all to clean all resources".to_string(), "使用 --all 清理所有资源".to_string()));
        messages.insert("use_images_flag", ("Use --images to clean images".to_string(), "使用 --images 清理镜像".to_string()));
        messages.insert("use_containers_flag", ("Use --containers to clean containers".to_string(), "使用 --containers 清理容器".to_string()));
        messages.insert("use_volumes_flag", ("Use --volumes to clean volumes".to_string(), "使用 --volumes 清理卷".to_string()));
        
        // 状态相关
        messages.insert("environment_status", ("Development environment status:".to_string(), "开发环境状态:".to_string()));
        
        // 初始化相关
        messages.insert("init_success", ("✓ mdde configuration initialized successfully".to_string(), "✓ mdde 配置初始化成功".to_string()));
        messages.insert("server_address", ("Server address: {}".to_string(), "服务器地址: {}".to_string()));
        messages.insert("env_file_created", ("Environment file created: .mdde/cfg.env".to_string(), "环境变量文件已创建: .mdde/cfg.env".to_string()));
        messages.insert("enter_server_address", ("Please enter MDDE server address:".to_string(), "请输入 MDDE 服务器地址:".to_string()));
        messages.insert("default_address", ("Default address [https://raw.githubusercontent.com/luqizheng/mdde-dockerifle/refs/heads/main]: ".to_string(), "默认地址 [https://raw.githubusercontent.com/luqizheng/mdde-dockerifle/refs/heads/main]: ".to_string()));
        
        // 诊断相关
        messages.insert("system_diagnosis", ("🔍 MDDE System Diagnosis".to_string(), "🔍 MDDE 系统诊断".to_string()));
        messages.insert("diagnosis_completed", ("✓ Diagnosis completed".to_string(), "✓ 诊断完成".to_string()));
        messages.insert("check_docker", ("🐳 Checking Docker...".to_string(), "🐳 检查 Docker...".to_string()));
        messages.insert("docker_installed", ("✓ Docker is installed".to_string(), "✓ Docker 已安装".to_string()));
        messages.insert("docker_version", ("  Version: {}".to_string(), "  版本: {}".to_string()));
        messages.insert("docker_not_installed", ("✗ Docker is not installed or inaccessible".to_string(), "✗ Docker 未安装或无法访问".to_string()));
        messages.insert("install_docker", ("  Please install Docker Desktop or Docker Engine".to_string(), "  请安装 Docker Desktop 或 Docker Engine".to_string()));
        messages.insert("docker_running", ("✓ Docker service is running normally".to_string(), "✓ Docker 服务运行正常".to_string()));
        messages.insert("docker_not_running", ("✗ Docker service is not running".to_string(), "✗ Docker 服务未运行".to_string()));
        messages.insert("start_docker", ("  Please start Docker service".to_string(), "  请启动 Docker 服务".to_string()));
        messages.insert("check_docker_compose", ("📦 Checking Docker Compose...".to_string(), "📦 检查 Docker Compose...".to_string()));
        messages.insert("docker_compose_installed", ("✓ Docker Compose is installed".to_string(), "✓ Docker Compose 已安装".to_string()));
        messages.insert("docker_compose_not_installed", ("✗ Docker Compose is not installed".to_string(), "✗ Docker Compose 未安装".to_string()));
        messages.insert("install_docker_compose", ("  Please install Docker Compose".to_string(), "  请安装 Docker Compose".to_string()));
        messages.insert("check_network", ("🌐 Checking network connection...".to_string(), "🌐 检查网络连接...".to_string()));
        messages.insert("network_ok", ("✓ Network connection is normal".to_string(), "✓ 网络连接正常".to_string()));
        messages.insert("network_server", ("  Server: {}".to_string(), "  服务器: {}".to_string()));
        messages.insert("server_response_error", ("⚠ Server response error".to_string(), "⚠ 服务器响应异常".to_string()));
        messages.insert("status_code", ("  Status code: {}".to_string(), "  状态码: {}".to_string()));
        messages.insert("network_failed", ("✗ Network connection failed".to_string(), "✗ 网络连接失败".to_string()));
        messages.insert("error_msg", ("  Error: {}".to_string(), "  错误: {}".to_string()));
        messages.insert("check_config_files", ("📁 Checking configuration files...".to_string(), "📁 检查配置文件...".to_string()));
        messages.insert("docker_compose_exists", ("✓ docker-compose.yml exists".to_string(), "✓ docker-compose.yml 存在".to_string()));
        messages.insert("docker_compose_not_exists", ("⚠ docker-compose.yml does not exist".to_string(), "⚠ docker-compose.yml 不存在".to_string()));
        messages.insert("current_dir", ("  Current directory: {}".to_string(), "  当前目录: {}".to_string()));
        messages.insert("mdde_env_exists", ("✓ .mdde/cfg.env exists".to_string(), "✓ .mdde/cfg.env 存在".to_string()));
        messages.insert("mdde_env_not_exists", ("⚠ .mdde/cfg.env does not exist".to_string(), "⚠ .mdde/cfg.env 不存在".to_string()));
        
        // 启动相关
        messages.insert("starting_environment", ("Starting development environment...".to_string(), "启动开发环境...".to_string()));
        messages.insert("command", ("Command: {}".to_string(), "命令: {}".to_string()));
        messages.insert("environment_started", ("✓ Development environment started successfully".to_string(), "✓ 开发环境启动成功".to_string()));
        messages.insert("running_in_background", ("Environment is running in background".to_string(), "环境已在后台运行".to_string()));
        messages.insert("view_logs", ("View logs: mdde logs".to_string(), "查看日志: mdde logs".to_string()));
        messages.insert("view_status", ("View status: mdde status".to_string(), "查看状态: mdde status".to_string()));
        
        // 停止相关
        messages.insert("stopping_environment", ("Stopping development environment...".to_string(), "停止开发环境...".to_string()));
        messages.insert("environment_stopped", ("✓ Development environment stopped".to_string(), "✓ 开发环境已停止".to_string()));
        messages.insert("containers_volumes_removed", ("Containers and volumes removed".to_string(), "容器和卷已删除".to_string()));
        
        // 重启相关
        messages.insert("restarting_environment", ("Restarting development environment...".to_string(), "重启开发环境...".to_string()));
        messages.insert("restart_success", ("✓ Development environment restarted successfully".to_string(), "✓ 开发环境重启成功".to_string()));
        messages.insert("environment_name", ("Environment name: {}".to_string(), "环境名称: {}".to_string()));
        
        // 版本相关
        messages.insert("mdde_cli_tool", ("MDDE Command Line Tool".to_string(), "MDDE 命令行工具".to_string()));
        messages.insert("version", ("Version: {}".to_string(), "版本: {}".to_string()));
        messages.insert("author", ("Author: {}".to_string(), "作者: {}".to_string()));
        messages.insert("description", ("Description: {}".to_string(), "描述: {}".to_string()));
        messages.insert("license", ("License: {}".to_string(), "许可证: {}".to_string()));
        messages.insert("repository", ("Repository: {}".to_string(), "仓库: {}".to_string()));
        
        messages
    })
}

/// 获取翻译后的消息
pub fn t(key: MessageKey) -> &'static str {
    let messages = get_messages();
    if let Some((en_msg, zh_msg)) = messages.get(key) {
        match get_language() {
            Language::English => en_msg.as_str(),
            Language::Chinese => zh_msg.as_str(),
        }
    } else {
        key // 如果找不到翻译，返回原始 key
    }
}

/// 格式化翻译消息（支持参数）
pub fn tf(key: MessageKey, args: &[&dyn std::fmt::Display]) -> String {
    let template = t(key);
    let mut result = template.to_string();
    
    // 简单的字符串替换，支持 {} 占位符
    for (i, arg) in args.iter().enumerate() {
        if i == 0 {
            result = result.replace("{}", &arg.to_string());
        } else {
            // 对于多个参数，可以扩展支持 {0}, {1} 等
            result = result.replace(&format!("{{{}}}", i), &arg.to_string());
        }
    }
    
    result
}

/// 宏定义，简化使用
#[macro_export]
macro_rules! tprint {
    ($key:expr) => {
        print!("{}", $crate::i18n::t($key))
    };
    ($key:expr, $($arg:expr),*) => {
        print!("{}", $crate::i18n::tf($key, &[$(&$arg),*]))
    };
}

#[macro_export]
macro_rules! tprintln {
    ($key:expr) => {
        println!("{}", $crate::i18n::t($key))
    };
    ($key:expr, $($arg:expr),*) => {
        println!("{}", $crate::i18n::tf($key, &[$(&$arg),*]))
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_language_detection() {
        // 测试中文检测
        assert_eq!(Language::from_str("zh_CN"), Language::Chinese);
        assert_eq!(Language::from_str("zh_TW"), Language::Chinese);
        assert_eq!(Language::from_str("cn"), Language::Chinese);
        
        // 测试英文检测
        assert_eq!(Language::from_str("en_US"), Language::English);
        assert_eq!(Language::from_str("fr_FR"), Language::English);
    }

    #[test]
    fn test_translation() {
        // 测试中文
        set_language(Language::Chinese);
        assert_eq!(t("clean_completed"), "✓ 清理完成");
        
        // 测试英文
        set_language(Language::English);
        assert_eq!(t("clean_completed"), "✓ Cleanup completed");
        
        // 重置为英文，避免影响其他测试
        set_language(Language::English);
    }

    #[test]
    fn test_formatted_translation() {
        // 确保使用英文
        set_language(Language::English);
        let result = tf("server_address", &[&"http://localhost:3000"]);
        assert_eq!(result, "Server address: http://localhost:3000");
        
        // 测试中文格式化
        set_language(Language::Chinese);
        let result_zh = tf("server_address", &[&"http://localhost:3000"]);
        assert_eq!(result_zh, "服务器地址: http://localhost:3000");
        
        // 重置为英文，避免影响其他测试
        set_language(Language::English);
    }
}

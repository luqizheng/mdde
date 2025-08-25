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
            .args([
                "-Command",
                "Get-Culture | Select-Object -ExpandProperty Name",
            ])
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

        // 创建环境相关
        messages.insert("select_env_type", ("Please select development environment type:".to_string(), "请选择开发环境类型:".to_string()));
        messages.insert("env_list_from_server", ("✓ Environment list retrieved from server".to_string(), "✓ 从服务器获取环境列表".to_string()));
        messages.insert("env_list_failed", ("⚠ Failed to retrieve environment list from server: {}".to_string(), "⚠ 无法从服务器获取环境列表: {}".to_string()));
        messages.insert("using_default_env_list", ("Using default environment list".to_string(), "使用默认环境列表".to_string()));
        messages.insert("no_available_envs", ("No available development environments".to_string(), "没有可用的开发环境".to_string()));
        messages.insert("available_options", ("Available options:".to_string(), "可用选项:".to_string()));
        messages.insert("enter_env_type", ("Please enter development environment type: ".to_string(), "请输入开发环境类型: ".to_string()));
        messages.insert("env_type_empty", ("Development environment type cannot be empty".to_string(), "开发环境类型不能为空".to_string()));
        messages.insert("invalid_env_type", ("Invalid development environment type: '{}'. Please select a valid environment type".to_string(), "无效的开发环境类型: '{}'. 请选择有效的环境类型".to_string()));
        
        messages.insert("downloaded_compose", ("✓ Downloaded docker-compose.yml".to_string(), "✓ 已下载 docker-compose.yml".to_string()));
        messages.insert("downloaded_dockerfile", ("✓ Downloaded Dockerfile".to_string(), "✓ 已下载 Dockerfile".to_string()));
        messages.insert("dockerfile_not_exists", ("ℹ Dockerfile does not exist, using default image".to_string(), "ℹ Dockerfile 不存在，使用默认镜像".to_string()));
        messages.insert("dockerfile_download_failed", ("⚠ Failed to download Dockerfile: {}".to_string(), "⚠ 下载 Dockerfile 失败: {}".to_string()));
        
        messages.insert("env_created_success", ("✓ Development environment created successfully".to_string(), "✓ 开发环境创建成功".to_string()));
        messages.insert("env_name_label", ("Environment name: {}".to_string(), "环境名称: {}".to_string()));
        messages.insert("env_type_label", ("Environment type: {}".to_string(), "环境类型: {}".to_string()));
        messages.insert("workspace_label", ("Workspace: {}".to_string(), "工作目录: {}".to_string()));
        messages.insert("app_port_label", ("Application port: {} (host port:{} -> container port:{})".to_string(), "应用端口: {} (主机端口:{} -> 容器端口:{})".to_string()));
        messages.insert("config_file_label", ("Configuration file: .mdde/docker-compose.yml".to_string(), "配置文件: .mdde/docker-compose.yml".to_string()));
        messages.insert("env_file_label", ("Environment file: .mdde/cfg.env".to_string(), "环境变量文件: .mdde/cfg.env".to_string()));
        messages.insert("custom_image_label", ("Custom image: .mdde/Dockerfile".to_string(), "自定义镜像: .mdde/Dockerfile".to_string()));
        
        messages.insert("next_steps", ("Next steps:".to_string(), "下一步操作:".to_string()));
        messages.insert("start_env_step", ("1. Start environment: mdde start".to_string(), "1. 启动环境: mdde start".to_string()));
        messages.insert("check_status_step", ("2. Check status: mdde status".to_string(), "2. 查看状态: mdde status".to_string()));
        messages.insert("view_logs_step", ("3. View logs: mdde logs".to_string(), "3. 查看日志: mdde logs".to_string()));
        
        messages.insert("enter_env_name", ("Please enter environment name:".to_string(), "请输入环境名称:".to_string()));
        messages.insert("env_name_prompt", ("Environment name (for container identification): ".to_string(), "环境名称 (用于标识容器): ".to_string()));
        messages.insert("env_name_empty", ("Environment name cannot be empty".to_string(), "环境名称不能为空".to_string()));
        messages.insert("env_name_invalid_chars", ("Environment name can only contain letters, numbers, hyphens and underscores".to_string(), "环境名称只能包含字母、数字、连字符和下划线".to_string()));
        
        // 端口验证相关
        messages.insert("port_format_error", ("Application port format error: '{}'. Should be host_port:container_port format, example: 8080:80".to_string(), "应用端口格式错误: '{}'. 应为 host_port:container_port 格式，例如: 8080:80".to_string()));
        messages.insert("invalid_host_port", ("Invalid host port: '{}'. Must be a number between 1-65535".to_string(), "无效的主机端口: '{}'. 必须是 1-65535 之间的数字".to_string()));
        messages.insert("invalid_container_port", ("Invalid container port: '{}'. Must be a number between 1-65535".to_string(), "无效的容器端口: '{}'. 必须是 1-65535 之间的数字".to_string()));
        messages.insert("port_cannot_be_zero", ("Port number cannot be 0".to_string(), "端口号不能为 0".to_string()));
        
        // 默认环境描述
        messages.insert("dotnet9_desc", (".NET 9 Development Environment".to_string(), ".NET 9 开发环境".to_string()));
        messages.insert("dotnet8_desc", (".NET 8 Development Environment".to_string(), ".NET 8 开发环境".to_string()));
        messages.insert("dotnet6_desc", (".NET 6 Development Environment".to_string(), ".NET 6 开发环境".to_string()));
        messages.insert("java21_desc", ("Java 21 Development Environment".to_string(), "Java 21 开发环境".to_string()));
        messages.insert("java18_desc", ("Java 18 Development Environment".to_string(), "Java 18 开发环境".to_string()));
        messages.insert("java11_desc", ("Java 11 Development Environment".to_string(), "Java 11 开发环境".to_string()));
        messages.insert("node22_desc", ("Node.js 22 Development Environment".to_string(), "Node.js 22 开发环境".to_string()));
        messages.insert("node20_desc", ("Node.js 20 Development Environment".to_string(), "Node.js 20 开发环境".to_string()));
        messages.insert("node18_desc", ("Node.js 18 Development Environment".to_string(), "Node.js 18 开发环境".to_string()));
        messages.insert("python312_desc", ("Python 3.12 Development Environment".to_string(), "Python 3.12 开发环境".to_string()));
        messages.insert("python311_desc", ("Python 3.11 Development Environment".to_string(), "Python 3.11 开发环境".to_string()));

        // 环境变量管理相关 (env 命令)
        messages.insert("specify_operation", ("Please specify at least one operation: --set, --ls, or --del".to_string(), "请指定至少一个操作: --set, --ls, 或 --del".to_string()));
        messages.insert("only_one_operation", ("Only one operation option can be used at a time".to_string(), "只能同时使用一个操作选项".to_string()));
        messages.insert("display_env_vars", ("Display environment variable configuration".to_string(), "显示环境变量配置".to_string()));
        messages.insert("env_file_empty", ("Environment variable file is empty or does not exist".to_string(), "环境变量文件为空或不存在".to_string()));
        messages.insert("file_location", ("File location: .mdde/cfg.env".to_string(), "文件位置: .mdde/cfg.env".to_string()));
        messages.insert("env_config_header", ("Environment variable configuration (.mdde/cfg.env):".to_string(), "环境变量配置 (.mdde/cfg.env):".to_string()));
        messages.insert("total_env_vars", ("Total {} environment variables".to_string(), "总共 {} 个环境变量".to_string()));
        messages.insert("set_env_var", ("Set environment variable".to_string(), "设置环境变量".to_string()));
        messages.insert("env_var_updated", ("✓ Environment variable updated".to_string(), "✓ 环境变量已更新".to_string()));
        messages.insert("env_var_added", ("✓ Environment variable added".to_string(), "✓ 环境变量已添加".to_string()));
        messages.insert("delete_env_var", ("Delete environment variable".to_string(), "删除环境变量".to_string()));
        messages.insert("env_var_not_exists", ("Environment variable '{}' does not exist".to_string(), "环境变量 '{}' 不存在".to_string()));
        messages.insert("env_var_deleted", ("✓ Environment variable deleted".to_string(), "✓ 环境变量已删除".to_string()));
        messages.insert("deleted_label", ("Deleted: {}={}".to_string(), "已删除: {}={}".to_string()));
        messages.insert("invalid_format", ("Invalid format: '{}'. Should be key=value format, example: host=http://localhost:3000".to_string(), "无效的格式: '{}'. 应为 key=value 格式，例如: host=http://localhost:3000".to_string()));
        messages.insert("env_var_name_empty", ("Environment variable name cannot be empty".to_string(), "环境变量名不能为空".to_string()));
        messages.insert("env_var_name_chars", ("Environment variable name can only contain letters, numbers and underscores".to_string(), "环境变量名只能包含字母、数字和下划线".to_string()));

        // 交互式执行相关 (exec 命令)
        messages.insert("enter_container_interactive", ("Enter container {} for interactive operation, using shell: {}".to_string(), "进入容器 {} 进行交互式操作，使用 shell: {}".to_string()));
        messages.insert("entering_container", ("Entering container {} for interactive operation...".to_string(), "正在进入容器 {} 进行交互式操作...".to_string()));
        messages.insert("using_shell", ("Using shell: {}".to_string(), "使用 shell: {}".to_string()));
        messages.insert("exit_hint", ("Hint: Enter 'exit' or press Ctrl+D to exit container".to_string(), "提示：输入 'exit' 或按 Ctrl+D 退出容器".to_string()));
        messages.insert("exited_container", ("✓ Exited container".to_string(), "✓ 已退出容器".to_string()));
        messages.insert("enter_container_failed", ("✗ Failed to enter container: {}".to_string(), "✗ 进入容器失败: {}".to_string()));

        // 初始化相关 (init 命令)
        messages.insert("url_must_start_with", ("Server address must start with http:// or https://".to_string(), "服务器地址必须以 http:// 或 https:// 开头".to_string()));
        messages.insert("invalid_url_format", ("Invalid server address format".to_string(), "无效的服务器地址格式".to_string()));

        // 日志查看相关 (logs 命令)
        messages.insert("container_name_not_found", ("Container name not found, please run 'mdde create' to create environment first or use 'mdde env --set container_name=your_name' to set container name".to_string(), "未找到容器名称，请先运行 'mdde create' 创建环境或使用 'mdde env --set container_name=your_name' 设置容器名".to_string()));
        messages.insert("view_container_logs", ("View container logs: {}".to_string(), "查看容器日志: {}".to_string()));
        messages.insert("show_all_logs", ("Showing all logs for container {}...".to_string(), "显示容器 {} 的所有日志...".to_string()));
        messages.insert("show_last_n_logs", ("Showing last {} lines of logs for container {}...".to_string(), "显示容器 {} 的最后 {} 行日志...".to_string()));
        messages.insert("show_last_50_logs", ("Showing last 50 lines of logs for container {}...".to_string(), "显示容器 {} 的最后 50 行日志...".to_string()));
        messages.insert("execute_command_label", ("Execute command: {}".to_string(), "执行命令: {}".to_string()));
        messages.insert("follow_logs_realtime", ("Following logs in real-time (press Ctrl+C to stop)...".to_string(), "实时跟踪日志 (按 Ctrl+C 停止)...".to_string()));
        messages.insert("get_logs_failed", ("Failed to get logs, container '{}' may not exist or not running".to_string(), "获取日志失败，容器 '{}' 可能不存在或未运行".to_string()));
        messages.insert("no_log_output", ("No log output".to_string(), "暂无日志输出".to_string()));
        messages.insert("container_not_running_hint", ("Hint: Container may not be running or has no log output".to_string(), "提示: 容器可能未运行或没有产生日志输出".to_string()));
        messages.insert("container_not_exists", ("Container '{}' does not exist. Please check container name or start container first".to_string(), "容器 '{}' 不存在。请检查容器名称或先启动容器".to_string()));
        messages.insert("get_logs_error", ("Failed to get logs: {}".to_string(), "获取日志失败: {}".to_string()));

        // 运行命令相关 (run 命令)
        messages.insert("provide_command", ("Please provide a command to execute".to_string(), "请提供要执行的命令".to_string()));
        messages.insert("execute_command_in_container", ("Execute command in container {}: {}".to_string(), "在容器 {} 中执行命令: {}".to_string()));
        messages.insert("command_success", ("✓ Command executed successfully".to_string(), "✓ 命令执行成功".to_string()));
        messages.insert("command_failed", ("✗ Command execution failed: {}".to_string(), "✗ 命令执行失败: {}".to_string()));

        // 启动环境相关 (start 命令额外的)
        messages.insert("start_env_name", ("Start development environment: {}".to_string(), "启动开发环境: {}".to_string()));
        messages.insert("start_failed", ("Start failed: {}".to_string(), "启动失败: {}".to_string()));

        // 停止环境相关 (stop 命令)
        messages.insert("stop_env_name", ("Stop development environment: {}".to_string(), "停止开发环境: {}".to_string()));
        messages.insert("docker_compose_not_exists", ("docker-compose.yml file does not exist".to_string(), "docker-compose.yml 文件不存在".to_string()));
        messages.insert("mdde_cfg_env_not_exists", (".mdde/cfg.env file does not exist".to_string(), ".mdde/cfg.env 文件不存在".to_string()));
        messages.insert("stop_failed", ("Stop failed: {}".to_string(), "停止失败: {}".to_string()));

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

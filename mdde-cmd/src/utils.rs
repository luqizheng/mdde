use std::path::Path;

/// 检查文件是否存在
pub fn file_exists(path: &Path) -> bool {
    path.exists() && path.is_file()
}

/// 检查目录是否存在
pub fn dir_exists(path: &Path) -> bool {
    path.exists() && path.is_dir()
}

/// 获取文件扩展名
pub fn get_file_extension(path: &Path) -> Option<String> {
    path.extension()
        .and_then(|ext| ext.to_str())
        .map(|s| s.to_lowercase())
}

/// 检查是否为脚本文件
pub fn is_script_file(path: &Path) -> bool {
    if let Some(ext) = get_file_extension(path) {
        matches!(
            ext.as_str(),
            "ps1" | "sh" | "bat" | "cmd" | "py" | "js" | "ts"
        )
    } else {
        false
    }
}

/// 格式化文件大小
pub fn format_file_size(bytes: u64) -> String {
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;

    match bytes {
        0..KB => format!("{} B", bytes),
        KB..MB => format!("{:.1} KB", bytes as f64 / KB as f64),
        MB..GB => format!("{:.1} MB", bytes as f64 / MB as f64),
        _ => format!("{:.1} GB", bytes as f64 / GB as f64),
    }
}

/// 获取当前时间戳
pub fn get_timestamp() -> u64 {
    use std::time::{SystemTime, UNIX_EPOCH};

    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

/// 检查是否为有效的端口号
pub fn is_valid_port(port: u32) -> bool {
    port > 0 && port < 65536
}

/// 检查是否为有效的 URL
pub fn is_valid_url(url: &str) -> bool {
    url.starts_with("http://") || url.starts_with("https://")
}

/// 清理字符串中的特殊字符
pub fn sanitize_filename(filename: &str) -> String {
    filename
        .chars()
        .map(|c| {
            if c.is_alphanumeric() || c == '.' || c == '_' || c == '-' {
                c
            } else {
                '_'
            }
        })
        .collect()
}

/// 获取操作系统信息
pub fn get_os_info() -> String {
    #[cfg(target_os = "windows")]
    {
        "Windows".to_string()
    }
    #[cfg(target_os = "macos")]
    {
        "macOS".to_string()
    }
    #[cfg(target_os = "linux")]
    {
        "Linux".to_string()
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        "Unknown".to_string()
    }
}

/// 获取架构信息
pub fn get_arch_info() -> String {
    #[cfg(target_arch = "x86_64")]
    {
        "x86_64".to_string()
    }
    #[cfg(target_arch = "aarch64")]
    {
        "aarch64".to_string()
    }
    #[cfg(target_arch = "arm")]
    {
        "arm".to_string()
    }
    #[cfg(not(any(target_arch = "x86_64", target_arch = "aarch64", target_arch = "arm")))]
    {
        "unknown".to_string()
    }
}
pub const DEFAULT_HOST: &str =
    "https://raw.githubusercontent.com/luqizheng/mdde-dockerifle/refs/heads/main";

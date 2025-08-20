//! MDDE 基本使用示例
//!
//! 这个示例展示了如何使用 MDDE 命令行工具的基本功能

use mdde::{http::MddeClient, Config};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🚀 MDDE 基本使用示例");
    println!("{}", "=".repeat(40));

    // 1. 初始化配置
    println!("\n1. 初始化配置...");
    let config = Config::default();
    println!("默认服务器地址: {}", config.host);

    // 2. 创建 HTTP 客户端
    println!("\n2. 创建 HTTP 客户端...");
    let client = MddeClient::new(&config.host);

    // 3. 测试连接
    println!("\n3. 测试服务器连接...");
    match client.ping().await {
        Ok(true) => println!("✓ 服务器连接正常"),
        Ok(false) => println!("⚠ 服务器连接异常"),
        Err(e) => println!("✗ 连接失败: {}", e),
    }

    // 4. 获取脚本列表
    println!("\n4. 获取可用脚本列表...");
    match client.list_scripts(None).await {
        Ok(scripts) => {
            println!("✓ 获取脚本列表成功");
            println!("脚本信息: {}", scripts);
        }
        Err(e) => println!("✗ 获取脚本列表失败: {}", e),
    }

    // 5. 检查特定环境
    println!("\n5. 检查 dotnet9 环境...");
    match client.list_scripts(Some("dotnet9")).await {
        Ok(scripts) => {
            println!("✓ 获取 dotnet9 脚本成功");
            println!("脚本信息: {}", scripts);
        }
        Err(e) => println!("✗ 获取 dotnet9 脚本失败: {}", e),
    }

    println!("\n✅ 示例执行完成");
    Ok(())
}

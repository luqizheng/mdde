use clap::Parser;
use mdde::cli::Cli;
use mdde::config::Config;
use mdde::error::MddeError;
use mdde::i18n;
use tracing::{error, info};

#[tokio::main]
async fn main() -> Result<(), MddeError> {
    // 初始化语言设置
    i18n::init_language();

    // 初始化日志
    tracing_subscriber::fmt::init();

    // 解析命令行参数
    let cli = Cli::parse();

    // 加载配置
    let config = Config::load().await?;
    // 打印 config 数据
    println!(
        "{}",
        i18n::tf("current_config", &[&format!("{:#?}", config)])
    );

    info!("MDDE 命令行工具启动");

    // 执行命令
    if let Err(e) = cli.execute(config).await {
        error!("执行命令失败: {}", e);
        std::process::exit(1);
    }

    Ok(())
}

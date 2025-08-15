use crate::error::MddeError;
use colored::*;

pub async fn execute() -> Result<(), MddeError> {
    println!("{}", "MDDE 命令行工具".blue().bold());
    println!("{}", "=".repeat(30));
    println!("版本: {}", env!("CARGO_PKG_VERSION").green());
    println!("作者: {}", env!("CARGO_PKG_AUTHORS").cyan());
    println!("描述: {}", env!("CARGO_PKG_DESCRIPTION").yellow());
    println!("许可证: {}", env!("CARGO_PKG_LICENSE").magenta());
    println!("仓库: {}", env!("CARGO_PKG_REPOSITORY").blue());
    println!("{}", "=".repeat(30));

    Ok(())
}

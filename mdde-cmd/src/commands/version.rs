use crate::error::MddeError;
use crate::i18n;
use colored::*;

pub async fn execute() -> Result<(), MddeError> {
    println!("{}", i18n::t("mdde_cli_tool").blue().bold());
    println!("{}", "=".repeat(30));
    println!(
        "{}",
        i18n::tf("version", &[&env!("CARGO_PKG_VERSION").green()])
    );
    println!(
        "{}",
        i18n::tf("author", &[&env!("CARGO_PKG_AUTHORS").cyan()])
    );
    println!(
        "{}",
        i18n::tf("description", &[&env!("CARGO_PKG_DESCRIPTION").yellow()])
    );
    println!(
        "{}",
        i18n::tf("license", &[&env!("CARGO_PKG_LICENSE").magenta()])
    );
    println!(
        "{}",
        i18n::tf("repository", &[&env!("CARGO_PKG_REPOSITORY").blue()])
    );
    println!("{}", "=".repeat(30));

    Ok(())
}

use crate::commands::{init, create, start, stop, restart, status, logs, clean, doctor, version};
use crate::config::Config;
use crate::error::MddeError;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "mdde")]
#[command(about = "一个基于 Rust 编写的跨平台命令行工具，用于管理 Docker 多语言开发环境")]
#[command(version)]
pub struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// 初始化 mdde 相关配置
    Init {
        /// mdde 服务器地址
        #[arg(short, long, default_value = "http://192.168.2.5:3000")]
        host: String,
    },

    /// 创建新的开发环境
    Create {
        /// 开发环境类型 (如: dotnet9, java18, java19_tomcat)
        dev_env: String,
        
        /// 环境名称
        #[arg(short, long)]
        name: String,
        
        /// 调试端口
        #[arg(long)]
        debug_port: Option<u16>,
        
        /// 工作目录路径
        #[arg(short, long)]
        workspace: Option<String>,
    },

    /// 启动指定的开发环境
    Start {
        /// 环境名称
        name: String,
        
        /// 后台运行
        #[arg(short, long)]
        detach: bool,
    },

    /// 停止指定的开发环境
    Stop {
        /// 环境名称
        name: String,
        
        /// 停止后删除容器
        #[arg(long)]
        remove: bool,
    },

    /// 重启指定的开发环境
    Restart {
        /// 环境名称
        name: String,
    },

    /// 查看所有开发环境的状态
    Status {
        /// 输出格式
        #[arg(long, value_enum, default_value = "table")]
        format: OutputFormat,
    },

    /// 查看指定环境的日志
    Logs {
        /// 环境名称
        name: String,
        
        /// 实时跟踪日志
        #[arg(short, long)]
        follow: bool,
        
        /// 显示最后 N 行
        #[arg(long)]
        tail: Option<usize>,
        
        /// 显示指定时间后的日志
        #[arg(long)]
        since: Option<String>,
    },

    /// 清理未使用的 Docker 资源
    Clean {
        /// 清理所有未使用的资源
        #[arg(long)]
        all: bool,
        
        /// 清理未使用的镜像
        #[arg(long)]
        images: bool,
        
        /// 清理未使用的容器
        #[arg(long)]
        containers: bool,
        
        /// 清理未使用的卷
        #[arg(long)]
        volumes: bool,
    },

    /// 检查系统环境和配置
    Doctor,

    /// 显示版本信息
    Version,
}

#[derive(Clone, Copy, PartialEq, Eq, clap::ValueEnum)]
pub enum OutputFormat {
    Table,
    Json,
    Yaml,
}

impl Cli {
    pub async fn execute(self, config: Config) -> Result<(), MddeError> {
        match self.command {
            Commands::Init { host } => init::execute(host, config).await,
            Commands::Create { dev_env, name, debug_port, workspace } => {
                create::execute(dev_env, name, debug_port, workspace, config).await
            }
            Commands::Start { name, detach } => start::execute(name, detach, config).await,
            Commands::Stop { name, remove } => stop::execute(name, remove, config).await,
            Commands::Restart { name } => restart::execute(name, config).await,
            Commands::Status { format } => status::execute(format, config).await,
            Commands::Logs { name, follow, tail, since } => {
                logs::execute(name, follow, tail, since, config).await
            }
            Commands::Clean { all, images, containers, volumes } => {
                clean::execute(all, images, containers, volumes, config).await
            }
            Commands::Doctor => doctor::execute(config).await,
            Commands::Version => version::execute().await,
        }
    }
}

use crate::config::Config;
use crate::error::MddeError;
use crate::http::MddeClient;
use crate::i18n;
use colored::*;
use serde::Deserialize;
use std::collections::HashMap;
use std::io::{self, Write};
use std::path::PathBuf;
use tracing::info;

/// 开发环境信息
#[derive(Debug, Deserialize, Clone)]
pub struct DevEnvironment {
    /// 环境名称，如 "node/v22"
    pub name: String,
    /// 环境描述，如 "Node.js 22 开发环境"
    pub description: String,
}

/// 验证应用端口格式是否为 number:number
fn validate_app_port(port_mapping: &str) -> Result<(u16, u16), MddeError> {
    let parts: Vec<&str> = port_mapping.split(':').collect();

    if parts.len() != 2 {
        return Err(MddeError::InvalidPortFormat(
            i18n::tf("port_format_error", &[&port_mapping])
        ));
    }

    let host_port = parts[0].parse::<u16>().map_err(|_| {
        MddeError::InvalidPortFormat(
            i18n::tf("invalid_host_port", &[&parts[0]])
        )
    })?;

    let container_port = parts[1].parse::<u16>().map_err(|_| {
        MddeError::InvalidPortFormat(
            i18n::tf("invalid_container_port", &[&parts[1]])
        )
    })?;

    if host_port == 0 || container_port == 0 {
        return Err(MddeError::InvalidPortFormat(i18n::t("port_cannot_be_zero").to_string()));
    }

    Ok((host_port, container_port))
}

pub async fn execute(
    dev_env: Option<String>,
    name: Option<String>,
    app_port: Option<String>,
    workspace: Option<String>,
    mut config: Config,
) -> Result<(), MddeError> {
    // 获取开发环境类型，如果没有提供则交互式询问
    let dev_env = match dev_env {
        Some(env) => {
            if env.trim().is_empty() {
                get_dev_env_interactively(&config).await?
            } else {
                env
            }
        }
        None => get_dev_env_interactively(&config).await?,
    };

    // 获取环境名称，如果没有提供则交互式询问
    let name = match name {
        Some(n) => {
            if n.trim().is_empty() {
                get_name_interactively()?
            } else {
                n
            }
        }
        None => get_name_interactively()?,
    };

    info!("创建开发环境: {} ({})", name.clone(), dev_env);

    // 验证应用端口格式
    let validated_app_port = if let Some(ref port_str) = app_port {
        let (host_port, container_port) = validate_app_port(port_str)?;
        Some((host_port, container_port, port_str.clone()))
    } else {
        None
    };

    // 确定工作目录
    let workspace_path = workspace
        .map(PathBuf::from)
        .unwrap_or_else(|| std::env::current_dir().unwrap_or_else(|_| PathBuf::from(".")));

    // 创建 HTTP 客户端
    let client = MddeClient::new(&config.host);

    // 确保 .mdde 目录存在
    let mdde_dir = workspace_path.join(".mdde");
    tokio::fs::create_dir_all(&mdde_dir).await?;

    // 下载 docker-compose.yml 文件
    let compose_content = client
        .download_script(&dev_env, "docker-compose.yml")
        .await?;

    // 保存 docker-compose.yml 文件
    let compose_path = mdde_dir.join("docker-compose.yml");
    tokio::fs::write(&compose_path, compose_content).await?;
    println!("{}", i18n::t("downloaded_compose").green());

    // 下载 Dockerfile 文件（如果存在）
    match client.download_script(&dev_env, "Dockerfile").await {
        Ok(dockerfile_content) => {
            let dockerfile_path = mdde_dir.join("Dockerfile");
            tokio::fs::write(&dockerfile_path, dockerfile_content).await?;
            println!("{}", i18n::t("downloaded_dockerfile").green());
        }
        Err(MddeError::HttpStatus(404)) => {
            // Dockerfile 不存在，这是正常情况
            println!("{}", i18n::t("dockerfile_not_exists").yellow());
        }
        Err(e) => {
            // 其他错误，记录但不中断流程
            println!("{}", i18n::tf("dockerfile_download_failed", &[&e]).yellow());
        }
    }

    // 更新环境变量文件
    let mut env_vars = Config::load_env_file().await?;
    env_vars.insert("container_name".to_string(), name.clone());
    if let Some((_, _, port_str)) = &validated_app_port {
        env_vars.insert("app_port".to_string(), port_str.clone());
    }
    env_vars.insert(
        "workspace".to_string(),
        workspace_path.to_string_lossy().to_string(),
    );

    Config::save_env_file(&env_vars).await?;

    // 更新配置
    let mut updates = HashMap::new();
    updates.insert("container_name".to_string(), name.clone());
    if let Some((_, _, port_str)) = &validated_app_port {
        updates.insert("app_port".to_string(), port_str.clone());
    }
    updates.insert(
        "workspace".to_string(),
        workspace_path.to_string_lossy().to_string(),
    );
    config.update(updates).await?;

    println!("{}", i18n::t("env_created_success").green());
    println!("{}", i18n::tf("env_name_label", &[&name]));
    println!("{}", i18n::tf("env_type_label", &[&dev_env]));
    println!("{}", i18n::tf("workspace_label", &[&workspace_path.display()]));
    if let Some((host_port, container_port, port_str)) = &validated_app_port {
        println!("{}", i18n::tf("app_port_label", &[&port_str, &host_port, &container_port]));
    }
    println!("{}", i18n::t("config_file_label"));
    println!("{}", i18n::t("env_file_label"));

    // 检查是否下载了 Dockerfile
    let dockerfile_path = mdde_dir.join("Dockerfile");
    if dockerfile_path.exists() {
        println!("{}", i18n::t("custom_image_label"));
    }

    println!("\n{}", i18n::t("next_steps").yellow());
    println!("{}", i18n::t("start_env_step"));
    println!("{}", i18n::t("check_status_step"));
    println!("{}", i18n::t("view_logs_step"));

    Ok(())
}

/// 交互式获取开发环境类型，从服务器动态获取环境列表
async fn get_dev_env_interactively(config: &Config) -> Result<String, MddeError> {
    println!("{}", i18n::t("select_env_type").cyan());

    // 尝试从服务器获取环境列表
    let client = MddeClient::new(&config.host);
    let environments = match client.get_environments().await {
        Ok(envs) => {
            println!("{}", i18n::t("env_list_from_server").green());
            envs
        }
        Err(e) => {
            println!("{}", i18n::tf("env_list_failed", &[&e]).yellow());
            println!("{}", i18n::t("using_default_env_list").yellow());
            get_default_environments()
        }
    };

    if environments.is_empty() {
        return Err(MddeError::InvalidInput(i18n::t("no_available_envs").to_string()));
    }

    println!("{}", i18n::t("available_options"));
    for env in &environments {
        println!("  - {}    ({})", env.name.cyan(), env.description);
    }

    print!("{}", i18n::t("enter_env_type"));
    io::stdout().flush().map_err(MddeError::Io)?;

    let mut input = String::new();
    io::stdin().read_line(&mut input).map_err(MddeError::Io)?;

    let dev_env = input.trim();

    if dev_env.is_empty() {
        return Err(MddeError::InvalidInput(i18n::t("env_type_empty").to_string()));
    }

    // 验证输入的环境类型是否有效
    let valid_env_names: Vec<&str> = environments.iter().map(|e| e.name.as_str()).collect();

    if !valid_env_names.contains(&dev_env) {
        return Err(MddeError::InvalidInput(
            i18n::tf("invalid_env_type", &[&dev_env])
        ));
    }

    Ok(dev_env.to_string())
}

/// 获取默认的开发环境列表（作为回退选项）
fn get_default_environments() -> Vec<DevEnvironment> {
    vec![
        DevEnvironment {
            name: "dotnet9".to_string(),
            description: i18n::t("dotnet9_desc").to_string(),
        },
        DevEnvironment {
            name: "dotnet8".to_string(),
            description: i18n::t("dotnet8_desc").to_string(),
        },
        DevEnvironment {
            name: "dotnet6".to_string(),
            description: i18n::t("dotnet6_desc").to_string(),
        },
        DevEnvironment {
            name: "java21".to_string(),
            description: i18n::t("java21_desc").to_string(),
        },
        DevEnvironment {
            name: "java18".to_string(),
            description: i18n::t("java18_desc").to_string(),
        },
        DevEnvironment {
            name: "java11".to_string(),
            description: i18n::t("java11_desc").to_string(),
        },
        DevEnvironment {
            name: "node22".to_string(),
            description: i18n::t("node22_desc").to_string(),
        },
        DevEnvironment {
            name: "node20".to_string(),
            description: i18n::t("node20_desc").to_string(),
        },
        DevEnvironment {
            name: "node18".to_string(),
            description: i18n::t("node18_desc").to_string(),
        },
        DevEnvironment {
            name: "python312".to_string(),
            description: i18n::t("python312_desc").to_string(),
        },
        DevEnvironment {
            name: "python311".to_string(),
            description: i18n::t("python311_desc").to_string(),
        },
    ]
}

/// 交互式获取环境名称
fn get_name_interactively() -> Result<String, MddeError> {
    println!("{}", i18n::t("enter_env_name").cyan());
    print!("{}", i18n::t("env_name_prompt"));
    io::stdout().flush().map_err(MddeError::Io)?;

    let mut input = String::new();
    io::stdin().read_line(&mut input).map_err(MddeError::Io)?;

    let name = input.trim();

    if name.is_empty() {
        return Err(MddeError::InvalidInput(i18n::t("env_name_empty").to_string()));
    }

    // 验证名称格式（只允许字母数字和连字符）
    if !name
        .chars()
        .all(|c| c.is_alphanumeric() || c == '-' || c == '_')
    {
        return Err(MddeError::InvalidInput(
            i18n::t("env_name_invalid_chars").to_string(),
        ));
    }

    Ok(name.to_string())
}

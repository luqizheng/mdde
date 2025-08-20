use mdde::docker::{DockerCommand, DockerError};

fn main() -> Result<(), DockerError> {
    println!("🚀 MDDE Docker 命令示例");
    println!("========================\n");

    // 1. 检查Docker是否已安装
    println!("1. 检查Docker安装状态...");
    match DockerCommand::check_installed() {
        Ok(installed) => {
            if installed {
                println!("✅ Docker 已安装");
            } else {
                println!("❌ Docker 未安装");
                return Ok(());
            }
        }
        Err(e) => {
            println!("❌ 检查Docker安装状态失败: {}", e);
            return Ok(());
        }
    }

    // 2. 获取Docker版本
    println!("\n2. 获取Docker版本...");
    match DockerCommand::version() {
        Ok(version) => println!("✅ {}", version.trim()),
        Err(e) => println!("❌ 获取Docker版本失败: {}", e),
    }

    // 3. 获取Docker系统信息
    println!("\n3. 获取Docker系统信息...");
    match DockerCommand::info() {
        Ok(info) => {
            // 只显示前几行信息
            let lines: Vec<&str> = info.lines().take(10).collect();
            println!("✅ Docker系统信息:");
            for line in lines {
                println!("   {}", line);
            }
            if info.lines().count() > 10 {
                println!("   ... (还有更多信息)");
            }
        }
        Err(e) => println!("❌ 获取Docker系统信息失败: {}", e),
    }

    // 4. 列出所有容器
    println!("\n4. 列出所有容器...");
    match DockerCommand::ps_all() {
        Ok(containers) => {
            if containers.trim().is_empty() {
                println!("ℹ️  当前没有容器");
            } else {
                println!("✅ 容器列表:");
                println!("{}", containers);
            }
        }
        Err(e) => println!("❌ 列出容器失败: {}", e),
    }

    // 5. 列出运行中的容器
    println!("\n5. 列出运行中的容器...");
    match DockerCommand::ps_running() {
        Ok(containers) => {
            if containers.trim().is_empty() {
                println!("ℹ️  当前没有运行中的容器");
            } else {
                println!("✅ 运行中的容器:");
                println!("{}", containers);
            }
        }
        Err(e) => println!("❌ 列出运行中容器失败: {}", e),
    }

    // 6. 检查特定容器是否存在
    let test_container = "test_container";
    println!("\n6. 检查容器 '{}' 是否存在...", test_container);
    match DockerCommand::container_exists(test_container) {
        Ok(exists) => {
            if exists {
                println!("✅ 容器 '{}' 存在", test_container);

                // 检查是否正在运行
                match DockerCommand::container_running(test_container) {
                    Ok(running) => {
                        if running {
                            println!("✅ 容器 '{}' 正在运行", test_container);
                        } else {
                            println!("ℹ️  容器 '{}' 已停止", test_container);
                        }
                    }
                    Err(e) => println!("❌ 检查容器运行状态失败: {}", e),
                }
            } else {
                println!("ℹ️  容器 '{}' 不存在", test_container);
            }
        }
        Err(e) => println!("❌ 检查容器存在性失败: {}", e),
    }

    // 7. 演示容器操作（如果存在的话）
    if let Ok(true) = DockerCommand::container_exists(test_container) {
        println!("\n7. 演示容器操作...");

        // 获取容器日志
        println!("   获取容器日志...");
        match DockerCommand::logs(test_container, Some(5)) {
            Ok(logs) => {
                if logs.trim().is_empty() {
                    println!("   ℹ️  容器没有日志");
                } else {
                    println!("   ✅ 容器日志 (最后5行):");
                    for line in logs.lines() {
                        println!("     {}", line);
                    }
                }
            }
            Err(e) => println!("   ❌ 获取容器日志失败: {}", e),
        }

        // 获取容器详细信息
        println!("   获取容器详细信息...");
        match DockerCommand::inspect(test_container) {
            Ok(info) => {
                println!("   ✅ 容器详细信息:");
                // 只显示前几行
                let lines: Vec<&str> = info.lines().take(5).collect();
                for line in lines {
                    println!("     {}", line);
                }
                if info.lines().count() > 5 {
                    println!("     ... (还有更多信息)");
                }
            }
            Err(e) => println!("   ❌ 获取容器详细信息失败: {}", e),
        }
    }

    // 8. 演示镜像操作
    println!("\n8. 演示镜像操作...");

    // 拉取一个简单的测试镜像
    let test_image = "hello-world";
    println!("   拉取测试镜像 '{}'...", test_image);
    match DockerCommand::pull_image(test_image) {
        Ok(result) => println!("   ✅ {}", result),
        Err(e) => println!("   ❌ 拉取镜像失败: {}", e),
    }

    // 9. 演示构建操作（需要Dockerfile）
    println!("\n9. 演示构建操作...");
    println!("   ℹ️  构建操作需要Dockerfile，这里跳过演示");
    println!("   使用方法: DockerCommand::build_image(\"./path\", \"tag\")");

    // 10. 演示运行容器
    println!("\n10. 演示运行容器...");
    println!("    ℹ️  运行容器操作需要镜像，这里跳过演示");
    println!(
        "    使用方法: DockerCommand::run_container(\"image\", \"name\", None, None, None, true)"
    );

    println!("\n🎉 Docker命令示例演示完成！");
    println!("\n可用的Docker命令:");
    println!("  - DockerCommand::check_installed()     - 检查Docker是否安装");
    println!("  - DockerCommand::version()            - 获取Docker版本");
    println!("  - DockerCommand::info()               - 获取Docker系统信息");
    println!("  - DockerCommand::ps_all()             - 列出所有容器");
    println!("  - DockerCommand::ps_running()         - 列出运行中的容器");
    println!("  - DockerCommand::container_exists()   - 检查容器是否存在");
    println!("  - DockerCommand::container_running()  - 检查容器是否运行");
    println!("  - DockerCommand::start_container()    - 启动容器");
    println!("  - DockerCommand::stop_container()     - 停止容器");
    println!("  - DockerCommand::restart_container()  - 重启容器");
    println!("  - DockerCommand::exec_command()       - 在容器中执行命令");
    println!("  - DockerCommand::logs()               - 获取容器日志");
    println!("  - DockerCommand::inspect()            - 获取容器详细信息");
    println!("  - DockerCommand::rm_container()       - 删除容器");
    println!("  - DockerCommand::build_image()        - 构建镜像");
    println!("  - DockerCommand::pull_image()         - 拉取镜像");
    println!("  - DockerCommand::run_container()      - 运行容器");

    Ok(())
}

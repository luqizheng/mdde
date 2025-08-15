#!/bin/bash

# MDDE 默认运行脚本
# 在容器内执行命令

set -e

SCRIPT_NAME="$1"
CONTAINER_NAME="$2"
COMMAND="$3"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "SUCCESS") echo -e "[$timestamp] [SUCCESS] $message" ;;
        "ERROR") echo -e "[$timestamp] [ERROR] $message" ;;
        "WARNING") echo -e "[$timestamp] [WARNING] $message" ;;
        "INFO") echo -e "[$timestamp] [INFO] $message" ;;
        *) echo -e "[$timestamp] [INFO] $message" ;;
    esac
}

# 显示帮助
show_help() {
    echo -e "${CYAN}MDDE 运行脚本使用说明${NC}"
    echo "================================"
    echo ""
    echo "用法:"
    echo "  ./run.sh <script-name> <container-name> <command>"
    echo ""
    echo "参数:"
    echo "  script-name:    脚本名称 (如: dotnet6, java17)"
    echo "  container-name: 容器名称"
    echo "  command:        要执行的命令"
    echo ""
    echo "示例:"
    echo "  ./run.sh dotnet6 oa2 'dotnet build'"
    echo "  ./run.sh java17 workflow_2 'mvn clean install'"
    echo "  ./run.sh python311 ml_project 'python main.py'"
    echo ""
    echo "预定义命令:"
    echo "  build:    构建项目"
    echo "  test:     运行测试"
    echo "  run:      运行项目"
    echo "  clean:    清理项目"
    echo "  install:  安装依赖"
}

# 检查容器状态
check_container_status() {
    local container_name="$1"
    
    if docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
        log "SUCCESS" "容器 $container_name 正在运行"
        return 0
    elif docker ps -a --format "table {{.Names}}" | grep -q "^$container_name$"; then
        log "WARNING" "容器 $container_name 已停止"
        return 1
    else
        log "ERROR" "容器 $container_name 不存在"
        return 1
    fi
}

# 执行预定义命令
execute_predefined_command() {
    local script_name="$1"
    local container_name="$2"
    local command="$3"
    
    case "$command" in
        "build")
            case "$script_name" in
                "dotnet6"|"dotnet9")
                    log "INFO" "执行 .NET 构建命令"
                    docker exec "$container_name" dotnet build
                    ;;
                "java17")
                    log "INFO" "执行 Java 构建命令"
                    docker exec "$container_name" mvn clean compile
                    ;;
                "python311")
                    log "INFO" "执行 Python 构建命令"
                    docker exec "$container_name" python -m pip install -r requirements.txt
                    ;;
                "nodejs18")
                    log "INFO" "执行 Node.js 构建命令"
                    docker exec "$container_name" npm install && npm run build
                    ;;
                *)
                    log "WARNING" "未知的脚本类型: $script_name"
                    ;;
            esac
            ;;
        "test")
            case "$script_name" in
                "dotnet6"|"dotnet9")
                    docker exec "$container_name" dotnet test
                    ;;
                "java17")
                    docker exec "$container_name" mvn test
                    ;;
                "python311")
                    docker exec "$container_name" python -m pytest
                    ;;
                "nodejs18")
                    docker exec "$container_name" npm test
                    ;;
                *)
                    log "WARNING" "未知的脚本类型: $script_name"
                    ;;
            esac
            ;;
        "run")
            case "$script_name" in
                "dotnet6"|"dotnet9")
                    docker exec "$container_name" dotnet run
                    ;;
                "java17")
                    docker exec "$container_name" mvn spring-boot:run
                    ;;
                "python311")
                    docker exec "$container_name" python main.py
                    ;;
                "nodejs18")
                    docker exec "$container_name" npm start
                    ;;
                *)
                    log "WARNING" "未知的脚本类型: $script_name"
                    ;;
            esac
            ;;
        "clean")
            case "$script_name" in
                "dotnet6"|"dotnet9")
                    docker exec "$container_name" dotnet clean
                    ;;
                "java17")
                    docker exec "$container_name" mvn clean
                    ;;
                "python311")
                    docker exec "$container_name" find . -type f -name "*.pyc" -delete
                    docker exec "$container_name" find . -type d -name "__pycache__" -delete
                    ;;
                "nodejs18")
                    docker exec "$container_name" rm -rf node_modules dist
                    ;;
                *)
                    log "WARNING" "未知的脚本类型: $script_name"
                    ;;
            esac
            ;;
        "install")
            case "$script_name" in
                "dotnet6"|"dotnet9")
                    docker exec "$container_name" dotnet restore
                    ;;
                "java17")
                    docker exec "$container_name" mvn dependency:resolve
                    ;;
                "python311")
                    docker exec "$container_name" python -m pip install -r requirements.txt
                    ;;
                "nodejs18")
                    docker exec "$container_name" npm install
                    ;;
                *)
                    log "WARNING" "未知的脚本类型: $script_name"
                    ;;
            esac
            ;;
        *)
            log "INFO" "执行自定义命令: $command"
            docker exec "$container_name" /bin/bash -c "$command"
            ;;
    esac
}

# 主程序
main() {
    # 检查参数
    if [ $# -lt 3 ]; then
        log "ERROR" "参数不足"
        show_help
        exit 1
    fi
    
    local script_name="$1"
    local container_name="$2"
    local command="$3"
    
    log "INFO" "开始执行命令..."
    log "INFO" "脚本名称: $script_name"
    log "INFO" "容器名称: $container_name"
    log "INFO" "执行命令: $command"
    
    # 检查容器状态
    if ! check_container_status "$container_name"; then
        log "ERROR" "容器状态检查失败，请先启动容器"
        exit 1
    fi
    
    # 执行命令
    if execute_predefined_command "$script_name" "$container_name" "$command"; then
        log "SUCCESS" "命令执行成功"
    else
        log "ERROR" "命令执行失败"
        exit 1
    fi
}

# 执行主程序
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

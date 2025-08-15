#!/bin/bash

# MDDE - Multi-Development Docker Environment 管理工具
# 用于创建、管理和部署Docker开发环境的Bash脚本
#
# 作者: MDDE Team
# 版本: 1.0.0
#
# 用法:
#   ./mdde.sh --create <script-name>
#   ./mdde.sh --push <script-name> -f <filename>
#   ./mdde.sh --list
#   ./mdde.sh --status
#   ./mdde.sh --help

set -e  # 遇到错误时退出

# 默认配置
SERVER_URL="http://localhost:3000"
SCRIPT_NAME=""
CONTAINER_NAME=""
FILE_NAME=""
ACTION="help"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "SUCCESS")
            echo -e "[$timestamp] [SUCCESS] $message" >&2
            ;;
        "ERROR")
            echo -e "[$timestamp] [ERROR] $message" >&2
            ;;
        "WARNING")
            echo -e "[$timestamp] [WARNING] $message" >&2
            ;;
        "INFO")
            echo -e "[$timestamp] [INFO] $message" >&2
            ;;
        *)
            echo -e "[$timestamp] [INFO] $message" >&2
            ;;
    esac
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}MDDE - Multi-Development Docker Environment 管理工具${NC}"
    echo "=================================================="
    echo ""
    echo "用法:"
    echo "  ./mdde.sh --create <script-name>"
    echo "  ./mdde.sh --push <script-name> -f <filename>"
    echo "  ./mdde.sh --list"
    echo "  ./mdde.sh --status"
    echo "  ./mdde.sh --help"
    echo ""
    echo "参数说明:"
    echo "  --create, -c    创建Docker开发环境"
    echo "  --push, -p      推送脚本到服务器"
    echo "  --list, -l      列出可用的脚本"
    echo "  --status, -s    显示系统状态"
    echo "  --help, -h      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./mdde.sh --create dotnet6"
    echo "  ./mdde.sh --create java17"
    echo "  ./mdde.sh --push dotnet6 -f my-script.sh"
    echo "  ./mdde.sh --list"
    echo ""
    echo "支持的开发环境:"
    echo "  - dotnet6: .NET 6 开发环境"
    echo "  - dotnet9: .NET 9 开发环境"
    echo "  - java17: Java 17 开发环境"
    echo "  - python311: Python 3.11 开发环境"
    echo "  - nodejs18: Node.js 18 开发环境"
}

# 检查前置条件
check_prerequisites() {
    log "INFO" "检查系统前置条件..."
    
    # 检查Docker
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version 2>/dev/null)
        if [ $? -eq 0 ]; then
            log "SUCCESS" "Docker: $docker_version"
        else
            log "ERROR" "Docker 未安装或未运行"
            return 1
        fi
    else
        log "ERROR" "Docker 未安装"
        return 1
    fi
    
    # 检查网络连接
    if command -v curl &> /dev/null; then
        if curl -s --connect-timeout 5 "$SERVER_URL/health" >/dev/null 2>&1; then
            log "SUCCESS" "MDDE 服务器连接正常"
        else
            log "ERROR" "无法连接到 MDDE 服务器: $SERVER_URL"
            log "WARNING" "请确保服务器正在运行"
            return 1
        fi
    else
        log "ERROR" "curl 未安装"
        return 1
    fi
    
    return 0
}

# 列出可用的脚本
get_script_list() {
    log "INFO" "获取可用的脚本列表..."
    
    if command -v curl &> /dev/null; then
        local response=$(curl -s "$SERVER_URL/list" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$response" ]; then
            # 使用jq解析JSON（如果可用）
            if command -v jq &> /dev/null; then
                local dir_count=$(echo "$response" | jq '.directories | length' 2>/dev/null)
                if [ "$dir_count" -gt 0 ]; then
                    log "INFO" "可用的脚本目录:"
                    echo "$response" | jq -r '.directories[] | "  📁 \(.name) (\(.scripts | length) 个脚本)"' 2>/dev/null
                    echo "$response" | jq -r '.directories[] | "     脚本: \(.scripts | join(", "))"' 2>/dev/null | sed 's/^     脚本: $/     脚本: 无/'
                else
                    log "WARNING" "暂无可用的脚本"
                fi
            else
                log "INFO" "脚本列表获取成功（需要安装jq以获得更好的显示效果）"
                log "INFO" "响应: $response"
            fi
        else
            log "ERROR" "获取脚本列表失败"
        fi
    else
        log "ERROR" "curl 未安装"
    fi
}

# 显示系统状态
show_system_status() {
    log "INFO" "系统状态检查..."
    
    # Docker 状态
    if docker info >/dev/null 2>&1; then
        log "SUCCESS" "Docker 运行正常"
    else
        log "ERROR" "Docker 状态异常"
    fi
    
    # 磁盘空间
    if command -v df &> /dev/null; then
        local disk_info=$(df -h / | tail -1)
        local total=$(echo "$disk_info" | awk '{print $2}')
        local used=$(echo "$disk_info" | awk '{print $3}')
        local available=$(echo "$disk_info" | awk '{print $4}')
        log "INFO" "💾 磁盘空间: $available / $total (已用: $used)"
    fi
    
    # 内存使用
    if command -v free &> /dev/null; then
        local mem_info=$(free -h | grep '^Mem:')
        local total_mem=$(echo "$mem_info" | awk '{print $2}')
        local used_mem=$(echo "$mem_info" | awk '{print $3}')
        local free_mem=$(echo "$mem_info" | awk '{print $4}')
        log "INFO" "🧠 内存使用: $free_mem / $total_mem (已用: $used_mem)"
    fi
    
    # 系统信息
    if [ -f /etc/os-release ]; then
        local os_name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
        local os_version=$(grep '^VERSION=' /etc/os-release | cut -d'"' -f2)
        log "INFO" "🖥️  操作系统: $os_name $os_version"
    fi
}

# 创建开发环境
create_development_environment() {
    local script_name="$1"
    local container_name="$2"
    
    log "INFO" "开始创建开发环境..."
    log "INFO" "脚本名称: $script_name"
    log "INFO" "容器名称: $container_name"
    
    # 验证输入
    if [ -z "$script_name" ] || [ -z "$container_name" ]; then
        log "ERROR" "脚本名称和容器名称不能为空"
        return 1
    fi
    
    # 检查前置条件
    if ! check_prerequisites; then
        log "ERROR" "前置条件检查失败，无法继续"
        return 1
    fi
    
    # 创建项目目录
    local project_dir="$PWD/$container_name"
    if [ -d "$project_dir" ]; then
        log "WARNING" "项目目录已存在: $project_dir"
        read -p "是否覆盖？(y/N): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            log "INFO" "操作已取消"
            return 0
        fi
        rm -rf "$project_dir"
    fi
    
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    log "SUCCESS" "项目目录已创建: $project_dir"
    
    # 下载脚本
    log "INFO" "下载默认脚本..."
    if curl -s -o "default_scripts.zip" "$SERVER_URL/get/default"; then
        unzip -q "default_scripts.zip"
        rm "default_scripts.zip"
        log "SUCCESS" "✅ 默认脚本下载完成"
    else
        log "ERROR" "❌ 默认脚本下载失败"
        return 1
    fi
    
    # 下载特定脚本
    log "INFO" "下载 $script_name 脚本..."
    if curl -s -o "${script_name}_scripts.zip" "$SERVER_URL/get/$script_name"; then
        unzip -q "${script_name}_scripts.zip"
        rm "${script_name}_scripts.zip"
        log "SUCCESS" "✅ $script_name 脚本下载完成"
    else
        log "ERROR" "❌ $script_name 脚本下载失败"
        return 1
    fi
    
    # 执行创建脚本
    local create_script="create.sh"
    if [ -f "$create_script" ]; then
        log "INFO" "执行创建脚本: $create_script"
        if chmod +x "$create_script" && ./"$create_script" "$script_name" "$container_name"; then
            log "SUCCESS" "✅ 开发环境创建完成！"
        else
            log "ERROR" "❌ 创建脚本执行失败"
        fi
    else
        log "WARNING" "未找到创建脚本: $create_script"
        log "INFO" "请手动配置开发环境"
    fi
    
    # 显示后续步骤
    echo ""
    log "SUCCESS" "🎉 开发环境创建完成！"
    log "INFO" "后续步骤:"
    log "INFO" "1. 进入项目目录: cd $container_name"
    log "INFO" "2. 启动容器: ./start.sh"
    log "INFO" "3. 运行命令: ./run.sh <command>"
    log "INFO" "4. 停止容器: ./stop.sh"
}

# 推送脚本到服务器
push_script_to_server() {
    local script_name="$1"
    local file_name="$2"
    
    log "INFO" "推送脚本到服务器..."
    log "INFO" "脚本名称: $script_name"
    log "INFO" "文件名: $file_name"
    
    # 验证输入
    if [ -z "$script_name" ] || [ -z "$file_name" ]; then
        log "ERROR" "脚本名称和文件名不能为空"
        return 1
    fi
    
    # 检查文件是否存在
    if [ ! -f "$file_name" ]; then
        log "ERROR" "文件不存在: $file_name"
        return 1
    fi
    
    # 检查前置条件
    if ! check_prerequisites; then
        log "ERROR" "前置条件检查失败，无法继续"
        return 1
    fi
    
    # 推送文件
    if command -v curl &> /dev/null; then
        if curl -s -X POST -F "script=@$file_name" "$SERVER_URL/upload/$script_name" >/dev/null; then
            log "SUCCESS" "✅ 脚本推送成功！"
        else
            log "ERROR" "❌ 脚本推送失败"
            return 1
        fi
    else
        log "ERROR" "curl 未安装"
        return 1
    fi
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --create|-c)
                ACTION="create"
                SCRIPT_NAME="$2"
                shift 2
                ;;
            --push|-p)
                ACTION="push"
                SCRIPT_NAME="$2"
                shift 2
                ;;
            -f)
                FILE_NAME="$2"
                shift 2
                ;;
            --list|-l)
                ACTION="list"
                shift
                ;;
            --status|-s)
                ACTION="status"
                shift
                ;;
            --help|-h)
                ACTION="help"
                shift
                ;;
            --server|-u)
                SERVER_URL="$2"
                shift 2
                ;;
            *)
                log "ERROR" "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 主程序
main() {
    echo -e "${CYAN}🚀 MDDE - Multi-Development Docker Environment${NC}"
    echo "版本: 1.0.0"
    echo "=================================================="
    
    case "$ACTION" in
        "create")
            if [ -z "$SCRIPT_NAME" ]; then
                read -p "请输入脚本名称 (如: dotnet6, java17): " SCRIPT_NAME
            fi
            if [ -z "$CONTAINER_NAME" ]; then
                read -p "请输入容器名称 (如: oa2, workflow_2): " CONTAINER_NAME
            fi
            create_development_environment "$SCRIPT_NAME" "$CONTAINER_NAME"
            ;;
        "push")
            if [ -z "$SCRIPT_NAME" ]; then
                read -p "请输入目标脚本目录名称: " SCRIPT_NAME
            fi
            if [ -z "$FILE_NAME" ]; then
                read -p "请输入要推送的文件名: " FILE_NAME
            fi
            push_script_to_server "$SCRIPT_NAME" "$FILE_NAME"
            ;;
        "list")
            get_script_list
            ;;
        "status")
            show_system_status
            ;;
        "help")
            show_help
            ;;
        *)
            log "ERROR" "未知操作: $ACTION"
            show_help
            exit 1
            ;;
    esac
}

# 执行主程序
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
    main
fi

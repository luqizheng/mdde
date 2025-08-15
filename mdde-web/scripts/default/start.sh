#!/bin/bash

# MDDE 启动容器脚本

set -e

CONTAINER_NAME="$1"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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
    echo -e "${CYAN}MDDE 启动脚本使用说明${NC}"
    echo "================================"
    echo ""
    echo "用法:"
    echo "  ./start.sh <container-name>"
    echo ""
    echo "参数:"
    echo "  container-name: 容器名称"
    echo ""
    echo "示例:"
    echo "  ./start.sh oa2"
    echo "  ./start.sh workflow_2"
}

# 检查容器状态
check_container_status() {
    local container_name="$1"
    
    if docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
        log "WARNING" "容器 $container_name 已经在运行"
        return 1
    elif docker ps -a --format "table {{.Names}}" | grep -q "^$container_name$"; then
        log "INFO" "容器 $container_name 已存在，正在启动..."
        return 0
    else
        log "ERROR" "容器 $container_name 不存在，请先创建容器"
        return 1
    fi
}

# 启动容器
start_container() {
    local container_name="$1"
    
    log "INFO" "启动容器: $container_name"
    
    if docker start "$container_name"; then
        log "SUCCESS" "容器 $container_name 启动成功"
        
        # 显示容器状态
        log "INFO" "容器状态:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$container_name"
        
        # 显示容器日志（最近10行）
        log "INFO" "容器日志（最近10行）:"
        docker logs --tail 10 "$container_name"
        
    else
        log "ERROR" "容器 $container_name 启动失败"
        return 1
    fi
}

# 主程序
main() {
    # 检查参数
    if [ $# -lt 1 ]; then
        log "ERROR" "参数不足"
        show_help
        exit 1
    fi
    
    local container_name="$1"
    
    log "INFO" "开始启动容器..."
    log "INFO" "容器名称: $container_name"
    
    # 检查容器状态
    if ! check_container_status "$container_name"; then
        exit 1
    fi
    
    # 启动容器
    if start_container "$container_name"; then
        log "SUCCESS" "容器启动完成！"
        log "INFO" "后续步骤:"
        log "INFO" "1. 查看容器状态: docker ps"
        log "INFO" "2. 查看容器日志: docker logs $container_name"
        log "INFO" "3. 进入容器: docker exec -it $container_name /bin/bash"
        log "INFO" "4. 停止容器: ./stop.sh $container_name"
    else
        log "ERROR" "容器启动失败"
        exit 1
    fi
}

# 执行主程序
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

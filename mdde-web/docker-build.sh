#!/bin/bash

# MDDE Web Docker 构建脚本

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认参数
TAG="mdde-web:latest"
NO_CACHE=false

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        -h|--help)
            echo "使用方法: $0 [选项]"
            echo "选项:"
            echo "  -t, --tag TAG     指定镜像标签 (默认: mdde-web:latest)"
            echo "  --no-cache        不使用缓存构建"
            echo "  -h, --help        显示帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 $0 --help 查看帮助"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🐳 开始构建 MDDE Web Docker 镜像...${NC}"

# 构建命令
BUILD_ARGS=("build" "-t" "$TAG")

if [ "$NO_CACHE" = true ]; then
    BUILD_ARGS+=("--no-cache")
fi

BUILD_ARGS+=(".")

# 执行构建
if docker "${BUILD_ARGS[@]}"; then
    echo -e "${GREEN}✅ Docker 镜像构建成功!${NC}"
    echo -e "${CYAN}📦 镜像标签: $TAG${NC}"
    
    # 显示镜像信息
    echo -e "\n${YELLOW}📋 镜像信息:${NC}"
    docker images "$TAG"
    
    echo -e "\n${YELLOW}🚀 运行容器命令:${NC}"
    echo -e "${CYAN}docker run -d -p 3000:3000 --name mdde-web-container $TAG${NC}"
else
    echo -e "${RED}❌ Docker 镜像构建失败!${NC}"
    exit 1
fi

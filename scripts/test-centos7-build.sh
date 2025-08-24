#!/bin/bash
# CentOS 7 兼容性构建测试脚本
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_IMAGE="mdde-centos7-builder"
TEST_CONTAINER="mdde-centos7-test"

echo -e "${BLUE}🧪 MDDE CentOS 7 兼容性构建测试${NC}"
echo "项目目录: ${PROJECT_DIR}"

# 检查 Docker 可用性
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装或不在 PATH 中${NC}"
    exit 1
fi

# 清理可能存在的容器
echo -e "${YELLOW}🧹 清理之前的测试环境...${NC}"
docker rm -f "${TEST_CONTAINER}" 2>/dev/null || true
docker rmi -f "${BUILD_IMAGE}" 2>/dev/null || true

# 构建 Docker 镜像
echo -e "${YELLOW}🔨 构建 CentOS 7 构建镜像...${NC}"
cd "${PROJECT_DIR}"
if ! docker build -f docker/centos7.Dockerfile -t "${BUILD_IMAGE}" .; then
    echo -e "${RED}❌ Docker 镜像构建失败${NC}"
    exit 1
fi

# 运行构建测试
echo -e "${YELLOW}🏗️ 开始 CentOS 7 兼容构建...${NC}"
if ! docker run --name "${TEST_CONTAINER}" -v "${PROJECT_DIR}:/workspace" "${BUILD_IMAGE}"; then
    echo -e "${RED}❌ 构建过程失败${NC}"
    docker logs "${TEST_CONTAINER}" 2>/dev/null || true
    exit 1
fi

# 验证构建产物
echo -e "${YELLOW}✅ 验证构建产物...${NC}"
BUILD_PATH="${PROJECT_DIR}/mdde-cmd/target/x86_64-unknown-linux-gnu/release/mdde"

if [ ! -f "${BUILD_PATH}" ]; then
    echo -e "${RED}❌ 构建产物不存在: ${BUILD_PATH}${NC}"
    exit 1
fi

echo "✅ 构建产物存在: ${BUILD_PATH}"
ls -lh "${BUILD_PATH}"

# 在 CentOS 7 环境中测试运行
echo -e "${YELLOW}🧪 在 CentOS 7 环境中测试运行...${NC}"
docker run --rm \
    -v "${BUILD_PATH}:/usr/local/bin/mdde:ro" \
    centos:7 \
    bash -c '
        echo "=== CentOS 7 运行环境测试 ==="
        cat /etc/centos-release
        echo
        
        echo "=== OpenSSL 版本 ==="
        openssl version
        echo
        
        echo "=== 测试 mdde 版本命令 ==="
        if /usr/local/bin/mdde --version; then
            echo "✅ 版本命令执行成功"
        else
            echo "❌ 版本命令执行失败"
            exit 1
        fi
        echo
        
        echo "=== 检查动态库依赖 ==="
        ldd /usr/local/bin/mdde || echo "静态链接或无动态依赖"
        echo
        
        echo "=== 测试 help 命令 ==="
        if /usr/local/bin/mdde --help > /dev/null; then
            echo "✅ 帮助命令执行成功"
        else
            echo "❌ 帮助命令执行失败" 
            exit 1
        fi
        
        echo "🎉 所有测试通过！"
    '

if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 CentOS 7 兼容性测试全部通过！${NC}"
    echo
    echo "构建产物位置: ${BUILD_PATH}"
    echo "可以使用以下命令验证:"
    echo "  file ${BUILD_PATH}"
    echo "  ldd ${BUILD_PATH}"
else
    echo -e "${RED}❌ CentOS 7 兼容性测试失败${NC}"
    exit 1
fi

# 清理测试环境
echo -e "${YELLOW}🧹 清理测试环境...${NC}"
docker rm -f "${TEST_CONTAINER}" 2>/dev/null || true
docker rmi -f "${BUILD_IMAGE}" 2>/dev/null || true

echo -e "${GREEN}✅ 测试完成${NC}"

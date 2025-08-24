#!/bin/bash
# CentOS 7 构建脚本
set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐋 开始 CentOS 7 兼容构建...${NC}"

# 检查环境
echo -e "${YELLOW}📋 环境检查:${NC}"
echo "- CentOS 版本: $(cat /etc/centos-release)"
echo "- OpenSSL 版本: $(openssl version)"
echo "- Rust 版本: $(rustc --version)"
echo "- Cargo 版本: $(cargo --version)"

# 检查源码目录
if [ ! -d "mdde-cmd" ]; then
    echo -e "${RED}❌ 错误: 未找到 mdde-cmd 目录！${NC}"
    exit 1
fi

# 进入项目目录
cd mdde-cmd

# 安装构建目标
echo -e "${YELLOW}🎯 安装 Rust 构建目标...${NC}"
rustup target add x86_64-unknown-linux-gnu

# 验证依赖库
echo -e "${YELLOW}📦 验证系统依赖库...${NC}"
if ! pkg-config --exists openssl; then
    echo -e "${RED}❌ OpenSSL 开发库未安装${NC}"
    exit 1
fi

echo "- OpenSSL 版本: $(pkg-config --modversion openssl)"
echo "- OpenSSL 库路径: $(pkg-config --variable=libdir openssl)"
echo "- OpenSSL 头文件路径: $(pkg-config --variable=includedir openssl)"

# 设置构建环境变量
export PKG_CONFIG_ALLOW_CROSS=1
export OPENSSL_DIR=/usr
export OPENSSL_LIB_DIR=/usr/lib64
export OPENSSL_INCLUDE_DIR=/usr/include
export OPENSSL_STATIC=0

# 构建项目
echo -e "${YELLOW}🔨 开始构建 MDDE (CentOS 7 兼容版本)...${NC}"
cargo build --release --target x86_64-unknown-linux-gnu --features centos7-compat --verbose

# 验证构建结果
if [ -f "target/x86_64-unknown-linux-gnu/release/mdde" ]; then
    echo -e "${GREEN}✅ 构建成功！${NC}"
    
    # 显示二进制文件信息
    echo -e "${YELLOW}📊 构建产物信息:${NC}"
    ls -lh target/x86_64-unknown-linux-gnu/release/mdde
    file target/x86_64-unknown-linux-gnu/release/mdde
    
    # 检查动态库依赖
    echo -e "${YELLOW}🔗 动态库依赖:${NC}"
    ldd target/x86_64-unknown-linux-gnu/release/mdde || echo "静态链接或无动态依赖"
    
    # 运行简单测试
    echo -e "${YELLOW}🧪 运行基本测试:${NC}"
    if target/x86_64-unknown-linux-gnu/release/mdde --version; then
        echo -e "${GREEN}✅ 版本命令测试通过${NC}"
    else
        echo -e "${RED}❌ 版本命令测试失败${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}🎉 CentOS 7 兼容版本构建完成！${NC}"
else
    echo -e "${RED}❌ 构建失败！未找到构建产物${NC}"
    exit 1
fi

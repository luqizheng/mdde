#!/bin/bash

# MDDE 包生成器统一入口
# 自动检测操作系统并调用合适的构建脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 显示横幅
echo -e "${BLUE}"
echo "╔════════════════════════════════════╗"
echo "║       MDDE 包生成器入口            ║"
echo "║     Package Generator Entry        ║"
echo "╚════════════════════════════════════╝"
echo -e "${NC}"

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "Linux";;
        Darwin*)    echo "macOS";;
        CYGWIN*)    echo "Windows";;
        MINGW*)     echo "Windows";;
        *)          echo "Unknown";;
    esac
}

OS=$(detect_os)
echo -e "${BLUE}[INFO]${NC} 检测到操作系统: $OS"

# 根据操作系统选择构建脚本
case $OS in
    "Linux"|"macOS")
        if [[ -f "package.sh" ]]; then
            echo -e "${GREEN}[INFO]${NC} 使用 package.sh 进行构建..."
            chmod +x package.sh
            ./package.sh "$@"
        elif [[ -f "build.sh" ]]; then
            echo -e "${GREEN}[INFO]${NC} 使用 build.sh 进行构建..."
            chmod +x build.sh
            ./build.sh "$@"
        else
            echo -e "${RED}[ERROR]${NC} 未找到构建脚本"
            exit 1
        fi
        ;;
    "Windows")
        if [[ -f "build.ps1" ]]; then
            echo -e "${GREEN}[INFO]${NC} 使用 PowerShell 脚本进行构建..."
            powershell.exe -ExecutionPolicy Bypass -File build.ps1 "$@"
        else
            echo -e "${RED}[ERROR]${NC} 未找到 PowerShell 构建脚本"
            exit 1
        fi
        ;;
    *)
        echo -e "${YELLOW}[WARNING]${NC} 未知操作系统，尝试使用默认脚本..."
        if [[ -f "package.sh" ]]; then
            chmod +x package.sh
            ./package.sh "$@"
        else
            echo -e "${RED}[ERROR]${NC} 无法确定合适的构建脚本"
            exit 1
        fi
        ;;
esac

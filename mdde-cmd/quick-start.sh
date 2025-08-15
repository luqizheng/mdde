#!/bin/bash

# MDDE 快速启动脚本
# 自动安装依赖、构建项目并运行

set -e

echo "🚀 MDDE 快速启动脚本"
echo "===================="

# 检查操作系统
OS=$(uname -s)
case "$OS" in
    Linux*)     PLATFORM="linux" ;;
    Darwin*)    PLATFORM="macos" ;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
    *)          PLATFORM="unknown" ;;
esac

echo "检测到操作系统: $PLATFORM"

# 检查 Rust 是否安装
if ! command -v rustc &> /dev/null; then
    echo "📦 安装 Rust..."
    case "$PLATFORM" in
        "windows")
            echo "请访问 https://rustup.rs/ 下载并安装 Rust"
            exit 1
            ;;
        *)
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source ~/.cargo/env
            ;;
    esac
else
    echo "✓ Rust 已安装: $(rustc --version)"
fi

# 检查 Cargo 是否可用
if ! command -v cargo &> /dev/null; then
    echo "✗ Cargo 不可用，请重新安装 Rust"
    exit 1
fi

echo "✓ Cargo 已安装: $(cargo --version)"

# 安装必要的工具
echo "🔧 安装开发工具..."
rustup component add rustfmt
rustup component add clippy

# 检查依赖
echo "📋 检查项目依赖..."
cargo check

# 运行测试
echo "🧪 运行测试..."
cargo test

# 构建项目
echo "🔨 构建项目..."
cargo build --release

# 检查构建结果
BINARY_PATH="target/release/mdde"
if [ -f "$BINARY_PATH" ]; then
    echo "✅ 构建成功!"
    echo "二进制文件: $BINARY_PATH"
    
    # 设置执行权限
    chmod +x "$BINARY_PATH"
    
    # 显示帮助信息
    echo ""
    echo "🎉 MDDE 已准备就绪!"
    echo "运行以下命令查看帮助:"
    echo "  ./$BINARY_PATH --help"
    echo ""
    echo "快速开始:"
    echo "  1. 初始化配置: ./$BINARY_PATH init"
    echo "  2. 创建环境: ./$BINARY_PATH create dotnet9 --name my-app"
    echo "  3. 启动环境: ./$BINARY_PATH start my-app"
    echo ""
    echo "或者安装到系统:"
    echo "  cargo install --path ."
else
    echo "✗ 构建失败"
    exit 1
fi



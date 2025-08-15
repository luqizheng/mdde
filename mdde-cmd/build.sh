#!/bin/bash

# MDDE 构建脚本
# 用于在 Linux/macOS 环境下构建 Rust 项目

set -e

echo "🚀 开始构建 MDDE 命令行工具..."

# 检查 Rust 是否安装
if ! command -v rustc &> /dev/null; then
    echo "✗ Rust 未安装，请先安装 Rust"
    echo "访问 https://rustup.rs/ 安装 Rust"
    exit 1
fi

if ! command -v cargo &> /dev/null; then
    echo "✗ Cargo 不可用"
    exit 1
fi

# 显示版本信息
echo "✓ Rust 已安装: $(rustc --version)"
echo "✓ Cargo 已安装: $(cargo --version)"

# 清理之前的构建
echo "🧹 清理之前的构建..."
cargo clean

# 检查依赖
echo "📦 检查项目依赖..."
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
    FILE_SIZE=$(stat -f%z "$BINARY_PATH" 2>/dev/null || stat -c%s "$BINARY_PATH" 2>/dev/null || echo "0")
    FILE_SIZE_KB=$(echo "scale=2; $FILE_SIZE / 1024" | bc 2>/dev/null || echo "0")
    
    echo "✅ 构建成功!"
    echo "二进制文件: $BINARY_PATH"
    echo "文件大小: ${FILE_SIZE_KB} KB"
    
    # 显示版本信息
    echo "📋 版本信息:"
    "$BINARY_PATH" --version
    
    # 设置执行权限
    chmod +x "$BINARY_PATH"
    echo "✓ 已设置执行权限"
else
    echo "✗ 构建失败：找不到二进制文件"
    exit 1
fi

echo "🎉 构建完成!"

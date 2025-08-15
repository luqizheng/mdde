#!/bin/bash

echo "🚀 启动 MDDE Web 服务器..."
echo

# 检查Node.js是否安装
if ! command -v node &> /dev/null; then
    echo "❌ 未找到 Node.js，请先安装 Node.js"
    echo "下载地址: https://nodejs.org/"
    exit 1
fi

# 检查npm是否可用
if ! command -v npm &> /dev/null; then
    echo "❌ npm 不可用"
    exit 1
fi

# 显示版本信息
echo "✅ Node.js 版本: $(node --version)"
echo "✅ npm 版本: $(npm --version)"
echo

# 检查依赖是否已安装
if [ ! -d "node_modules" ]; then
    echo "📦 安装依赖..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ 依赖安装失败"
        exit 1
    fi
    echo "✅ 依赖安装完成"
    echo
fi

# 启动服务器
echo "🌐 启动 Web 服务器..."
echo "📁 脚本目录: $(pwd)/scripts"
echo "🌐 访问地址: http://localhost:3000"
echo "🔧 管理界面: http://localhost:3000/admin.html"
echo
echo "按 Ctrl+C 停止服务器"
echo

npm start

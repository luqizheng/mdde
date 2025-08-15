#!/usr/bin/env pwsh

Write-Host "🚀 启动 MDDE Web 服务器..." -ForegroundColor Green

# 检查Node.js是否安装
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js 版本: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ 未找到 Node.js，请先安装 Node.js" -ForegroundColor Red
    Write-Host "下载地址: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# 检查npm是否可用
try {
    $npmVersion = npm --version
    Write-Host "✅ npm 版本: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm 不可用" -ForegroundColor Red
    exit 1
}

# 检查依赖是否已安装
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 安装依赖..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 依赖安装失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ 依赖安装完成" -ForegroundColor Green
}

# 启动服务器
Write-Host "🌐 启动 Web 服务器..." -ForegroundColor Yellow
Write-Host "📁 脚本目录: $PWD\scripts" -ForegroundColor Cyan
Write-Host "🌐 访问地址: http://localhost:3000" -ForegroundColor Cyan
Write-Host "🔧 管理界面: http://localhost:3000/admin.html" -ForegroundColor Cyan
Write-Host "按 Ctrl+C 停止服务器" -ForegroundColor Yellow
Write-Host ""

npm start

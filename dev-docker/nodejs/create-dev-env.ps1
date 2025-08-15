#!/usr/bin/env pwsh

Write-Host "=== Node.js 开发环境创建向导 ===" -ForegroundColor Green

# 获取源码路径
$sourceCodePath = Read-Host "请输入源码目录路径 (例如: C:\projects\myapp)"
if (-not (Test-Path $sourceCodePath)) {
    Write-Host "错误: 源码目录不存在!" -ForegroundColor Red
    exit 1
}

# 获取容器名称
$containerName = Read-Host "请输入容器名称 (默认: nodejs-dev)"
if ([string]::IsNullOrEmpty($containerName)) {
    $containerName = "nodejs-dev"
}

# 获取应用端口
$appPort = Read-Host "请输入应用端口 (默认: 3000)"
if ([string]::IsNullOrEmpty($appPort)) {
    $appPort = "3000"
}

# 创建环境变量文件
$envContent = @"
# Node.js 开发环境配置
SOURCE_CODE_PATH=$sourceCodePath
CONTAINER_NAME=$containerName
APP_PORT=$appPort
"@

$envContent | Out-File -FilePath ".dev.env" -Encoding UTF8

Write-Host "环境配置文件已创建: .dev.env" -ForegroundColor Green

# 启动开发环境
Write-Host "正在启动 Node.js 开发环境..." -ForegroundColor Yellow
docker-compose --env-file .dev.env up -d

Write-Host "开发环境启动完成!" -ForegroundColor Green
Write-Host "容器名称: $containerName" -ForegroundColor Cyan
Write-Host "源码路径: $sourceCodePath" -ForegroundColor Cyan
Write-Host "应用端口: $appPort" -ForegroundColor Cyan
Write-Host ""
Write-Host "使用方法:" -ForegroundColor Yellow
Write-Host "  .\run-cmd.ps1 npm install" -ForegroundColor Cyan
Write-Host "  .\run-cmd.ps1 npm run dev" -ForegroundColor Cyan
Write-Host "  .\run-cmd.ps1 npm run build" -ForegroundColor Cyan
Write-Host "  .\run-cmd.ps1 yarn install" -ForegroundColor Cyan

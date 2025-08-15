#!/usr/bin/env pwsh

Write-Host "=== Docker 开发环境设置脚本 ===" -ForegroundColor Green

# 检查PowerShell执行策略
$currentPolicy = Get-ExecutionPolicy
Write-Host "当前PowerShell执行策略: $currentPolicy" -ForegroundColor Cyan

if ($currentPolicy -eq "Restricted") {
    Write-Host "检测到执行策略受限，需要设置执行策略..." -ForegroundColor Yellow
    
    $response = Read-Host "是否设置执行策略为 RemoteSigned? (y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "执行策略已设置为 RemoteSigned" -ForegroundColor Green
        }
        catch {
            Write-Host "设置执行策略失败: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "请以管理员身份运行PowerShell并手动设置执行策略" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "跳过执行策略设置，但脚本可能无法正常运行" -ForegroundColor Yellow
    }
}
else {
    Write-Host "执行策略已正确设置，无需修改" -ForegroundColor Green
}

# 检查Docker
Write-Host "检查Docker状态..." -ForegroundColor Cyan
try {
    $dockerVersion = docker --version
    Write-Host "Docker版本: $dockerVersion" -ForegroundColor Green
    
    $dockerStatus = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker运行正常" -ForegroundColor Green
    }
    else {
        Write-Host "Docker未运行，请启动Docker Desktop" -ForegroundColor Red
    }
}
catch {
    Write-Host "Docker未安装或不在PATH中" -ForegroundColor Red
    Write-Host "请安装Docker Desktop并确保其在PATH中" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "设置完成!" -ForegroundColor Green
Write-Host "现在可以开始使用Docker开发环境了" -ForegroundColor Cyan
Write-Host ""
Write-Host "使用步骤:" -ForegroundColor Yellow
Write-Host "1. 进入对应语言目录 (如: cd dotnet)" -ForegroundColor Cyan
Write-Host "2. 运行环境创建脚本: .\create-dev-env.ps1" -ForegroundColor Cyan
Write-Host "3. 使用命令执行脚本: .\run-cmd.ps1 <命令>" -ForegroundColor Cyan

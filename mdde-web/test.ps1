#!/usr/bin/env pwsh

Write-Host "🧪 MDDE Web 服务器功能测试" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan

# 设置基础URL
$baseUrl = "http://localhost:3000"

# 测试函数
function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$Description
    )
    
    Write-Host "测试: $Description" -ForegroundColor Yellow
    Write-Host "  $Method $Endpoint" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl$Endpoint" -Method $Method -ErrorAction Stop
        Write-Host "  ✅ 成功" -ForegroundColor Green
        if ($response) {
            Write-Host "  响应: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ❌ 失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# 等待服务器启动
Write-Host "等待服务器启动..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# 测试基础脚本下载
Write-Host "1. 测试基础脚本下载" -ForegroundColor Magenta
Test-Endpoint -Method "GET" -Endpoint "/download/env-build.ps1" -Description "下载 PowerShell 脚本"
Test-Endpoint -Method "GET" -Endpoint "/download/env-build.sh" -Description "下载 Bash 脚本"

# 测试脚本列表
Write-Host "2. 测试脚本列表" -ForegroundColor Magenta
Test-Endpoint -Method "GET" -Endpoint "/list" -Description "获取所有脚本目录"
Test-Endpoint -Method "GET" -Endpoint "/list/dotnet9" -Description "获取 dotnet9 目录脚本"

# 测试脚本下载
Write-Host "3. 测试脚本下载" -ForegroundColor Magenta
Test-Endpoint -Method "GET" -Endpoint "/get/dotnet9" -Description "下载 dotnet9 目录脚本"

# 测试脚本上传（模拟）
Write-Host "4. 测试脚本上传" -ForegroundColor Magenta
Write-Host "  注意: 上传测试需要手动在管理界面进行" -ForegroundColor Yellow
Write-Host "  管理界面: $baseUrl/admin.html" -ForegroundColor Cyan

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "测试完成！" -ForegroundColor Green
Write-Host "访问管理界面: $baseUrl/admin.html" -ForegroundColor Cyan
Write-Host "访问主页: $baseUrl" -ForegroundColor Cyan

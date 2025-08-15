#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status", "logs", "clean")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$Language = "all"
)

# 定义支持的语言
$Languages = @("dotnet", "java", "nodejs", "python")

# 检查语言参数
if ($Language -ne "all" -and $Language -notin $Languages) {
    Write-Host "错误: 不支持的语言 '$Language'" -ForegroundColor Red
    Write-Host "支持的语言: $($Languages -join ', ')" -ForegroundColor Yellow
    exit 1
}

# 获取目标语言目录
$targetLanguages = if ($Language -eq "all") { $Languages } else { @($Language) }

foreach ($lang in $targetLanguages) {
    $langPath = "./$lang"
    if (-not (Test-Path $langPath)) {
        Write-Host "警告: 语言目录 '$lang' 不存在，跳过" -ForegroundColor Yellow
        continue
    }
    
    $envFile = Join-Path $langPath ".dev.env"
    if (-not (Test-Path $envFile)) {
        Write-Host "警告: 语言 '$lang' 未配置开发环境，跳过" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "处理语言: $lang" -ForegroundColor Green
    
    switch ($Action) {
        "start" {
            Write-Host "启动 $lang 开发环境..." -ForegroundColor Yellow
            Set-Location $langPath
            docker-compose --env-file .dev.env up -d
            Set-Location ..
        }
        "stop" {
            Write-Host "停止 $lang 开发环境..." -ForegroundColor Yellow
            Set-Location $langPath
            docker-compose --env-file .dev.env down
            Set-Location ..
        }
        "restart" {
            Write-Host "重启 $lang 开发环境..." -ForegroundColor Yellow
            Set-Location $langPath
            docker-compose --env-file .dev.env restart
            Set-Location ..
        }
        "status" {
            Write-Host "检查 $lang 开发环境状态..." -ForegroundColor Yellow
            Set-Location $langPath
            docker-compose --env-file .dev.env ps
            Set-Location ..
        }
        "logs" {
            Write-Host "查看 $lang 开发环境日志..." -ForegroundColor Yellow
            Set-Location $langPath
            docker-compose --env-file .dev.env logs -f
            Set-Location ..
        }
        "clean" {
            Write-Host "清理 $lang 开发环境..." -ForegroundColor Yellow
            Set-Location $langPath
            docker-compose --env-file .dev.env down -v --remove-orphans
            Set-Location ..
        }
    }
}

Write-Host "操作完成!" -ForegroundColor Green

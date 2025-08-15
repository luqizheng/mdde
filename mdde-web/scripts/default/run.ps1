#!/usr/bin/env pwsh

<#
.SYNOPSIS
    MDDE 默认运行脚本 (PowerShell版本)

.DESCRIPTION
    在容器内执行命令的PowerShell脚本

.PARAMETER ScriptName
    脚本名称，如 dotnet6, java17

.PARAMETER ContainerName
    容器名称

.PARAMETER Command
    要执行的命令

.EXAMPLE
    .\run.ps1 -ScriptName dotnet6 -ContainerName oa2 -Command "dotnet build"
    .\run.ps1 -ScriptName java17 -ContainerName workflow_2 -Command "mvn clean install"
    .\run.ps1 -ScriptName dotnet6 -ContainerName oa2 -Command "build"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$true)]
    [string]$Command
)

# 颜色定义
$Colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
    Default = "White"
}

# 日志函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $levelUpper = $Level.ToUpper()
    
    switch ($Level.ToLower()) {
        "success" { $Color = $Colors.Success }
        "error" { $Color = $Colors.Error }
        "warning" { $Color = $Colors.Warning }
        "info" { $Color = $Colors.Info }
        default { $Color = $Colors.Default }
    }
    
    Write-Host "[$timestamp] [$levelUpper] $Message" -ForegroundColor $Color
}

# 显示帮助
function Show-Help {
    Write-Host "MDDE 运行脚本使用说明 (PowerShell)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "用法:" -ForegroundColor White
    Write-Host "  .\run.ps1 -ScriptName <script-name> -ContainerName <container-name> -Command <command>" -ForegroundColor White
    Write-Host ""
    Write-Host "参数:" -ForegroundColor White
    Write-Host "  ScriptName:     脚本名称 (如: dotnet6, java17)" -ForegroundColor White
    Write-Host "  ContainerName:  容器名称" -ForegroundColor White
    Write-Host "  Command:        要执行的命令" -ForegroundColor White
    Write-Host ""
    Write-Host "示例:" -ForegroundColor White
    Write-Host "  .\run.ps1 -ScriptName dotnet6 -ContainerName oa2 -Command 'dotnet build'" -ForegroundColor White
    Write-Host "  .\run.ps1 -ScriptName java17 -ContainerName workflow_2 -Command 'mvn clean install'" -ForegroundColor White
    Write-Host "  .\run.ps1 -ScriptName python311 -ContainerName ml_project -Command 'python main.py'" -ForegroundColor White
    Write-Host ""
    Write-Host "预定义命令:" -ForegroundColor White
    Write-Host "  build:    构建项目" -ForegroundColor White
    Write-Host "  test:     运行测试" -ForegroundColor White
    Write-Host "  run:      运行项目" -ForegroundColor White
    Write-Host "  clean:    清理项目" -ForegroundColor White
    Write-Host "  install:  安装依赖" -ForegroundColor White
}

# 检查容器状态
function Test-ContainerStatus {
    param([string]$ContainerName)
    
    try {
        $running = docker ps --format "table {{.Names}}" 2>$null | Select-String "^$ContainerName$"
        if ($running) {
            Write-Log "容器 $ContainerName 正在运行" "Success"
            return $true
        }
        
        $stopped = docker ps -a --format "table {{.Names}}" 2>$null | Select-String "^$ContainerName$"
        if ($stopped) {
            Write-Log "容器 $ContainerName 已停止" "Warning"
            return $false
        }
        
        Write-Log "容器 $ContainerName 不存在" "Error"
        return $false
    } catch {
        Write-Log "检查容器状态失败: $($_.Exception.Message)" "Error"
        return $false
    }
}

# 执行预定义命令
function Invoke-PredefinedCommand {
    param(
        [string]$ScriptName,
        [string]$ContainerName,
        [string]$Command
    )
    
    switch ($Command.ToLower()) {
        "build" {
            switch ($ScriptName.ToLower()) {
                { $_ -in @("dotnet6", "dotnet9") } {
                    Write-Log "执行 .NET 构建命令" "Info"
                    docker exec $ContainerName dotnet build
                }
                "java17" {
                    Write-Log "执行 Java 构建命令" "Info"
                    docker exec $ContainerName mvn clean compile
                }
                "python311" {
                    Write-Log "执行 Python 构建命令" "Info"
                    docker exec $ContainerName python -m pip install -r requirements.txt
                }
                "nodejs18" {
                    Write-Log "执行 Node.js 构建命令" "Info"
                    docker exec $ContainerName npm install; docker exec $ContainerName npm run build
                }
                default {
                    Write-Log "未知的脚本类型: $ScriptName" "Warning"
                }
            }
        }
        "test" {
            switch ($ScriptName.ToLower()) {
                { $_ -in @("dotnet6", "dotnet9") } {
                    docker exec $ContainerName dotnet test
                }
                "java17" {
                    docker exec $ContainerName mvn test
                }
                "python311" {
                    docker exec $ContainerName python -m pytest
                }
                "nodejs18" {
                    docker exec $ContainerName npm test
                }
                default {
                    Write-Log "未知的脚本类型: $ScriptName" "Warning"
                }
            }
        }
        "run" {
            switch ($ScriptName.ToLower()) {
                { $_ -in @("dotnet6", "dotnet9") } {
                    docker exec $ContainerName dotnet run
                }
                "java17" {
                    docker exec $ContainerName mvn spring-boot:run
                }
                "python311" {
                    docker exec $ContainerName python main.py
                }
                "nodejs18" {
                    docker exec $ContainerName npm start
                }
                default {
                    Write-Log "未知的脚本类型: $ScriptName" "Warning"
                }
            }
        }
        "clean" {
            switch ($ScriptName.ToLower()) {
                { $_ -in @("dotnet6", "dotnet9") } {
                    docker exec $ContainerName dotnet clean
                }
                "java17" {
                    docker exec $ContainerName mvn clean
                }
                "python311" {
                    docker exec $ContainerName find . -type f -name "*.pyc" -delete
                    docker exec $ContainerName find . -type d -name "__pycache__" -delete
                }
                "nodejs18" {
                    docker exec $ContainerName rm -rf node_modules dist
                }
                default {
                    Write-Log "未知的脚本类型: $ScriptName" "Warning"
                }
            }
        }
        "install" {
            switch ($ScriptName.ToLower()) {
                { $_ -in @("dotnet6", "dotnet9") } {
                    docker exec $ContainerName dotnet restore
                }
                "java17" {
                    docker exec $ContainerName mvn dependency:resolve
                }
                "python311" {
                    docker exec $ContainerName python -m pip install -r requirements.txt
                }
                "nodejs18" {
                    docker exec $ContainerName npm install
                }
                default {
                    Write-Log "未知的脚本类型: $ScriptName" "Warning"
                }
            }
        }
        default {
            Write-Log "执行自定义命令: $Command" "Info"
            docker exec $ContainerName /bin/bash -c $Command
        }
    }
}

# 主程序
function Main {
    Write-Log "开始执行命令..." "Info"
    Write-Log "脚本名称: $ScriptName" "Info"
    Write-Log "容器名称: $ContainerName" "Info"
    Write-Log "执行命令: $Command" "Info"
    
    # 检查容器状态
    if (-not (Test-ContainerStatus $ContainerName)) {
        Write-Log "容器状态检查失败，请先启动容器" "Error"
        exit 1
    }
    
    # 执行命令
    try {
        Invoke-PredefinedCommand -ScriptName $ScriptName -ContainerName $ContainerName -Command $Command
        Write-Log "命令执行成功" "Success"
    } catch {
        Write-Log "命令执行失败: $($_.Exception.Message)" "Error"
        exit 1
    }
}

# 执行主程序
try {
    Main
} catch {
    Write-Log "程序执行出错: $($_.Exception.Message)" "Error"
    Show-Help
    exit 1
}

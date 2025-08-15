#!/usr/bin/env pwsh

<#
.SYNOPSIS
    MDDE - Multi-Development Docker Environment 管理工具

.DESCRIPTION
    用于创建、管理和部署Docker开发环境的PowerShell脚本

.PARAMETER Action
    操作类型：create, push, list, status, help

.PARAMETER ScriptName
    脚本名称，如 dotnet6, java17, python311

.PARAMETER ContainerName
    容器名称，如 oa2, workflow_2

.PARAMETER FileName
    要推送的文件名

.EXAMPLE
    .\mdde.ps1 --create dotnet6
    .\mdde.ps1 --push dotnet6 -f my-script.ps1
    .\mdde.ps1 --list
    .\mdde.ps1 --status
    .\mdde.ps1 --help

.NOTES
    作者: MDDE Team
    版本: 1.0.0
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("create", "push", "list", "status", "help")]
    [string]$Action = "help",
    
    [Parameter(Mandatory=$false)]
    [string]$ScriptName,
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$false)]
    [string]$FileName,
    
    [Parameter(Mandatory=$false)]
    [string]$ServerUrl = "http://localhost:3000"
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

# 显示帮助信息
function Show-Help {
    Write-Log "MDDE - Multi-Development Docker Environment 管理工具" "Info"
    Write-Log "==================================================" "Info"
    Write-Log ""
    Write-Log "用法:" "Info"
    Write-Log "  .\mdde.ps1 --create <script-name>" "Info"
    Write-Log "  .\mdde.ps1 --push <script-name> -f <filename>" "Info"
    Write-Log "  .\mdde.ps1 --list" "Info"
    Write-Log "  .\mdde.ps1 --status" "Info"
    Write-Log "  .\mdde.ps1 --help" "Info"
    Write-Log ""
    Write-Log "参数说明:" "Info"
    Write-Log "  --create, -c    创建Docker开发环境" "Info"
    Write-Log "  --push, -p      推送脚本到服务器" "Info"
    Write-Log "  --list, -l      列出可用的脚本" "Info"
    Write-Log "  --status, -s    显示系统状态" "Info"
    Write-Log "  --help, -h      显示此帮助信息" "Info"
    Write-Log ""
    Write-Log "示例:" "Info"
    Write-Log "  .\mdde.ps1 --create dotnet6" "Info"
    Write-Log "  .\mdde.ps1 --create java17" "Info"
    Write-Log "  .\mdde.ps1 --push dotnet6 -f my-script.ps1" "Info"
    Write-Log "  .\mdde.ps1 --list" "Info"
    Write-Log ""
    Write-Log "支持的开发环境:" "Info"
    Write-Log "  - dotnet6: .NET 6 开发环境" "Info"
    Write-Log "  - dotnet9: .NET 9 开发环境" "Info"
    Write-Log "  - java17: Java 17 开发环境" "Info"
    Write-Log "  - python311: Python 3.11 开发环境" "Info"
    Write-Log "  - nodejs18: Node.js 18 开发环境" "Info"
}

# 检查前置条件
function Test-Prerequisites {
    Write-Log "检查系统前置条件..." "Info"
    
    # 检查Docker
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            Write-Log "✅ Docker: $dockerVersion" "Success"
        } else {
            Write-Log "❌ Docker 未安装或未运行" "Error"
            return $false
        }
    } catch {
        Write-Log "❌ Docker 未安装或未运行" "Error"
        return $false
    }
    
    # 检查网络连接
    try {
        $response = Invoke-WebRequest -Uri "$ServerUrl/health" -TimeoutSec 5 -ErrorAction Stop
        Write-Log "✅ MDDE 服务器连接正常" "Success"
    } catch {
        Write-Log "❌ 无法连接到 MDDE 服务器: $ServerUrl" "Error"
        Write-Log "请确保服务器正在运行" "Warning"
        return $false
    }
    
    return $true
}

# 列出可用的脚本
function Get-ScriptList {
    Write-Log "获取可用的脚本列表..." "Info"
    
    try {
        $response = Invoke-RestMethod -Uri "$ServerUrl/list" -Method Get
        $directories = $response.directories
        
        if ($directories.Count -eq 0) {
            Write-Log "暂无可用的脚本" "Warning"
            return
        }
        
        Write-Log "可用的脚本目录:" "Info"
        foreach ($dir in $directories) {
            $scriptCount = $dir.scripts.Count
            Write-Log "  📁 $($dir.name) ($scriptCount 个脚本)" "Info"
            if ($scriptCount -gt 0) {
                $scriptList = $dir.scripts -join ", "
                Write-Log "     脚本: $scriptList" "Info"
            }
        }
    } catch {
        Write-Log "获取脚本列表失败: $($_.Exception.Message)" "Error"
    }
}

# 显示系统状态
function Show-SystemStatus {
    Write-Log "系统状态检查..." "Info"
    
    # Docker 状态
    try {
        $dockerInfo = docker info 2>$null
        if ($dockerInfo) {
            Write-Log "✅ Docker 运行正常" "Success"
        }
    } catch {
        Write-Log "❌ Docker 状态异常" "Error"
    }
    
    # 磁盘空间
    try {
        $drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $totalSpaceGB = [math]::Round($drive.Size / 1GB, 2)
        Write-Log "💾 磁盘空间: $freeSpaceGB GB / $totalSpaceGB GB" "Info"
    } catch {
        Write-Log "❌ 无法获取磁盘空间信息" "Error"
    }
    
    # 内存使用
    try {
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $freeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $totalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        Write-Log "🧠 内存使用: $freeMemoryGB GB / $totalMemoryGB GB" "Info"
    } catch {
        Write-Log "❌ 无法获取内存使用信息" "Error"
    }
}

# 创建开发环境
function New-DevelopmentEnvironment {
    param(
        [string]$ScriptName,
        [string]$ContainerName
    )
    
    Write-Log "开始创建开发环境..." "Info"
    Write-Log "脚本名称: $ScriptName" "Info"
    Write-Log "容器名称: $ContainerName" "Info"
    
    # 验证输入
    if (-not $ScriptName -or -not $ContainerName) {
        Write-Log "脚本名称和容器名称不能为空" "Error"
        return
    }
    
    # 检查前置条件
    if (-not (Test-Prerequisites)) {
        Write-Log "前置条件检查失败，无法继续" "Error"
        return
    }
    
    # 创建项目目录
    $projectDir = Join-Path (Get-Location) $ContainerName
    if (Test-Path $projectDir) {
        Write-Log "项目目录已存在: $projectDir" "Warning"
        $overwrite = Read-Host "是否覆盖？(y/N)"
        if ($overwrite -ne "y" -and $overwrite -ne "Y") {
            Write-Log "操作已取消" "Info"
            return
        }
        Remove-Item $projectDir -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $projectDir -Force | Out-Null
    Set-Location $projectDir
    
    Write-Log "项目目录已创建: $projectDir" "Success"
    
    # 下载脚本
    Write-Log "下载默认脚本..." "Info"
    try {
        Invoke-WebRequest -Uri "$ServerUrl/get/default" -OutFile "default_scripts.zip"
        Expand-Archive -Path "default_scripts.zip" -DestinationPath "." -Force
        Remove-Item "default_scripts.zip"
        Write-Log "✅ 默认脚本下载完成" "Success"
    } catch {
        Write-Log "❌ 默认脚本下载失败: $($_.Exception.Message)" "Error"
        return
    }
    
    # 下载特定脚本
    Write-Log "下载 $ScriptName 脚本..." "Info"
    try {
        Invoke-WebRequest -Uri "$ServerUrl/get/$ScriptName" -OutFile "${ScriptName}_scripts.zip"
        Expand-Archive -Path "${ScriptName}_scripts.zip" -DestinationPath "." -Force
        Remove-Item "${ScriptName}_scripts.zip"
        Write-Log "✅ $ScriptName 脚本下载完成" "Success"
    } catch {
        Write-Log "❌ $ScriptName 脚本下载失败: $($_.Exception.Message)" "Error"
        return
    }
    
    # 执行创建脚本
    $createScript = "create.ps1"
    if (Test-Path $createScript) {
        Write-Log "执行创建脚本: $createScript" "Info"
        try {
            & ".\$createScript" -ScriptName $ScriptName -ContainerName $ContainerName
            Write-Log "✅ 开发环境创建完成！" "Success"
        } catch {
            Write-Log "❌ 创建脚本执行失败: $($_.Exception.Message)" "Error"
        }
    } else {
        Write-Log "未找到创建脚本: $createScript" "Warning"
        Write-Log "请手动配置开发环境" "Info"
    }
    
    # 显示后续步骤
    Write-Log ""
    Write-Log "🎉 开发环境创建完成！" "Success"
    Write-Log "后续步骤:" "Info"
    Write-Log "1. 进入项目目录: cd $ContainerName" "Info"
    Write-Log "2. 启动容器: .\start.ps1" "Info"
    Write-Log "3. 运行命令: .\run.ps1 <command>" "Info"
    Write-Log "4. 停止容器: .\stop.ps1" "Info"
}

# 推送脚本到服务器
function Push-ScriptToServer {
    param(
        [string]$ScriptName,
        [string]$FileName
    )
    
    Write-Log "推送脚本到服务器..." "Info"
    Write-Log "脚本名称: $ScriptName" "Info"
    Write-Log "文件名: $FileName" "Info"
    
    # 验证输入
    if (-not $ScriptName -or -not $FileName) {
        Write-Log "脚本名称和文件名不能为空" "Error"
        return
    }
    
    # 检查文件是否存在
    if (-not (Test-Path $FileName)) {
        Write-Log "文件不存在: $FileName" "Error"
        return
    }
    
    # 检查前置条件
    if (-not (Test-Prerequisites)) {
        Write-Log "前置条件检查失败，无法继续" "Error"
        return
    }
    
    # 推送文件
    try {
        $form = @{
            script = Get-Item $FileName
        }
        
        $response = Invoke-RestMethod -Uri "$ServerUrl/upload/$ScriptName" -Method Post -Form $form
        
        Write-Log "✅ 脚本推送成功！" "Success"
        Write-Log "文件名: $($response.fileName)" "Info"
        Write-Log "目录: $($response.dirName)" "Info"
    } catch {
        Write-Log "❌ 脚本推送失败: $($_.Exception.Message)" "Error"
    }
}

# 主程序
function Main {
    Write-Log "🚀 MDDE - Multi-Development Docker Environment" "Info"
    Write-Log "版本: 1.0.0" "Info"
    Write-Log "==================================================" "Info"
    
    switch ($Action.ToLower()) {
        "create" {
            if (-not $ScriptName) {
                $ScriptName = Read-Host "请输入脚本名称 (如: dotnet6, java17)"
            }
            if (-not $ContainerName) {
                $ContainerName = Read-Host "请输入容器名称 (如: oa2, workflow_2)"
            }
            New-DevelopmentEnvironment -ScriptName $ScriptName -ContainerName $ContainerName
        }
        "push" {
            if (-not $ScriptName) {
                $ScriptName = Read-Host "请输入目标脚本目录名称"
            }
            if (-not $FileName) {
                $FileName = Read-Host "请输入要推送的文件名"
            }
            Push-ScriptToServer -ScriptName $ScriptName -FileName $FileName
        }
        "list" {
            Get-ScriptList
        }
        "status" {
            Show-SystemStatus
        }
        "help" {
            Show-Help
        }
        default {
            Write-Log "未知操作: $Action" "Error"
            Show-Help
        }
    }
}

# 执行主程序
try {
    Main
} catch {
    Write-Log "程序执行出错: $($_.Exception.Message)" "Error"
    Write-Log "请使用 --help 查看使用说明" "Info"
    exit 1
}

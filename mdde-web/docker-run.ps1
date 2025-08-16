# MDDE Web Docker 运行脚本

param(
    [string]$Tag = "mdde-web:latest",
    [string]$ContainerName = "mdde-web-container",
    [int]$Port = 3000,
    [string]$ScriptsPath = "",
    [switch]$Detach
)

Write-Host "🐳 启动 MDDE Web 容器..." -ForegroundColor Green

# 检查容器是否已存在
$existingContainer = docker ps -aq --filter "name=$ContainerName" 2>$null

if ($existingContainer) {
    Write-Host "⚠️  容器 '$ContainerName' 已存在，正在移除..." -ForegroundColor Yellow
    docker stop $ContainerName 2>$null | Out-Null
    docker rm $ContainerName 2>$null | Out-Null
}

# 构建运行命令
$runArgs = @("run")

if ($Detach) {
    $runArgs += "-d"
} else {
    $runArgs += "-it"
}

$runArgs += @(
    "--name", $ContainerName,
    "-p", "${Port}:3000"
)

# 如果指定了脚本路径，挂载 volumes
if ($ScriptsPath -and (Test-Path $ScriptsPath)) {
    $absoluteScriptsPath = Resolve-Path $ScriptsPath
    $runArgs += "-v", "${absoluteScriptsPath}:/app/scripts"
    Write-Host "📁 挂载脚本目录: $absoluteScriptsPath" -ForegroundColor Cyan
}

$runArgs += $Tag

try {
    # 执行运行命令
    Write-Host "🚀 运行命令: docker $($runArgs -join ' ')" -ForegroundColor Cyan
    & docker @runArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 容器启动成功!" -ForegroundColor Green
        Write-Host "🌐 访问地址: http://localhost:$Port" -ForegroundColor Cyan
        Write-Host "💚 健康检查: http://localhost:$Port/health" -ForegroundColor Cyan
        
        if ($Detach) {
            Write-Host "`n📋 容器状态:" -ForegroundColor Yellow
            docker ps --filter "name=$ContainerName"
            
            Write-Host "`n📝 查看日志命令:" -ForegroundColor Yellow
            Write-Host "docker logs -f $ContainerName" -ForegroundColor Cyan
        }
    } else {
        Write-Host "❌ 容器启动失败!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 运行过程中出现错误: $_" -ForegroundColor Red
    exit 1
}

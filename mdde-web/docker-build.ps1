# MDDE Web Docker 构建脚本

param(
    [string]$Tag = "mdde-web:latest",
    [switch]$NoCache
)

Write-Host "🐳 开始构建 MDDE Web Docker 镜像..." -ForegroundColor Green

# 构建命令
$buildArgs = @("build", "-t", $Tag)

if ($NoCache) {
    $buildArgs += "--no-cache"
}

$buildArgs += "."

try {
    # 执行构建
    & docker @buildArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker 镜像构建成功!" -ForegroundColor Green
        Write-Host "📦 镜像标签: $Tag" -ForegroundColor Cyan
        
        # 显示镜像信息
        Write-Host "`n📋 镜像信息:" -ForegroundColor Yellow
        docker images $Tag
        
        Write-Host "`n🚀 运行容器命令:" -ForegroundColor Yellow
        Write-Host "docker run -d -p 3000:3000 --name mdde-web-container $Tag" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Docker 镜像构建失败!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 构建过程中出现错误: $_" -ForegroundColor Red
    exit 1
}

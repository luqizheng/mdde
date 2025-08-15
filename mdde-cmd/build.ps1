# MDDE 构建脚本
# 用于在 Windows 环境下构建 Rust 项目

Write-Host "🚀 开始构建 MDDE 命令行工具..." -ForegroundColor Green

# 检查 Rust 是否安装
try {
    $rustVersion = rustc --version
    Write-Host "✓ Rust 已安装: $rustVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Rust 未安装，请先安装 Rust" -ForegroundColor Red
    Write-Host "访问 https://rustup.rs/ 安装 Rust" -ForegroundColor Yellow
    exit 1
}

# 检查 Cargo 是否可用
try {
    $cargoVersion = cargo --version
    Write-Host "✓ Cargo 已安装: $cargoVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Cargo 不可用" -ForegroundColor Red
    exit 1
}

# 清理之前的构建
Write-Host "🧹 清理之前的构建..." -ForegroundColor Yellow
cargo clean

# 检查依赖
Write-Host "📦 检查项目依赖..." -ForegroundColor Yellow
cargo check

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 依赖检查失败" -ForegroundColor Red
    exit 1
}

# 运行测试
Write-Host "🧪 运行测试..." -ForegroundColor Yellow
cargo test

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 测试失败" -ForegroundColor Red
    exit 1
}

# 构建项目
Write-Host "🔨 构建项目..." -ForegroundColor Yellow
cargo build --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 构建失败" -ForegroundColor Red
    exit 1
}

# 检查构建结果
$binaryPath = "target\release\mdde.exe"
if (Test-Path $binaryPath) {
    $fileSize = (Get-Item $binaryPath).Length
    $fileSizeKB = [math]::Round($fileSize / 1024, 2)
    
    Write-Host "✅ 构建成功!" -ForegroundColor Green
    Write-Host "二进制文件: $binaryPath" -ForegroundColor Cyan
    Write-Host "文件大小: $fileSizeKB KB" -ForegroundColor Cyan
    
    # 显示版本信息
    Write-Host "📋 版本信息:" -ForegroundColor Yellow
    & $binaryPath --version
} else {
    Write-Host "✗ 构建失败：找不到二进制文件" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 构建完成!" -ForegroundColor Green

# MDDE 快速启动脚本 (PowerShell)
# 自动安装依赖、构建项目并运行

Write-Host "🚀 MDDE 快速启动脚本" -ForegroundColor Green
Write-Host "====================" -ForegroundColor Green

# 检查 Rust 是否安装
try {
    $rustVersion = rustc --version
    Write-Host "✓ Rust 已安装: $rustVersion" -ForegroundColor Green
} catch {
    Write-Host "📦 安装 Rust..." -ForegroundColor Yellow
    Write-Host "请访问 https://rustup.rs/ 下载并安装 Rust" -ForegroundColor Red
    Write-Host "或者运行以下命令:" -ForegroundColor Cyan
    Write-Host "  winget install Rustlang.Rust.MSVC" -ForegroundColor Cyan
    Write-Host "  choco install rust" -ForegroundColor Cyan
    exit 1
}

# 检查 Cargo 是否可用
try {
    $cargoVersion = cargo --version
    Write-Host "✓ Cargo 已安装: $cargoVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Cargo 不可用，请重新安装 Rust" -ForegroundColor Red
    exit 1
}

# 安装必要的工具
Write-Host "🔧 安装开发工具..." -ForegroundColor Yellow
rustup component add rustfmt
rustup component add clippy

# 检查依赖
Write-Host "📋 检查项目依赖..." -ForegroundColor Yellow
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
    
    # 显示帮助信息
    Write-Host ""
    Write-Host "🎉 MDDE 已准备就绪!" -ForegroundColor Green
    Write-Host "运行以下命令查看帮助:" -ForegroundColor Yellow
    Write-Host "  .\$binaryPath --help" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "快速开始:" -ForegroundColor Yellow
    Write-Host "  1. 初始化配置: .\$binaryPath init" -ForegroundColor Cyan
    Write-Host "  2. 创建环境: .\$binaryPath create dotnet9 --name my-app" -ForegroundColor Cyan
    Write-Host "  3. 启动环境: .\$binaryPath start my-app" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "或者安装到系统:" -ForegroundColor Yellow
    Write-Host "  cargo install --path ." -ForegroundColor Cyan
    
    # 显示版本信息
    Write-Host ""
    Write-Host "📋 版本信息:" -ForegroundColor Yellow
    & $binaryPath --version
} else {
    Write-Host "✗ 构建失败：找不到二进制文件" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 快速启动完成!" -ForegroundColor Green





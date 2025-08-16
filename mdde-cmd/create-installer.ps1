# MDDE 一键打包脚本
# 快速生成 Windows 安装包

param(
    [switch]$Force,      # 强制运行，跳过确认
    [switch]$Help        # 显示帮助
)

# 显示帮助信息
if ($Help) {
    Write-Host "MDDE Windows 安装包生成器" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "用法: .\create-installer.ps1 [参数]"
    Write-Host ""
    Write-Host "参数:"
    Write-Host "  -Force    强制运行，跳过所有确认"
    Write-Host "  -Help     显示此帮助信息"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\create-installer.ps1         # 交互式运行"
    Write-Host "  .\create-installer.ps1 -Force  # 自动运行"
    exit 0
}

Write-Host "🚀 MDDE Windows 安装包生成器" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否在正确的目录
if (-not (Test-Path "Cargo.toml")) {
    Write-Host "❌ 错误: 请在 mdde-cmd 项目根目录运行此脚本" -ForegroundColor Red
    Write-Host "当前目录: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

# 显示项目信息
Write-Host "📁 项目目录: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# 询问用户是否继续
if (-not $Force) {
    $continue = Read-Host "是否开始生成安装包? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "取消操作" -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "使用强制模式，自动开始生成安装包..." -ForegroundColor Green
}

Write-Host ""
Write-Host "正在准备构建环境..." -ForegroundColor Yellow

# 检查构建脚本是否存在
$BuildScript = ".\build-installer.ps1"
if (-not (Test-Path $BuildScript)) {
    Write-Host "❌ 找不到构建脚本: $BuildScript" -ForegroundColor Red
    exit 1
}

# 运行构建脚本
try {
    Write-Host "🔨 开始构建..." -ForegroundColor Green
    & $BuildScript
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "🎉 安装包生成成功！" -ForegroundColor Green
        Write-Host ""
        
        # 查找生成的安装包
        $InstallerDir = ".\installer\output"
        if (Test-Path $InstallerDir) {
            $Installers = Get-ChildItem -Path $InstallerDir -Filter "*.exe" | Sort-Object LastWriteTime -Descending
            if ($Installers.Count -gt 0) {
                $LatestInstaller = $Installers[0]
                Write-Host "📦 安装包位置: $($LatestInstaller.FullName)" -ForegroundColor Green
                Write-Host "📏 文件大小: $([math]::Round($LatestInstaller.Length / 1MB, 2)) MB" -ForegroundColor Green
                
                # 询问是否打开文件夹
                if (-not $Force) {
                    $openFolder = Read-Host "是否打开安装包所在文件夹? (Y/n)"
                    if ($openFolder -ne "n" -and $openFolder -ne "N") {
                        Invoke-Item (Split-Path -Parent $LatestInstaller.FullName)
                    }
                    
                    # 询问是否运行安装包
                    Write-Host ""
                    $runInstaller = Read-Host "是否运行安装包进行测试? (y/N)"
                    if ($runInstaller -eq "y" -or $runInstaller -eq "Y") {
                        Write-Host "正在启动安装程序..." -ForegroundColor Yellow
                        Start-Process -FilePath $LatestInstaller.FullName
                    }
                } else {
                    Write-Host "强制模式下跳过打开文件夹和运行安装包" -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "❌ 构建失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 构建过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ 操作完成！" -ForegroundColor Green


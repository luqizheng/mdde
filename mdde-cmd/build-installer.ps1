# MDDE Windows 安装包构建脚本
# 自动编译 Rust 项目并生成 Windows 安装包

param(
    [switch]$Clean,      # 清理构建
    [switch]$SkipBuild,  # 跳过 Rust 编译
    [switch]$Help        # 显示帮助
)

# 颜色函数
function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Success { param([string]$Text) Write-ColorText $Text "Green" }
function Write-Error { param([string]$Text) Write-ColorText $Text "Red" }
function Write-Warning { param([string]$Text) Write-ColorText $Text "Yellow" }
function Write-Info { param([string]$Text) Write-ColorText $Text "Cyan" }

# 显示帮助信息
if ($Help) {
    Write-Info "MDDE Windows 安装包构建脚本"
    Write-Host ""
    Write-Host "用法: .\build-installer.ps1 [参数]"
    Write-Host ""
    Write-Host "参数:"
    Write-Host "  -Clean      清理所有构建文件"
    Write-Host "  -SkipBuild  跳过 Rust 项目编译"
    Write-Host "  -Help       显示此帮助信息"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\build-installer.ps1              # 完整构建"
    Write-Host "  .\build-installer.ps1 -Clean       # 清理构建"
    Write-Host "  .\build-installer.ps1 -SkipBuild   # 仅生成安装包"
    exit 0
}

# 设置错误处理
$ErrorActionPreference = "Stop"

Write-Info "=== MDDE Windows 安装包构建器 ==="
Write-Host ""

# 获取脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$InstallerDir = Join-Path $ScriptDir "installer"
$OutputDir = Join-Path $InstallerDir "output"

Write-Info "项目目录: $ProjectRoot"
Write-Info "安装器目录: $InstallerDir"
Write-Info "输出目录: $OutputDir"
Write-Host ""

# 清理构建
if ($Clean) {
    Write-Warning "正在清理构建文件..."
    
    # 清理 Rust 构建
    if (Test-Path "$ScriptDir\target") {
        Remove-Item "$ScriptDir\target" -Recurse -Force
        Write-Success "已清理 Rust 构建文件"
    }
    
    # 清理安装包输出
    if (Test-Path $OutputDir) {
        Remove-Item $OutputDir -Recurse -Force
        Write-Success "已清理安装包输出文件"
    }
    
    Write-Success "清理完成！"
    exit 0
}

# 检查依赖
Write-Info "检查构建依赖..."

# 检查 Rust
try {
    $rustVersion = & cargo --version 
    if ($LASTEXITCODE -ne 0) {
        throw "Cargo 命令失败"
    }
    Write-Success "✓ Rust: $rustVersion"
} catch {
    Write-Error "✗ 未找到 Rust 工具链"
    Write-Error "请访问 https://rustup.rs/ 安装 Rust"
    exit 1
}

# 检查 Inno Setup
$InnoSetupPath = ""
$PossiblePaths = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 5\ISCC.exe"
)

foreach ($Path in $PossiblePaths) {
    if (Test-Path $Path) {
        $InnoSetupPath = $Path
        break
    }
}

if (-not $InnoSetupPath) {
    # 尝试在 PATH 中查找
    try {
        $isccVersion = & iscc 
        $InnoSetupPath = "iscc"
        Write-Success "✓ Inno Setup: 在 PATH 中找到"
    } catch {
        Write-Error "✗ 未找到 Inno Setup 编译器 (ISCC.exe)"
        Write-Error "请从 https://jrsoftware.org/isinfo.php 安装 Inno Setup"
        exit 1
    }
} else {
    Write-Success "✓ Inno Setup: $InnoSetupPath"
}

# 检查 Docker (可选)
try {
    $dockerVersion = & docker --version 
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✓ Docker: $dockerVersion"
    }
} catch {
    Write-Warning "○ Docker 未安装或未运行 (运行时需要)"
}

Write-Host ""

# 编译 Rust 项目
if (-not $SkipBuild) {
    Write-Info "编译 Rust 项目..."
    
    Push-Location $ScriptDir
    try {
        Write-Info "运行 cargo build --release..."
        $buildOutput = & cargo build --release
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Rust 编译失败:"
            Write-Error $buildOutput
            exit 1
        }
        
        # 检查生成的可执行文件
        $ExePath = Join-Path $ScriptDir "target\release\mdde.exe"
        if (-not (Test-Path $ExePath)) {
            Write-Error "找不到编译后的可执行文件: $ExePath"
            exit 1
        }
        
        $ExeSize = (Get-Item $ExePath).Length
        Write-Success "✓ Rust 编译完成 ($([math]::Round($ExeSize / 1KB, 2)) KB)"
        
        # 显示版本信息
        try {
            $versionOutput = & $ExePath version
            Write-Success "✓ 版本验证: $versionOutput"
        } catch {
            Write-Warning "○ 无法获取版本信息"
        }
        
    } finally {
        Pop-Location
    }
} else {
    Write-Warning "跳过 Rust 编译"
    
    # 检查可执行文件是否存在
    $ExePath = Join-Path $ScriptDir "target\release\mdde.exe"
    if (-not (Test-Path $ExePath)) {
        Write-Error "找不到可执行文件: $ExePath"
        Write-Error "请先编译项目或移除 -SkipBuild 参数"
        exit 1
    }
}

Write-Host ""

# 准备安装器文件
Write-Info "准备安装器文件..."

# 确保安装器目录存在
if (-not (Test-Path $InstallerDir)) {
    New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null
}

# 确保输出目录存在
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# 创建简单的图标文件 (可选)
$IconPath = Join-Path $InstallerDir "mdde-icon.ico"
if (-not (Test-Path $IconPath)) {
    Write-Warning "○ 未找到图标文件，将使用默认图标"
    # 这里可以添加创建默认图标的代码
}

# 检查许可证文件
$LicensePath = Join-Path $ProjectRoot "LICENSE"
if (-not (Test-Path $LicensePath)) {
    Write-Warning "○ 未找到 LICENSE 文件，创建默认许可证..."
    Set-Content -Path $LicensePath -Value @"
MIT License

Copyright (c) 2024 MDDE Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@
}

Write-Host ""

# 编译安装程序
Write-Info "编译安装程序..."

$SetupScriptPath = Join-Path $InstallerDir "mdde-setup.iss"
if (-not (Test-Path $SetupScriptPath)) {
    Write-Error "找不到安装脚本: $SetupScriptPath"
    exit 1
}

Push-Location $InstallerDir
try {
    Write-Info "运行 Inno Setup 编译器..."
    
    if ($InnoSetupPath -eq "iscc") {
        $compileOutput = & iscc "mdde-setup.iss" 
    } else {
        $compileOutput = & $InnoSetupPath "mdde-setup.iss" 
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Inno Setup 编译失败:"
        Write-Error $compileOutput
        exit 1
    }
    
    Write-Success "✓ 安装程序编译完成"
    
} finally {
    Pop-Location
}

# 查找生成的安装包
$InstallerFiles = Get-ChildItem -Path $OutputDir -Filter "MDDE-Setup-*.exe" | Sort-Object LastWriteTime -Descending

if ($InstallerFiles.Count -eq 0) {
    Write-Error "未找到生成的安装包文件"
    exit 1
}

$LatestInstaller = $InstallerFiles[0]
$InstallerSize = [math]::Round($LatestInstaller.Length / 1MB, 2)

Write-Host ""
Write-Success "=== 构建完成 ==="
Write-Success "安装包: $($LatestInstaller.FullName)"
Write-Success "大小: $InstallerSize MB"
Write-Success "创建时间: $($LatestInstaller.LastWriteTime)"

Write-Host ""
Write-Info "后续步骤:"
Write-Host "1. 运行安装包进行测试"
Write-Host "2. 分发安装包给用户"
Write-Host "3. 确保目标机器已安装 Docker Desktop"

Write-Host ""
Write-Success "构建成功完成！"

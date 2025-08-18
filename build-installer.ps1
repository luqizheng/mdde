#!/usr/bin/env pwsh
# MDDE 跨平台构建和安装包生成脚本 (PowerShell)
# 支持 Windows/Linux/macOS 构建和 Windows 安装包生成

param(
    [switch]$Help,
    [switch]$Clean,
    [switch]$SkipBuild,
    [switch]$SkipInstaller,
    [switch]$Verbose,
    [string]$OutputDir = "release-builds",
    [string]$DockerImage = "luqizheng/mdde-cmd-building-env:latest",
    [string]$FallbackImage = "rust:1.89.0-trixie",
    [string]$Version = "0.1.0"
)

# 颜色输出函数
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Info { param([string]$Text) Write-ColorText "[INFO] $Text" "Cyan" }
function Write-Success { param([string]$Text) Write-ColorText "[SUCCESS] $Text" "Green" }
function Write-Warning { param([string]$Text) Write-ColorText "[WARNING] $Text" "Yellow" }
function Write-Error { param([string]$Text) Write-ColorText "[ERROR] $Text" "Red" }

# 显示帮助信息
function Show-Help {
    Write-ColorText @"
MDDE 跨平台构建和安装包生成脚本
=====================================

用法: .\build-installer.ps1 [选项]

选项:
  -Help            显示此帮助信息
  -Clean           清理构建文件和输出目录
  -SkipBuild       跳过 Docker 编译步骤
  -SkipInstaller   跳过 Windows 安装包生成
  -Verbose         显示详细输出
  -OutputDir       指定输出目录 (默认: release-builds)
  -DockerImage     指定 Docker 镜像 (默认: luqizheng/mdde-cmd-building-env:latest)
  -Version         指定版本号 (默认: 0.1.0)

示例:
  .\build-installer.ps1                    # 完整构建所有平台
  .\build-installer.ps1 -Clean             # 清理构建文件
  .\build-installer.ps1 -SkipBuild         # 只生成安装包
  .\build-installer.ps1 -SkipInstaller     # 只编译不生成安装包
  .\build-installer.ps1 -Verbose           # 显示详细日志

支持平台:
  - Windows x64 (with installer)
  - Linux x64
  - macOS Intel x64
  - macOS Apple Silicon (ARM64)
"@ "White"
    exit 0
}

# 检查必需的工具
function Test-Prerequisites {
    Write-Info "检查构建环境..."
    
    # 检查 Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker 未安装或不在 PATH 中"
        Write-Info "请安装 Docker Desktop: https://www.docker.com/products/docker-desktop"
        exit 1
    }
    
    # 检查 Docker 服务
    try {
        $null = docker version 2>$null
        Write-Success "Docker 环境正常"
    }
    catch {
        Write-Error "Docker 服务未运行"
        Write-Info "请启动 Docker Desktop"
        exit 1
    }
    
    # 检查 Inno Setup (仅在需要生成安装包时)
    if (-not $SkipInstaller) {
        $innoSetupPaths = @(
            "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
            "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
            "ISCC.exe"
        )
        
        $innoSetupFound = $false
        foreach ($path in $innoSetupPaths) {
            if (Get-Command $path -ErrorAction SilentlyContinue) {
                $global:InnoSetupPath = $path
                $innoSetupFound = $true
                break
            }
        }
        
        if (-not $innoSetupFound) {
            Write-Warning "Inno Setup 未找到，将跳过 Windows 安装包生成"
            Write-Info "下载地址: https://jrsoftware.org/isinfo.php"
            $global:SkipInstaller = $true
        } else {
            Write-Success "Inno Setup 找到: $InnoSetupPath"
        }
    }
}

# 清理构建文件
function Clear-BuildFiles {
    Write-Info "清理构建文件..."
    
    $cleanDirs = @($OutputDir, "mdde-cmd\target", "mdde-cmd\installer\output")
    
    foreach ($dir in $cleanDirs) {
        if (Test-Path $dir) {
            Write-Info "删除目录: $dir"
            Remove-Item $dir -Recurse -Force
        }
    }
    
    Write-Success "清理完成"
}

# 创建输出目录结构
function New-OutputDirectories {
    Write-Info "创建输出目录结构..."
    
    $dirs = @(
        $OutputDir,
        "$OutputDir\windows-x64",
        "$OutputDir\linux-x64", 
        "$OutputDir\macos-x64",
        "$OutputDir\macos-arm64",
        "$OutputDir\installers"
    )
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            if ($Verbose) { Write-Info "创建目录: $dir" }
        }
    }
    
    Write-Success "输出目录结构已创建"
}

# 拉取 Docker 镜像
function Get-DockerImage {
    Write-Info "拉取 Docker 镜像: $DockerImage"
    
    try {
        if ($Verbose) {
            docker pull $DockerImage
        } else {
            docker pull $DockerImage 2>&1 | Out-Null
        }
        
        # 测试镜像是否可用
        $testResult = docker run --rm $DockerImage echo "test" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "主镜像不可用，尝试使用备用镜像: $FallbackImage"
            $global:DockerImage = $FallbackImage
            
            if ($Verbose) {
                docker pull $FallbackImage
            } else {
                docker pull $FallbackImage 2>&1 | Out-Null
            }
            
            # 再次测试备用镜像
            $testResult = docker run --rm $FallbackImage echo "test" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Error "备用镜像也不可用"
                exit 1
            }
            Write-Success "备用 Docker 镜像可用: $FallbackImage"
        } else {
            Write-Success "Docker 镜像拉取成功"
        }
    }
    catch {
        Write-Error "Docker 镜像拉取失败: $($_.Exception.Message)"
        exit 1
    }
}

# 检测 Docker 镜像支持的编译目标
function Test-DockerImageTargets {
    Write-Info "检测 Docker 镜像支持的编译目标..."
    
    $currentDir = Get-Location
    
    # 如果使用备用镜像，返回简化的结果
    if ($DockerImage -eq $FallbackImage) {
        Write-Info "使用备用镜像 Rust 官方镜像，将在编译时动态安装目标"
        return @{
            InstalledTargets = @()  # 空数组表示将动态安装
            OSXCrossAvailable = $false
        }
    }
    
    try {
        # 对于非备用镜像，检查已安装的目标
        $installedTargets = @()
        $targetsOutput = docker run --rm -v "${currentDir}:/workspace" -w "/workspace/mdde-cmd" $DockerImage rustup target list --installed 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            if ($Verbose) {
                Write-Info "已安装的 Rust 目标:"
                Write-Host $targetsOutput
            }
            $installedTargets = $targetsOutput -split "`n" | Where-Object { $_ -match "^\w" }
        } else {
            Write-Warning "无法检查已安装的目标，继续尝试编译"
        }
        
        # 检查 osxcross 工具是否可用（用于 macOS 交叉编译）
        $osxcrossAvailable = $false
        try {
            $osxcrossTest = docker run --rm $DockerImage which osxcross-clang 2>&1
            if ($LASTEXITCODE -eq 0) {
                $osxcrossAvailable = $true
                Write-Success "发现 osxcross 工具链，支持 macOS 交叉编译"
            }
        }
        catch {
            # osxcross 不可用
        }
        
        # 如果没有 osxcross，尝试检查是否有基本的 clang
        if (-not $osxcrossAvailable) {
            try {
                $clangTest = docker run --rm $DockerImage which clang 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Info "发现 clang，可能支持部分 macOS 编译"
                }
            }
            catch {
                # clang 也不可用
            }
        }
        
        return @{
            InstalledTargets = $installedTargets
            OSXCrossAvailable = $osxcrossAvailable
        }
    }
    catch {
        Write-Warning "无法检测 Docker 镜像支持的目标: $($_.Exception.Message)"
        return @{
            InstalledTargets = @()
            OSXCrossAvailable = $false
        }
    }
}

# 跨平台编译
function Build-CrossPlatform {
    Write-Info "开始跨平台编译..."
    
    # 检测 Docker 镜像支持的目标（仅在非备用镜像时检测）
    $dockerTargets = $null
    if ($DockerImage -ne $FallbackImage) {
        $dockerTargets = Test-DockerImageTargets
    } else {
        Write-Info "使用备用镜像，将在编译时动态安装目标"
        $dockerTargets = @{
            InstalledTargets = @()
            OSXCrossAvailable = $false
        }
    }
    
    $currentDir = Get-Location
    $targets = @(
        @{ 
            Name = "Windows x64"; 
            Target = "x86_64-pc-windows-msvc"; 
            Extension = ".exe"; 
            OutputDir = "windows-x64";
            EnvVars = @();
            LinkerConfig = @()
        },
        @{ 
            Name = "Linux x64"; 
            Target = "x86_64-unknown-linux-gnu"; 
            Extension = ""; 
            OutputDir = "linux-x64";
            EnvVars = @(
                "CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc"
            );
            LinkerConfig = @(
                "apt-get update -qq && apt-get install -y gcc-x86_64-linux-gnu || echo 'Failed to install Linux cross compiler'"
            )
        },
        @{ 
            Name = "macOS Intel"; 
            Target = "x86_64-apple-darwin"; 
            Extension = ""; 
            OutputDir = "macos-x64";
            EnvVars = @(
                "CC=o64-clang",
                "CXX=o64-clang++",
                "CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=x86_64-apple-darwin14-clang"
            );
            LinkerConfig = @();
            RequiresOSXCross = $true
        },
        @{ 
            Name = "macOS ARM64"; 
            Target = "aarch64-apple-darwin"; 
            Extension = ""; 
            OutputDir = "macos-arm64";
            EnvVars = @(
                "CC=oa64-clang",
                "CXX=oa64-clang++",
                "CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER=aarch64-apple-darwin20-clang"
            );
            LinkerConfig = @();
            RequiresOSXCross = $true
        }
    )
    
    foreach ($target in $targets) {
        # 如果使用备用镜像，跳过 macOS 目标（需要特殊工具链）
        if ($DockerImage -eq $FallbackImage -and $target.ContainsKey("RequiresOSXCross") -and $target.RequiresOSXCross) {
            Write-Warning "跳过 $($target.Name) - 备用镜像不支持 macOS 交叉编译"
            continue
        }
        
        # 对于非备用镜像，检查是否支持该目标
        if ($DockerImage -ne $FallbackImage) {
            if ($target.ContainsKey("RequiresOSXCross") -and $target.RequiresOSXCross -and -not $dockerTargets.OSXCrossAvailable) {
                Write-Warning "跳过 $($target.Name) - Docker 镜像不支持 macOS 交叉编译"
                Write-Info "提示: 需要包含 osxcross 工具链的 Docker 镜像"
                continue
            }
            
            if ($dockerTargets.InstalledTargets.Count -gt 0 -and $dockerTargets.InstalledTargets -notcontains $target.Target) {
                Write-Warning "跳过 $($target.Name) - 目标 $($target.Target) 未安装在 Docker 镜像中"
                continue
            }
        }
        
        # 对于备用镜像，只跳过 macOS 目标，其他目标尝试编译
        Write-Info "准备编译 $($target.Name) - 使用镜像: $DockerImage"
        
        Write-Info "编译 $($target.Name) ($($target.Target))..."
        
        # 构建 Docker 命令
        $dockerCmd = @("docker", "run", "--rm")
        
        # 添加环境变量
        foreach ($envVar in $target.EnvVars) {
            $dockerCmd += @("-e", $envVar)
        }
        
        $dockerCmd += @(
            "-v", "${currentDir}:/workspace",
            "-w", "/workspace/mdde-cmd",
            $global:DockerImage
        )
        
        # 构建编译命令
        $compileCmd = "cargo build --release --target $($target.Target)"
        
        # 如果使用备用镜像，需要先安装工具链
        if ($DockerImage -eq $FallbackImage) {
            $setupCmd = @(
                "rustup target add $($target.Target)",
                "apt-get update -qq",
                "apt-get install -y build-essential"
            )
            
            # 为Linux目标添加特定的交叉编译工具
            if ($target.Target -eq "x86_64-unknown-linux-gnu") {
                $setupCmd += "apt-get install -y gcc-x86_64-linux-gnu"
            }
            
            # 为Windows目标添加mingw
            if ($target.Target -eq "x86_64-pc-windows-msvc") {
                $setupCmd += "apt-get install -y mingw-w64"
                $setupCmd += "rustup target add x86_64-pc-windows-gnu"  # 使用GNU工具链
                # 更新目标为GNU版本，因为MSVC需要Visual Studio
                $target.Target = "x86_64-pc-windows-gnu"
            }
            
            $fullCmd = ($setupCmd + $compileCmd) -join " && "
            $dockerCmd += @("bash", "-c", $fullCmd)
        } elseif ($target.LinkerConfig.Count -gt 0) {
            $setupCmd = $target.LinkerConfig -join " && "
            $dockerCmd += @("bash", "-c", "$setupCmd && $compileCmd")
        } else {
            $dockerCmd += @("bash", "-c", $compileCmd)
        }
        
        try {
            Write-Info "执行命令: $($dockerCmd -join ' ')"
            
            # 执行编译
            $compilationResult = & $dockerCmd[0] $dockerCmd[1..($dockerCmd.Length-1)] 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($Verbose -or $exitCode -ne 0) {
                Write-Host $compilationResult
            }
            
            if ($exitCode -ne 0) {
                Write-Error "$($target.Name) 编译失败 (退出码: $exitCode)"
                continue
            }
            
            # 检查编译结果
            $sourcePath = "mdde-cmd\target\$($target.Target)\release\mdde$($target.Extension)"
            $destPath = "$OutputDir\$($target.OutputDir)\mdde$($target.Extension)"
            
            if (Test-Path $sourcePath) {
                Copy-Item $sourcePath $destPath -Force
                $fileSize = [math]::Round((Get-Item $destPath).Length / 1MB, 2)
                Write-Success "$($target.Name) 编译完成: $destPath ($fileSize MB)"
            } else {
                Write-Warning "$($target.Name) 编译产物未找到: $sourcePath"
                # 列出目标目录内容进行调试
                $targetDir = "mdde-cmd\target\$($target.Target)\release"
                if (Test-Path $targetDir) {
                    Write-Info "目标目录内容:"
                    Get-ChildItem $targetDir | ForEach-Object { Write-Info "  - $($_.Name)" }
                } else {
                    Write-Warning "目标目录不存在: $targetDir"
                }
            }
        }
        catch {
            Write-Error "$($target.Name) 编译失败: $($_.Exception.Message)"
        }
    }
}

# 生成文件信息
function New-BuildInfo {
    Write-Info "生成构建信息文件..."
    
    $buildInfo = @{
        version = $Version
        buildTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        dockerImage = $global:DockerImage
        platforms = @("Windows x64", "Linux x64", "macOS Intel x64", "macOS Apple Silicon ARM64")
        files = @()
    }
    
    # 收集生成的文件信息
    Get-ChildItem $OutputDir -Recurse -File | ForEach-Object {
        $buildInfo.files += @{
            name = $_.Name
            path = $_.FullName.Replace($PWD.Path + "\", "")
            size = [math]::Round($_.Length / 1MB, 2)
            hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        }
    }
    
    $buildInfo | ConvertTo-Json -Depth 3 | Out-File "$OutputDir\build-info.json" -Encoding UTF8
    Write-Success "构建信息已保存到: $OutputDir\build-info.json"
}

# 生成 Windows 安装包
function New-WindowsInstaller {
    if ($SkipInstaller) {
        Write-Info "跳过 Windows 安装包生成"
        return
    }
    
    Write-Info "生成 Windows 安装包..."
    
    # 确保 Windows 可执行文件存在
    $windowsExe = "$OutputDir\windows-x64\mdde.exe"
    if (-not (Test-Path $windowsExe)) {
        Write-Warning "Windows 可执行文件不存在，跳过安装包生成"
        return
    }
    
    # 复制 Windows 可执行文件到目标位置
    $targetExe = "mdde-cmd\target\release\mdde.exe"
    $targetDir = Split-Path $targetExe -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Copy-Item $windowsExe $targetExe -Force
    
    # 运行 Inno Setup
    try {
        $innoScript = "mdde-cmd\installer\mdde-setup.iss"
        $innoOutputDir = "mdde-cmd\installer\output"
        
        if ($Verbose) {
            & $InnoSetupPath $innoScript
        } else {
            & $InnoSetupPath $innoScript 2>&1 | Out-Null
        }
        
        # 复制安装包到输出目录
        if (Test-Path $innoOutputDir) {
            Get-ChildItem $innoOutputDir -Filter "*.exe" | ForEach-Object {
                $destPath = "$OutputDir\installers\$($_.Name)"
                Copy-Item $_.FullName $destPath -Force
                Write-Success "Windows 安装包已生成: $destPath"
            }
        } else {
            Write-Warning "安装包输出目录不存在: $innoOutputDir"
        }
    }
    catch {
        Write-Error "Windows 安装包生成失败: $($_.Exception.Message)"
    }
}

# 显示构建结果摘要
function Show-BuildSummary {
    Write-ColorText "`n" "White"
    Write-ColorText "Build Summary" "Green"
    Write-ColorText "=================" "Green"
    
    if (Test-Path "$OutputDir\build-info.json") {
        $buildInfo = Get-Content "$OutputDir\build-info.json" | ConvertFrom-Json
        Write-Info "版本: $($buildInfo.version)"
        Write-Info "构建时间: $($buildInfo.buildTime)"
        Write-Info "Docker 镜像: $($buildInfo.dockerImage)"
        Write-ColorText "`n生成的文件:" "White"
        
        $buildInfo.files | ForEach-Object {
            Write-ColorText "  [File] $($_.path) ($($_.size) MB)" "Gray"
        }
    }
    
    Write-ColorText "`n输出目录: $OutputDir" "Cyan"
    Write-ColorText "使用 'tree $OutputDir' 查看完整目录结构" "Gray"
}

# 主函数
function Main {
    Write-ColorText "MDDE Cross-Platform Build Script" "Green"
    Write-ColorText "======================" "Green"
    
    if ($Help) {
        Show-Help
    }
    
    if ($Clean) {
        Clear-BuildFiles
        Write-Success "清理完成"
        exit 0
    }
    
    # 检查环境
    Test-Prerequisites
    
    # 创建输出目录
    New-OutputDirectories
    
    if (-not $SkipBuild) {
        # 拉取 Docker 镜像
        Get-DockerImage
        
        # 跨平台编译
        Build-CrossPlatform
    }
    
    # 生成 Windows 安装包
    New-WindowsInstaller
    
    # 生成构建信息
    New-BuildInfo
    
    # 显示摘要
    Show-BuildSummary
    
    Write-Success "All tasks completed!"
}

# 错误处理
trap {
    Write-Error "脚本执行出错: $($_.Exception.Message)"
    Write-Info "使用 -Help 参数查看帮助信息"
    exit 1
}

# 执行主函数
Main

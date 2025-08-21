# MDDE Project Build Script (Windows PowerShell)
# Build cross-platform binaries and create packages

param(
    [switch]$Clean,
    [switch]$InstallTargets,
    [switch]$Help
)

# Project configuration
$ProjectName = "mdde"
$ProjectDir = "mdde-cmd"
$BuildDir = "release-builds"
$PackageDir = "packages"

# Get version from Cargo.toml
if (Test-Path "$ProjectDir\Cargo.toml") {
    $VersionLine = Get-Content "$ProjectDir\Cargo.toml" | Where-Object { $_ -match '^version\s*=' } | Select-Object -First 1
    $Version = ($VersionLine -split '"')[1]
} else {
    $Version = "unknown"
}

# Log functions
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Check dependencies
function Test-Dependencies {
    Write-Info "Checking build dependencies..."
    
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        Write-Error "Rust/Cargo not found. Please install Rust first"
        exit 1
    }
    
    Write-Success "Dependencies check completed"
}

# Install target platforms
function Install-Targets {
    Write-Info "Installing target platforms..."
    
    $targets = @(
        "x86_64-unknown-linux-gnu",
        "x86_64-pc-windows-msvc",
        "x86_64-apple-darwin",
        "aarch64-apple-darwin"
    )
    
    foreach ($target in $targets) {
        Write-Info "Installing target: $target"
        rustup target add $target | Out-Null
    }
    
    Write-Success "Target platforms installed"
}

# Clean build directories
function Clear-Build {
    Write-Info "Cleaning build directories..."
    
    Push-Location $ProjectDir
    cargo clean | Out-Null
    Pop-Location
    
    if (Test-Path $BuildDir) {
        Remove-Item -Recurse -Force $BuildDir
    }
    
    if (Test-Path $PackageDir) {
        Remove-Item -Recurse -Force $PackageDir
    }
    
    Write-Success "Build directories cleaned"
}

# Build target platform
function Build-Target {
    param([string]$Target, [string]$TargetName)
    
    Write-Info "Building $TargetName ($Target)..."
    
    Push-Location $ProjectDir
    cargo build --release --target $Target 2>&1 | Out-Null
    $success = $LASTEXITCODE -eq 0
    Pop-Location
    
    if ($success) {
        Write-Success "$TargetName build successful"
        return $true
    } else {
        Write-Error "$TargetName build failed"
        return $false
    }
}

# Copy binary files
function Copy-Binary {
    param([string]$Target, [string]$TargetName, [string]$BinaryName)
    
    Write-Info "Copying $TargetName binary..."
    
    $sourcePath = "$ProjectDir\target\$Target\release\$BinaryName"
    $destDir = "$BuildDir\$TargetName"
    
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destDir
        Write-Success "$TargetName binary copied"
        return $true
    } else {
        Write-Error "$TargetName binary not found: $sourcePath"
        return $false
    }
}

# Create install script
function New-InstallScript {
    param([string]$TempDir)
    
    $installContent = @"
@echo off
setlocal

echo MDDE Installer
echo ==============

set INSTALL_DIR=%ProgramFiles%\MDDE
set BINARY_NAME=mdde.exe

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Error: Administrator privileges required
    echo Please run as administrator
    pause
    exit /b 1
)

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Installing %BINARY_NAME% to %INSTALL_DIR%...
copy /Y "%BINARY_NAME%" "%INSTALL_DIR%\"

echo Adding to system PATH...
setx /M PATH "%PATH%;%INSTALL_DIR%"

echo.
echo Installation completed!
echo Please restart command prompt and run 'mdde --help'
pause
"@

    $installContent | Out-File -FilePath "$TempDir\install.bat" -Encoding ASCII
}

# Create package
function New-Package {
    param([string]$TargetName, [string]$BinaryName)
    
    Write-Info "Creating $TargetName package..."
    
    if (-not (Test-Path $PackageDir)) {
        New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
    }
    
    $sourceDir = "$BuildDir\$TargetName"
    $packageName = "$ProjectName-$TargetName-v$Version"
    $tempDir = "$env:TEMP\$packageName"
    
    # Create temp directory
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Copy files
    $targetBinary = if ($BinaryName.EndsWith('.exe')) { "$ProjectName.exe" } else { $ProjectName }
    Copy-Item "$sourceDir\$BinaryName" "$tempDir\$targetBinary"
    
    if (Test-Path "README.md") { Copy-Item "README.md" $tempDir }
    if (Test-Path "README_EN.md") { Copy-Item "README_EN.md" $tempDir }
    if (Test-Path "LICENSE") { Copy-Item "LICENSE" $tempDir }
    
    # Create install script for Windows
    if ($BinaryName.EndsWith('.exe')) {
        New-InstallScript $tempDir
    }
    
    # Create archive
    $archivePath = "$PackageDir\$packageName.zip"
    Compress-Archive -Path "$tempDir\*" -DestinationPath $archivePath -Force
    
    # Cleanup
    Remove-Item -Recurse -Force $tempDir
    
    Write-Success "$TargetName package created: $archivePath"
}

# Build all platforms
function Build-All {
    Write-Info "Starting multi-platform build..."
    
    if (-not (Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
    }
    
    # Windows x64
    if (Build-Target "x86_64-pc-windows-msvc" "windows-x64") {
        if (Copy-Binary "x86_64-pc-windows-msvc" "windows-x64" "mdde.exe") {
            New-Package "windows-x64" "mdde.exe"
        }
    }
    
    # Try Linux cross-compilation
    try {
        if (Build-Target "x86_64-unknown-linux-gnu" "linux-x64") {
            if (Copy-Binary "x86_64-unknown-linux-gnu" "linux-x64" "mdde") {
                New-Package "linux-x64" "mdde"
            }
        }
    } catch {
        Write-Warning "Skipping Linux build (cross-compilation toolchain required)"
    }
    
    Write-Success "Build completed"
}

# Show results
function Show-Results {
    Write-Info "Build results:"
    Write-Host ""
    
    if (Test-Path $PackageDir) {
        Write-Host "Generated packages:"
        Get-ChildItem $PackageDir | Format-Table Name, Length, LastWriteTime
    }
    
    Write-Host ""
    Write-Host "Binary sizes:"
    if (Test-Path $BuildDir) {
        Get-ChildItem -Recurse $BuildDir -Filter "mdde*" | Format-Table Name, Length, Directory
    }
}

# Show help
function Show-Help {
    Write-Host "MDDE Build Script (Windows)"
    Write-Host "Usage: .\build.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Clean           Clean build directories"
    Write-Host "  -InstallTargets  Install compilation targets"
    Write-Host "  -Help           Show help information"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\build.ps1                # Build all platforms"
    Write-Host "  .\build.ps1 -Clean         # Clean build directories"
    Write-Host "  .\build.ps1 -InstallTargets # Install targets"
}

# Main function
function Main {
    Write-Host "MDDE Build Script (Windows)"
    Write-Host "=========================="
    Write-Host "Version: $Version"
    Write-Host ""
    
    if ($Help) {
        Show-Help
        return
    }
    
    if ($Clean) {
        Clear-Build
        return
    }
    
    if ($InstallTargets) {
        Install-Targets
        return
    }
    
    Test-Dependencies
    Install-Targets
    Build-All
    Show-Results
    
    Write-Success "Build process completed!"
}

# Run main function
Main

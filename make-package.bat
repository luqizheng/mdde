@echo off
setlocal

REM MDDE 包生成器统一入口 (Windows)
REM 自动调用合适的构建脚本

echo.
echo ╔════════════════════════════════════╗
echo ║       MDDE 包生成器入口            ║
echo ║     Package Generator Entry        ║
echo ╚════════════════════════════════════╝
echo.

echo [INFO] 检测到 Windows 操作系统

REM 检查PowerShell脚本是否存在
if exist "build.ps1" (
    echo [INFO] 使用 PowerShell 脚本进行构建...
    powershell.exe -ExecutionPolicy Bypass -File build.ps1 %*
) else (
    echo [ERROR] 未找到 build.ps1 脚本
    echo 请确保 build.ps1 文件存在于当前目录
    pause
    exit /b 1
)

echo.
echo [SUCCESS] 构建完成
pause

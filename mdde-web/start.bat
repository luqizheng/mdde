@echo off
chcp 65001 >nul
echo 🚀 启动 MDDE Web 服务器...
echo.

REM 检查Node.js是否安装
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未找到 Node.js，请先安装 Node.js
    echo 下载地址: https://nodejs.org/
    pause
    exit /b 1
)

REM 检查npm是否可用
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ npm 不可用
    pause
    exit /b 1
)

REM 显示版本信息
for /f "tokens=*" %%i in ('node --version') do echo ✅ Node.js 版本: %%i
for /f "tokens=*" %%i in ('npm --version') do echo ✅ npm 版本: %%i
echo.

REM 检查依赖是否已安装
if not exist "node_modules" (
    echo 📦 安装依赖...
    npm install
    if %errorlevel% neq 0 (
        echo ❌ 依赖安装失败
        pause
        exit /b 1
    )
    echo ✅ 依赖安装完成
    echo.
)

REM 启动服务器
echo 🌐 启动 Web 服务器...
echo 📁 脚本目录: %CD%\scripts
echo 🌐 访问地址: http://localhost:3000
echo 🔧 管理界面: http://localhost:3000/admin.html
echo.
echo 按 Ctrl+C 停止服务器
echo.

npm start
pause

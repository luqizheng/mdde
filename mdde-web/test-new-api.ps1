# MDDE Web 服务器新API测试脚本
# 测试 /get/:dirName/:filename 端点

$BaseUrl = "http://localhost:3000"
$TestDir = "dotnet9"
$TestFile = "example.ps1"

Write-Host "🚀 测试 MDDE Web 服务器新API端点" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# 1. 测试健康检查
Write-Host "`n1. 测试健康检查..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get
    Write-Host "✅ 健康检查通过: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ 健康检查失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. 测试获取脚本列表
Write-Host "`n2. 测试获取脚本列表..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/list" -Method Get
    Write-Host "✅ 获取脚本列表成功" -ForegroundColor Green
    Write-Host "   可用目录: $($response.directories.Count)" -ForegroundColor Cyan
    foreach ($dir in $response.directories) {
        Write-Host "   - $($dir.name): $($dir.scripts.Count) 个脚本" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ 获取脚本列表失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 测试获取特定目录的脚本列表
Write-Host "`n3. 测试获取 $TestDir 目录的脚本列表..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/list/$TestDir" -Method Get
    Write-Host "✅ 获取 $TestDir 目录脚本列表成功" -ForegroundColor Green
    Write-Host "   脚本数量: $($response.scripts.Count)" -ForegroundColor Cyan
    foreach ($script in $response.scripts) {
        Write-Host "   - $script" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ 获取 $TestDir 目录脚本列表失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 测试下载整个目录（ZIP）
Write-Host "`n4. 测试下载整个 $TestDir 目录..." -ForegroundColor Yellow
try {
    $zipPath = "$TestDir`_scripts.zip"
    Invoke-WebRequest -Uri "$BaseUrl/get/$TestDir" -OutFile $zipPath
    if (Test-Path $zipPath) {
        $fileSize = (Get-Item $zipPath).Length
        Write-Host "✅ 下载目录成功: $zipPath ($(Format-FileSize $fileSize))" -ForegroundColor Green
        Remove-Item $zipPath -Force
    } else {
        Write-Host "❌ 下载目录失败: 文件未创建" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 下载目录失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 测试下载特定文件
Write-Host "`n5. 测试下载特定文件 $TestFile..." -ForegroundColor Yellow
try {
    $filePath = "$TestDir`_$TestFile"
    Invoke-WebRequest -Uri "$BaseUrl/get/$TestDir/$TestFile" -OutFile $filePath
    if (Test-Path $filePath) {
        $fileSize = (Get-Item $filePath).Length
        Write-Host "✅ 下载文件成功: $filePath ($(Format-FileSize $fileSize))" -ForegroundColor Green
        
        # 显示文件内容的前几行
        $content = Get-Content $filePath -Head 3
        Write-Host "   文件内容预览:" -ForegroundColor Cyan
        foreach ($line in $content) {
            Write-Host "   $line" -ForegroundColor Gray
        }
        
        Remove-Item $filePath -Force
    } else {
        Write-Host "❌ 下载文件失败: 文件未创建" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 下载文件失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 测试下载不存在的文件
Write-Host "`n6. 测试下载不存在的文件..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/get/$TestDir/nonexistent.txt" -Method Get
    Write-Host "❌ 应该返回404错误" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "✅ 正确处理404错误: 文件不存在" -ForegroundColor Green
    } else {
        Write-Host "❌ 意外的错误状态: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

# 7. 测试下载不存在的目录
Write-Host "`n7. 测试下载不存在的目录..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/get/nonexistent/test.txt" -Method Get
    Write-Host "❌ 应该返回404错误" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "✅ 正确处理404错误: 目录不存在" -ForegroundColor Green
    } else {
        Write-Host "❌ 意外的错误状态: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

Write-Host "`n🎉 新API测试完成！" -ForegroundColor Green
Write-Host "`n📋 API端点总结:" -ForegroundColor Cyan
Write-Host "  GET /get/{dirName}           - 下载整个目录（ZIP格式）" -ForegroundColor White
Write-Host "  GET /get/{dirName}/{filename} - 下载指定文件" -ForegroundColor White
Write-Host "  POST /upload/{dirName}       - 上传文件到指定目录" -ForegroundColor White
Write-Host "  GET /list                    - 获取所有目录列表" -ForegroundColor White
Write-Host "  GET /list/{dirName}          - 获取指定目录的文件列表" -ForegroundColor White
Write-Host "  DELETE /delete/{dirName}/{fileName} - 删除指定文件" -ForegroundColor White

# 辅助函数：格式化文件大小
function Format-FileSize {
    param([long]$Bytes)
    
    if ($Bytes -lt 1KB) { return "$Bytes B" }
    elseif ($Bytes -lt 1MB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    elseif ($Bytes -lt 1GB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    else { return "{0:N1} GB" -f ($Bytes / 1GB) }
}

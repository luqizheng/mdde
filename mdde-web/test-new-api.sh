#!/bin/bash

# MDDE Web 服务器新API测试脚本
# 测试 /get/:dirName/:filename 端点

BASE_URL="http://localhost:3000"
TEST_DIR="dotnet9"
TEST_FILE="example.ps1"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 测试 MDDE Web 服务器新API端点${NC}"
echo -e "${GREEN}=====================================${NC}"

# 1. 测试健康检查
echo -e "\n${YELLOW}1. 测试健康检查...${NC}"
if response=$(curl -s "$BASE_URL/health" 2>/dev/null); then
    status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}✅ 健康检查通过: $status${NC}"
else
    echo -e "${RED}❌ 健康检查失败${NC}"
fi

# 2. 测试获取脚本列表
echo -e "\n${YELLOW}2. 测试获取脚本列表...${NC}"
if response=$(curl -s "$BASE_URL/list" 2>/dev/null); then
    echo -e "${GREEN}✅ 获取脚本列表成功${NC}"
    dir_count=$(echo "$response" | grep -o '"name":"[^"]*"' | wc -l)
    echo -e "${CYAN}   可用目录: $dir_count${NC}"
    
    # 显示目录信息
    echo "$response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | while read -r dir; do
        script_count=$(echo "$response" | grep -A 10 "\"name\":\"$dir\"" | grep -o '"scripts":\[[^]]*\]' | grep -o '"[^"]*"' | wc -l)
        echo -e "${CYAN}   - $dir: $script_count 个脚本${NC}"
    done
else
    echo -e "${RED}❌ 获取脚本列表失败${NC}"
fi

# 3. 测试获取特定目录的脚本列表
echo -e "\n${YELLOW}3. 测试获取 $TEST_DIR 目录的脚本列表...${NC}"
if response=$(curl -s "$BASE_URL/list/$TEST_DIR" 2>/dev/null); then
    echo -e "${GREEN}✅ 获取 $TEST_DIR 目录脚本列表成功${NC}"
    script_count=$(echo "$response" | grep -o '"scripts":\[[^]]*\]' | grep -o '"[^"]*"' | wc -l)
    echo -e "${CYAN}   脚本数量: $script_count${NC}"
    
    # 显示脚本列表
    echo "$response" | grep -o '"scripts":\[[^]]*\]' | grep -o '"[^"]*"' | while read -r script; do
        echo -e "${CYAN}   - $script${NC}"
    done
else
    echo -e "${RED}❌ 获取 $TEST_DIR 目录脚本列表失败${NC}"
fi

# 4. 测试下载整个目录（ZIP）
echo -e "\n${YELLOW}4. 测试下载整个 $TEST_DIR 目录...${NC}"
zip_path="${TEST_DIR}_scripts.zip"
if curl -s -o "$zip_path" "$BASE_URL/get/$TEST_DIR"; then
    if [ -f "$zip_path" ]; then
        file_size=$(stat -c%s "$zip_path" 2>/dev/null || stat -f%z "$zip_path" 2>/dev/null)
        echo -e "${GREEN}✅ 下载目录成功: $zip_path ($(format_file_size $file_size))${NC}"
        rm -f "$zip_path"
    else
        echo -e "${RED}❌ 下载目录失败: 文件未创建${NC}"
    fi
else
    echo -e "${RED}❌ 下载目录失败${NC}"
fi

# 5. 测试下载特定文件
echo -e "\n${YELLOW}5. 测试下载特定文件 $TEST_FILE...${NC}"
file_path="${TEST_DIR}_${TEST_FILE}"
if curl -s -o "$file_path" "$BASE_URL/get/$TEST_DIR/$TEST_FILE"; then
    if [ -f "$file_path" ]; then
        file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null)
        echo -e "${GREEN}✅ 下载文件成功: $file_path ($(format_file_size $file_size))${NC}"
        
        # 显示文件内容的前几行
        echo -e "${CYAN}   文件内容预览:${NC}"
        head -3 "$file_path" | while read -r line; do
            echo -e "${GRAY}   $line${NC}"
        done
        
        rm -f "$file_path"
    else
        echo -e "${RED}❌ 下载文件失败: 文件未创建${NC}"
    fi
else
    echo -e "${RED}❌ 下载文件失败${NC}"
fi

# 6. 测试下载不存在的文件
echo -e "\n${YELLOW}6. 测试下载不存在的文件...${NC}"
if response=$(curl -s -w "%{http_code}" "$BASE_URL/get/$TEST_DIR/nonexistent.txt" -o /dev/null 2>/dev/null); then
    if [ "$response" = "404" ]; then
        echo -e "${GREEN}✅ 正确处理404错误: 文件不存在${NC}"
    else
        echo -e "${RED}❌ 意外的错误状态: $response${NC}"
    fi
else
    echo -e "${RED}❌ 测试失败${NC}"
fi

# 7. 测试下载不存在的目录
echo -e "\n${YELLOW}7. 测试下载不存在的目录...${NC}"
if response=$(curl -s -w "%{http_code}" "$BASE_URL/get/nonexistent/test.txt" -o /dev/null 2>/dev/null); then
    if [ "$response" = "404" ]; then
        echo -e "${GREEN}✅ 正确处理404错误: 目录不存在${NC}"
    else
        echo -e "${RED}❌ 意外的错误状态: $response${NC}"
    fi
else
    echo -e "${RED}❌ 测试失败${NC}"
fi

echo -e "\n${GREEN}🎉 新API测试完成！${NC}"
echo -e "\n${CYAN}📋 API端点总结:${NC}"
echo -e "${WHITE}  GET /get/{dirName}           - 下载整个目录（ZIP格式）${NC}"
echo -e "${WHITE}  GET /get/{dirName}/{filename} - 下载指定文件${NC}"
echo -e "${WHITE}  POST /upload/{dirName}       - 上传文件到指定目录${NC}"
echo -e "${WHITE}  GET /list                    - 获取所有目录列表${NC}"
echo -e "${WHITE}  GET /list/{dirName}          - 获取指定目录的文件列表${NC}"
echo -e "${WHITE}  DELETE /delete/{dirName}/{fileName} - 删除指定文件${NC}"

# 辅助函数：格式化文件大小
format_file_size() {
    local bytes=$1
    local kb=1024
    local mb=$((kb * 1024))
    local gb=$((mb * 1024))
    
    if [ $bytes -lt $kb ]; then
        echo "${bytes} B"
    elif [ $bytes -lt $mb ]; then
        echo "$(echo "scale=1; $bytes / $kb" | bc) KB"
    elif [ $bytes -lt $gb ]; then
        echo "$(echo "scale=1; $bytes / $mb" | bc) MB"
    else
        echo "$(echo "scale=1; $bytes / $gb" | bc) GB"
    fi
}

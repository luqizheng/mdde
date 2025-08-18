#!/bin/bash
# MDDE 跨平台构建和安装包生成脚本 (Bash)
# 支持 Windows/Linux/macOS 构建和 Windows 安装包生成

set -euo pipefail

# 默认配置
HELP=false
CLEAN=false
SKIP_BUILD=false
SKIP_INSTALLER=false
VERBOSE=false
OUTPUT_DIR="release-builds"
DOCKER_IMAGE="luqizheng/mdde-cmd-building-env:latest"
VERSION="0.1.0"
INNO_SETUP_PATH=""

# 颜色输出函数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${CYAN}ℹ️ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${GREEN}$1${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
$(log_header "MDDE 跨平台构建和安装包生成脚本")
$(log_header "=====================================")

用法: ./build-installer.sh [选项]

选项:
  -h, --help           显示此帮助信息
  -c, --clean          清理构建文件和输出目录
  -s, --skip-build     跳过 Docker 编译步骤
  -i, --skip-installer 跳过 Windows 安装包生成
  -v, --verbose        显示详细输出
  -o, --output DIR     指定输出目录 (默认: release-builds)
  -d, --docker IMAGE   指定 Docker 镜像 (默认: luqizheng/mdde-cmd-building-env:latest)
  --version VERSION    指定版本号 (默认: 0.1.0)

示例:
  ./build-installer.sh                       # 完整构建所有平台
  ./build-installer.sh --clean               # 清理构建文件
  ./build-installer.sh --skip-build          # 只生成安装包
  ./build-installer.sh --skip-installer      # 只编译不生成安装包
  ./build-installer.sh --verbose             # 显示详细日志

支持平台:
  - Windows x64 (with installer)
  - Linux x64
  - macOS Intel x64
  - macOS Apple Silicon (ARM64)

EOF
    exit 0
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                HELP=true
                shift
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -s|--skip-build)
                SKIP_BUILD=true
                shift
                ;;
            -i|--skip-installer)
                SKIP_INSTALLER=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -d|--docker)
                DOCKER_IMAGE="$2"
                shift 2
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                log_info "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
}

# 检查必需的工具
check_prerequisites() {
    log_info "检查构建环境..."
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装或不在 PATH 中"
        log_info "请安装 Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # 检查 Docker 服务
    if ! docker version &> /dev/null; then
        log_error "Docker 服务未运行"
        log_info "请启动 Docker 服务"
        exit 1
    fi
    
    log_success "Docker 环境正常"
    
    # 检查 wine (用于在 Linux/macOS 上运行 Inno Setup)
    if [[ "$SKIP_INSTALLER" == "false" ]]; then
        if command -v wine &> /dev/null; then
            log_success "Wine 找到，可以生成 Windows 安装包"
            INNO_SETUP_PATH="wine"
        else
            log_warning "Wine 未找到，将跳过 Windows 安装包生成"
            log_info "在 Linux/macOS 上生成 Windows 安装包需要 Wine"
            SKIP_INSTALLER=true
        fi
    fi
}

# 清理构建文件
clean_build_files() {
    log_info "清理构建文件..."
    
    local clean_dirs=("$OUTPUT_DIR" "mdde-cmd/target" "mdde-cmd/installer/output")
    
    for dir in "${clean_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "删除目录: $dir"
            rm -rf "$dir"
        fi
    done
    
    log_success "清理完成"
}

# 创建输出目录结构
create_output_directories() {
    log_info "创建输出目录结构..."
    
    local dirs=(
        "$OUTPUT_DIR"
        "$OUTPUT_DIR/windows-x64"
        "$OUTPUT_DIR/linux-x64"
        "$OUTPUT_DIR/macos-x64"
        "$OUTPUT_DIR/macos-arm64"
        "$OUTPUT_DIR/installers"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            [[ "$VERBOSE" == "true" ]] && log_info "创建目录: $dir"
        fi
    done
    
    log_success "输出目录结构已创建"
}

# 拉取 Docker 镜像
pull_docker_image() {
    log_info "拉取 Docker 镜像: $DOCKER_IMAGE"
    
    if [[ "$VERBOSE" == "true" ]]; then
        docker pull "$DOCKER_IMAGE"
    else
        docker pull "$DOCKER_IMAGE" &> /dev/null
    fi
    
    log_success "Docker 镜像拉取成功"
}

# 跨平台编译
build_cross_platform() {
    log_info "开始跨平台编译..."
    
    local current_dir=$(pwd)
    
    # 定义编译目标
    declare -A targets=(
        ["Windows x64"]="x86_64-pc-windows-msvc:.exe:windows-x64"
        ["Linux x64"]="x86_64-unknown-linux-gnu::linux-x64"
        ["macOS Intel"]="x86_64-apple-darwin::macos-x64"
        ["macOS ARM64"]="aarch64-apple-darwin::macos-arm64"
    )
    
    for name in "${!targets[@]}"; do
        IFS=':' read -ra target_info <<< "${targets[$name]}"
        local target="${target_info[0]}"
        local extension="${target_info[1]}"
        local output_dir="${target_info[2]}"
        
        log_info "编译 $name ($target)..."
        
        local docker_cmd=(
            docker run --rm
            -v "$current_dir:/workspace"
            -w "/workspace/mdde-cmd"
            "$DOCKER_IMAGE"
            cargo build --release --target "$target"
        )
        
        if [[ "$VERBOSE" == "true" ]]; then
            "${docker_cmd[@]}"
        else
            "${docker_cmd[@]}" &> /dev/null
        fi
        
        # 复制编译结果
        local source_path="mdde-cmd/target/$target/release/mdde$extension"
        local dest_path="$OUTPUT_DIR/$output_dir/mdde$extension"
        
        if [[ -f "$source_path" ]]; then
            cp "$source_path" "$dest_path"
            log_success "$name 编译完成: $dest_path"
        else
            log_warning "$name 编译产物未找到: $source_path"
        fi
    done
}

# 生成文件信息
generate_build_info() {
    log_info "生成构建信息文件..."
    
    local build_time=$(date '+%Y-%m-%d %H:%M:%S')
    local build_info_file="$OUTPUT_DIR/build-info.json"
    
    cat > "$build_info_file" << EOF
{
  "version": "$VERSION",
  "buildTime": "$build_time",
  "dockerImage": "$DOCKER_IMAGE",
  "platforms": [
    "Windows x64",
    "Linux x64",
    "macOS Intel x64",
    "macOS Apple Silicon ARM64"
  ],
  "files": [
EOF
    
    # 收集生成的文件信息
    local first_file=true
    find "$OUTPUT_DIR" -type f -not -name "build-info.json" | while read -r file; do
        local relative_path="${file#$PWD/}"
        local size_mb=$(echo "scale=2; $(stat -c%s "$file") / 1024 / 1024" | bc -l 2>/dev/null || echo "0")
        local file_hash=$(sha256sum "$file" | cut -d' ' -f1)
        local filename=$(basename "$file")
        
        if [[ "$first_file" == "true" ]]; then
            first_file=false
        else
            echo "," >> "$build_info_file"
        fi
        
        cat >> "$build_info_file" << EOF
    {
      "name": "$filename",
      "path": "$relative_path",
      "size": $size_mb,
      "hash": "$file_hash"
    }
EOF
    done
    
    cat >> "$build_info_file" << EOF
  ]
}
EOF
    
    log_success "构建信息已保存到: $build_info_file"
}

# 生成 Windows 安装包 (使用 Wine)
create_windows_installer() {
    if [[ "$SKIP_INSTALLER" == "true" ]]; then
        log_info "跳过 Windows 安装包生成"
        return
    fi
    
    log_info "生成 Windows 安装包..."
    
    # 确保 Windows 可执行文件存在
    local windows_exe="$OUTPUT_DIR/windows-x64/mdde.exe"
    if [[ ! -f "$windows_exe" ]]; then
        log_warning "Windows 可执行文件不存在，跳过安装包生成"
        return
    fi
    
    # 复制 Windows 可执行文件到目标位置
    local target_exe="mdde-cmd/target/release/mdde.exe"
    local target_dir=$(dirname "$target_exe")
    mkdir -p "$target_dir"
    cp "$windows_exe" "$target_exe"
    
    # 检查 Inno Setup 脚本
    local inno_script="mdde-cmd/installer/mdde-setup.iss"
    if [[ ! -f "$inno_script" ]]; then
        log_warning "Inno Setup 脚本不存在: $inno_script"
        return
    fi
    
    # 使用 Docker 运行 Windows 环境来生成安装包
    log_info "使用 Docker 运行 Windows 环境生成安装包..."
    
    local docker_cmd=(
        docker run --rm
        -v "$(pwd):/workspace"
        -w "/workspace"
        amake/innosetup:latest
        mdde-cmd/installer/mdde-setup.iss
    )
    
    if command -v docker &> /dev/null; then
        if [[ "$VERBOSE" == "true" ]]; then
            "${docker_cmd[@]}"
        else
            "${docker_cmd[@]}" &> /dev/null
        fi
        
        # 复制安装包到输出目录
        local inno_output_dir="mdde-cmd/installer/output"
        if [[ -d "$inno_output_dir" ]]; then
            find "$inno_output_dir" -name "*.exe" -type f | while read -r installer; do
                local dest_path="$OUTPUT_DIR/installers/$(basename "$installer")"
                cp "$installer" "$dest_path"
                log_success "Windows 安装包已生成: $dest_path"
            done
        else
            log_warning "安装包输出目录不存在: $inno_output_dir"
        fi
    else
        log_warning "Docker 不可用，跳过安装包生成"
    fi
}

# 显示构建结果摘要
show_build_summary() {
    echo
    log_header "🎉 构建完成摘要"
    log_header "================="
    
    if [[ -f "$OUTPUT_DIR/build-info.json" ]]; then
        local version=$(jq -r '.version' "$OUTPUT_DIR/build-info.json" 2>/dev/null || echo "$VERSION")
        local build_time=$(jq -r '.buildTime' "$OUTPUT_DIR/build-info.json" 2>/dev/null || echo "N/A")
        local docker_image=$(jq -r '.dockerImage' "$OUTPUT_DIR/build-info.json" 2>/dev/null || echo "$DOCKER_IMAGE")
        
        log_info "版本: $version"
        log_info "构建时间: $build_time"
        log_info "Docker 镜像: $docker_image"
        echo
        echo -e "${NC}生成的文件:"
        
        if command -v jq &> /dev/null; then
            jq -r '.files[] | "  📁 \(.path) (\(.size) MB)"' "$OUTPUT_DIR/build-info.json" 2>/dev/null || true
        else
            find "$OUTPUT_DIR" -type f -not -name "build-info.json" | while read -r file; do
                local relative_path="${file#$PWD/}"
                echo -e "  📁 $relative_path"
            done
        fi
    fi
    
    echo
    echo -e "${CYAN}输出目录: $OUTPUT_DIR${NC}"
    echo -e "${GRAY}使用 'tree $OUTPUT_DIR' 查看完整目录结构${NC}"
}

# 主函数
main() {
    log_header "🚀 MDDE 跨平台构建脚本"
    log_header "======================"
    
    parse_args "$@"
    
    if [[ "$HELP" == "true" ]]; then
        show_help
    fi
    
    if [[ "$CLEAN" == "true" ]]; then
        clean_build_files
        log_success "清理完成"
        exit 0
    fi
    
    # 检查环境
    check_prerequisites
    
    # 创建输出目录
    create_output_directories
    
    if [[ "$SKIP_BUILD" == "false" ]]; then
        # 拉取 Docker 镜像
        pull_docker_image
        
        # 跨平台编译
        build_cross_platform
    fi
    
    # 生成 Windows 安装包
    create_windows_installer
    
    # 生成构建信息
    generate_build_info
    
    # 显示摘要
    show_build_summary
    
    log_success "所有任务完成! 🎉"
}

# 错误处理
trap 'log_error "脚本执行出错，退出码: $?"; exit 1' ERR

# 执行主函数
main "$@"

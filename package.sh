#!/bin/bash

# MDDE 安装包生成脚本
# 跨平台构建和打包工具

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目配置
PROJECT_NAME="mdde"
PROJECT_DIR="mdde-cmd"
BUILD_DIR="release-builds"
PACKAGE_DIR="packages"
INSTALLER_DIR="installer"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║         MDDE 安装包生成器            ║"
    echo "║   Multi-platform Package Builder    ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="Linux";;
        Darwin*)    OS="MacOS";;
        CYGWIN*)    OS="Windows";;
        MINGW*)     OS="Windows";;
        *)          OS="Unknown";;
    esac
    log_info "检测到操作系统: $OS"
}

# 检查构建环境
check_environment() {
    log_step "检查构建环境..."
    
    # 检查 Rust
    if ! command -v cargo &> /dev/null; then
        log_error "未找到 Cargo，请安装 Rust 工具链"
        echo "安装方法: https://rustup.rs/"
        exit 1
    fi
    
    # 检查 Docker (可选，用于交叉编译)
    if command -v docker &> /dev/null; then
        log_info "发现 Docker，可用于交叉编译"
        DOCKER_AVAILABLE=true
    else
        log_warning "未发现 Docker，部分交叉编译功能不可用"
        DOCKER_AVAILABLE=false
    fi
    
    # 检查其他工具
    local tools=("tar" "zip" "git")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_info "✓ $tool 可用"
        else
            log_warning "✗ $tool 不可用"
        fi
    done
    
    log_success "环境检查完成"
}

# 获取项目版本
get_version() {
    if [[ -f "${PROJECT_DIR}/Cargo.toml" ]]; then
        VERSION=$(grep '^version' "${PROJECT_DIR}/Cargo.toml" | head -1 | sed 's/.*"\(.*\)".*/\1/')
        log_info "项目版本: v${VERSION}"
    else
        log_error "未找到 ${PROJECT_DIR}/Cargo.toml"
        exit 1
    fi
}

# 安装构建目标
install_rust_targets() {
    log_step "安装 Rust 构建目标..."
    
    local targets=(
        "x86_64-unknown-linux-gnu"
        "x86_64-pc-windows-msvc"
        "x86_64-apple-darwin"
        "aarch64-apple-darwin"
    )
    
    for target in "${targets[@]}"; do
        log_info "安装目标: $target"
        rustup target add "$target" || log_warning "无法安装目标: $target"
    done
    
    log_success "Rust 目标安装完成"
}

# 清理构建目录
clean_builds() {
    log_step "清理构建目录..."
    
    cd "${PROJECT_DIR}"
    cargo clean
    cd ..
    
    rm -rf "${BUILD_DIR}" "${PACKAGE_DIR}"
    mkdir -p "${BUILD_DIR}" "${PACKAGE_DIR}"
    
    log_success "构建目录清理完成"
}

# 构建单个目标
build_single_target() {
    local target=$1
    local target_name=$2
    
    log_step "构建 ${target_name} (${target})..."
    
    cd "${PROJECT_DIR}"
    
    if cargo build --release --target "${target}"; then
        log_success "${target_name} 构建成功"
        cd ..
        return 0
    else
        log_error "${target_name} 构建失败"
        cd ..
        return 1
    fi
}

# 使用 Docker 交叉编译
build_with_docker() {
    local target=$1
    local target_name=$2
    
    if [[ "$DOCKER_AVAILABLE" != "true" ]]; then
        log_warning "Docker 不可用，跳过 ${target_name}"
        return 1
    fi
    
    log_step "使用 Docker 构建 ${target_name}..."
    
    # 这里可以添加 Docker 交叉编译逻辑
    # 例如使用 cross 工具
    if command -v cross &> /dev/null; then
        cd "${PROJECT_DIR}"
        if cross build --release --target "${target}"; then
            log_success "Docker 构建 ${target_name} 成功"
            cd ..
            return 0
        else
            log_error "Docker 构建 ${target_name} 失败"
            cd ..
            return 1
        fi
    else
        log_warning "未安装 cross 工具，无法使用 Docker 交叉编译"
        return 1
    fi
}

# 复制并重命名二进制文件
prepare_binary() {
    local target=$1
    local target_name=$2
    local binary_name=$3
    local output_name=$4
    
    local source="${PROJECT_DIR}/target/${target}/release/${binary_name}"
    local dest_dir="${BUILD_DIR}/${target_name}"
    local dest="${dest_dir}/${output_name}"
    
    mkdir -p "${dest_dir}"
    
    if [[ -f "$source" ]]; then
        cp "$source" "$dest"
        chmod +x "$dest"
        log_success "二进制文件准备完成: ${dest}"
        return 0
    else
        log_error "二进制文件未找到: ${source}"
        return 1
    fi
}

# 创建安装脚本
create_install_scripts() {
    local dest_dir=$1
    local is_windows=$2
    
    if [[ "$is_windows" == "true" ]]; then
        # Windows 批处理安装脚本
        cat > "${dest_dir}/install.bat" << 'EOF'
@echo off
setlocal enabledelayedexpansion

echo MDDE 安装程序
echo =============

set "INSTALL_DIR=%ProgramFiles%\MDDE"
set "BINARY_NAME=mdde.exe"

REM 检查管理员权限
net session >nul 2>&1
if !errorLevel! neq 0 (
    echo 警告: 需要管理员权限安装到系统目录
    echo 将安装到用户目录...
    set "INSTALL_DIR=%USERPROFILE%\.local\bin"
    if not exist "!INSTALL_DIR!" mkdir "!INSTALL_DIR!"
) else (
    if not exist "!INSTALL_DIR!" mkdir "!INSTALL_DIR!"
)

echo 安装 !BINARY_NAME! 到 !INSTALL_DIR!...
copy /Y "!BINARY_NAME!" "!INSTALL_DIR!\"

echo 添加到 PATH...
if "!INSTALL_DIR!"=="%ProgramFiles%\MDDE" (
    setx /M PATH "%PATH%;!INSTALL_DIR!"
) else (
    setx PATH "%PATH%;!INSTALL_DIR!"
)

echo.
echo 安装完成！
echo 请重新打开命令提示符，然后运行 'mdde --help' 开始使用
pause
EOF
    else
        # Unix 安装脚本
        cat > "${dest_dir}/install.sh" << 'EOF'
#!/bin/bash

echo "MDDE 安装程序"
echo "============="

BINARY_NAME="mdde"
INSTALL_DIR="/usr/local/bin"

# 检查是否有写权限
if [[ ! -w "$INSTALL_DIR" ]]; then
    echo "警告: 无权限写入 $INSTALL_DIR"
    echo "尝试安装到用户目录..."
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
fi

echo "安装 $BINARY_NAME 到 $INSTALL_DIR..."
cp "$BINARY_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

# 检查 PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "警告: $INSTALL_DIR 不在 PATH 中"
    echo "请将以下行添加到您的 shell 配置文件:"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\""
fi

echo ""
echo "安装完成！"
echo "运行 'mdde --help' 开始使用"
EOF
        chmod +x "${dest_dir}/install.sh"
    fi
}

# 创建压缩包
create_package() {
    local target_name=$1
    local is_windows=$2
    
    log_step "创建 ${target_name} 安装包..."
    
    local source_dir="${BUILD_DIR}/${target_name}"
    local package_name="${PROJECT_NAME}-${target_name}-v${VERSION}"
    local temp_dir="/tmp/${package_name}"
    
    # 创建临时打包目录
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    
    # 复制文件
    if [[ "$is_windows" == "true" ]]; then
        cp "${source_dir}/mdde.exe" "${temp_dir}/"
    else
        cp "${source_dir}/mdde" "${temp_dir}/"
    fi
    
    cp README.md README_EN.md LICENSE "${temp_dir}/"
    
    # 创建安装脚本
    create_install_scripts "$temp_dir" "$is_windows"
    
    # 创建 CHANGELOG
    if [[ -f CHANGELOG.md ]]; then
        cp CHANGELOG.md "${temp_dir}/"
    fi
    
    # 打包
    cd /tmp
    if [[ "$is_windows" == "true" ]] && command -v zip &> /dev/null; then
        zip -r "${package_name}.zip" "$package_name"
        mv "${package_name}.zip" "${OLDPWD}/${PACKAGE_DIR}/"
        log_success "ZIP 包创建完成: ${PACKAGE_DIR}/${package_name}.zip"
    else
        tar -czf "${package_name}.tar.gz" "$package_name"
        mv "${package_name}.tar.gz" "${OLDPWD}/${PACKAGE_DIR}/"
        log_success "TAR.GZ 包创建完成: ${PACKAGE_DIR}/${package_name}.tar.gz"
    fi
    
    # 清理
    rm -rf "$temp_dir"
    cd "$OLDPWD"
}

# 构建所有平台
build_all_platforms() {
    log_step "开始多平台构建..."
    
    # 当前平台构建
    case "$OS" in
        "Linux")
            if build_single_target "x86_64-unknown-linux-gnu" "linux-x64"; then
                prepare_binary "x86_64-unknown-linux-gnu" "linux-x64" "mdde" "mdde"
                create_package "linux-x64" "false"
            fi
            
            # 尝试交叉编译 Windows
            if build_with_docker "x86_64-pc-windows-msvc" "windows-x64"; then
                prepare_binary "x86_64-pc-windows-msvc" "windows-x64" "mdde.exe" "mdde.exe"
                create_package "windows-x64" "true"
            fi
            ;;
            
        "MacOS")
            # macOS Intel
            if build_single_target "x86_64-apple-darwin" "macos-x64"; then
                prepare_binary "x86_64-apple-darwin" "macos-x64" "mdde" "mdde"
                create_package "macos-x64" "false"
            fi
            
            # macOS Apple Silicon
            if build_single_target "aarch64-apple-darwin" "macos-arm64"; then
                prepare_binary "aarch64-apple-darwin" "macos-arm64" "mdde" "mdde"
                create_package "macos-arm64" "false"
            fi
            ;;
            
        *)
            log_warning "未知操作系统，尝试构建当前平台..."
            cd "${PROJECT_DIR}"
            cargo build --release
            cd ..
            ;;
    esac
}

# 生成校验和
generate_checksums() {
    log_step "生成校验和文件..."
    
    cd "${PACKAGE_DIR}"
    
    if command -v sha256sum &> /dev/null; then
        sha256sum *.{tar.gz,zip} 2>/dev/null > SHA256SUMS || true
    elif command -v shasum &> /dev/null; then
        shasum -a 256 *.{tar.gz,zip} 2>/dev/null > SHA256SUMS || true
    fi
    
    cd ..
    log_success "校验和文件生成完成"
}

# 显示构建结果
show_results() {
    log_step "构建结果汇总:"
    echo ""
    
    if [[ -d "$PACKAGE_DIR" ]]; then
        echo "生成的安装包:"
        ls -la "$PACKAGE_DIR"
        echo ""
        
        echo "文件大小统计:"
        du -h "$PACKAGE_DIR"/*
        echo ""
        
        if [[ -f "${PACKAGE_DIR}/SHA256SUMS" ]]; then
            echo "校验和:"
            cat "${PACKAGE_DIR}/SHA256SUMS"
        fi
    fi
}

# 显示使用说明
show_usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -c, --clean         清理构建目录"
    echo "  -t, --targets       安装构建目标"
    echo "  -b, --build-only    仅构建，不打包"
    echo "  -p, --package-only  仅打包已构建的文件"
    echo ""
    echo "示例:"
    echo "  $0                  # 完整构建和打包流程"
    echo "  $0 --clean          # 清理构建目录"
    echo "  $0 --build-only     # 仅构建二进制文件"
}

# 主函数
main() {
    show_banner
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                clean_builds
                log_success "清理完成"
                exit 0
                ;;
            -t|--targets)
                install_rust_targets
                exit 0
                ;;
            -b|--build-only)
                BUILD_ONLY=true
                ;;
            -p|--package-only)
                PACKAGE_ONLY=true
                ;;
            *)
                log_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
    
    detect_os
    check_environment
    get_version
    
    if [[ "$PACKAGE_ONLY" != "true" ]]; then
        install_rust_targets
        clean_builds
        build_all_platforms
    fi
    
    if [[ "$BUILD_ONLY" != "true" ]]; then
        generate_checksums
    fi
    
    show_results
    log_success "所有操作完成！"
}

# 运行主函数
main "$@"

#!/bin/bash

# MDDE 项目构建脚本
# 用于构建所有平台的二进制文件和生成安装包

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="mdde"
PROJECT_DIR="mdde-cmd"
VERSION=$(grep '^version' ${PROJECT_DIR}/Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/')
BUILD_DIR="release-builds"
PACKAGE_DIR="packages"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查构建依赖..."
    
    if ! command -v cargo &> /dev/null; then
        log_error "Rust/Cargo 未安装，请先安装 Rust"
        exit 1
    fi
    
    if ! command -v tar &> /dev/null; then
        log_error "tar 未安装"
        exit 1
    fi
    
    log_success "所有依赖检查通过"
}

# 安装目标平台
install_targets() {
    log_info "安装目标平台..."
    
    rustup target add x86_64-unknown-linux-gnu
    rustup target add x86_64-pc-windows-msvc
    rustup target add x86_64-apple-darwin
    rustup target add aarch64-apple-darwin
    
    log_success "目标平台安装完成"
}

# 清理构建目录
clean_build() {
    log_info "清理构建目录..."
    
    cd ${PROJECT_DIR}
    cargo clean
    cd ..
    
    rm -rf ${BUILD_DIR}
    rm -rf ${PACKAGE_DIR}
    
    log_success "构建目录清理完成"
}

# 构建指定平台
build_target() {
    local target=$1
    local target_name=$2
    
    log_info "构建 ${target_name} (${target})..."
    
    cd ${PROJECT_DIR}
    
    if cargo build --release --target ${target}; then
        log_success "${target_name} 构建成功"
    else
        log_error "${target_name} 构建失败"
        cd ..
        return 1
    fi
    
    cd ..
}

# 复制二进制文件
copy_binary() {
    local target=$1
    local target_name=$2
    local binary_name=$3
    
    log_info "复制 ${target_name} 二进制文件..."
    
    local source_path="${PROJECT_DIR}/target/${target}/release/${binary_name}"
    local dest_dir="${BUILD_DIR}/${target_name}"
    
    mkdir -p ${dest_dir}
    
    if [[ -f ${source_path} ]]; then
        cp ${source_path} ${dest_dir}/
        log_success "${target_name} 二进制文件复制完成"
    else
        log_error "${target_name} 二进制文件未找到: ${source_path}"
        return 1
    fi
}

# 创建压缩包
create_package() {
    local target_name=$1
    local binary_name=$2
    
    log_info "创建 ${target_name} 压缩包..."
    
    mkdir -p ${PACKAGE_DIR}
    
    local source_dir="${BUILD_DIR}/${target_name}"
    local package_name="${PROJECT_NAME}-${target_name}-v${VERSION}"
    
    # 创建临时目录
    local temp_dir="/tmp/${package_name}"
    mkdir -p ${temp_dir}
    
    # 复制文件
    cp ${source_dir}/${binary_name} ${temp_dir}/${PROJECT_NAME}
    cp README.md ${temp_dir}/
    cp README_EN.md ${temp_dir}/
    cp LICENSE ${temp_dir}/
    
    # 创建安装脚本
    create_install_script ${temp_dir} ${target_name}
    
    # 打包
    cd /tmp
    tar -czf "${package_name}.tar.gz" ${package_name}
    mv "${package_name}.tar.gz" ${OLDPWD}/${PACKAGE_DIR}/
    
    # 清理临时目录
    rm -rf ${temp_dir}
    
    cd ${OLDPWD}
    log_success "${target_name} 压缩包创建完成: ${PACKAGE_DIR}/${package_name}.tar.gz"
}

# 创建安装脚本
create_install_script() {
    local temp_dir=$1
    local target_name=$2
    
    cat > ${temp_dir}/install.sh << 'EOF'
#!/bin/bash

# MDDE 安装脚本

set -e

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="mdde"

echo "MDDE 安装程序"
echo "============="

# 检查权限
if [[ $EUID -ne 0 ]]; then
    echo "注意: 需要管理员权限安装到 ${INSTALL_DIR}"
    echo "如果没有权限，将安装到 ~/.local/bin"
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p ${INSTALL_DIR}
fi

# 复制二进制文件
echo "安装 ${BINARY_NAME} 到 ${INSTALL_DIR}..."
cp ${BINARY_NAME} ${INSTALL_DIR}/
chmod +x ${INSTALL_DIR}/${BINARY_NAME}

# 检查 PATH
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
    echo ""
    echo "警告: ${INSTALL_DIR} 不在 PATH 中"
    echo "请将以下行添加到您的 shell 配置文件 (~/.bashrc, ~/.zshrc 等):"
    echo "export PATH=\"${INSTALL_DIR}:\$PATH\""
fi

echo ""
echo "安装完成！"
echo "运行 'mdde --help' 开始使用"
EOF

    chmod +x ${temp_dir}/install.sh
}

# 构建所有平台
build_all() {
    log_info "开始构建所有平台版本..."
    
    mkdir -p ${BUILD_DIR}
    
    # Linux x64
    if build_target "x86_64-unknown-linux-gnu" "linux-x64"; then
        copy_binary "x86_64-unknown-linux-gnu" "linux-x64" "mdde"
        create_package "linux-x64" "mdde"
    fi
    
    # Windows x64 (如果支持交叉编译)
    if [[ $(uname) == "Linux" ]] && command -v x86_64-w64-mingw32-gcc &> /dev/null; then
        if build_target "x86_64-pc-windows-msvc" "windows-x64"; then
            copy_binary "x86_64-pc-windows-msvc" "windows-x64" "mdde.exe"
            create_package "windows-x64" "mdde.exe"
        fi
    else
        log_warning "跳过 Windows 构建 (需要交叉编译工具链)"
    fi
    
    # macOS (仅在 macOS 上构建)
    if [[ $(uname) == "Darwin" ]]; then
        # macOS Intel
        if build_target "x86_64-apple-darwin" "macos-x64"; then
            copy_binary "x86_64-apple-darwin" "macos-x64" "mdde"
            create_package "macos-x64" "mdde"
        fi
        
        # macOS Apple Silicon
        if build_target "aarch64-apple-darwin" "macos-arm64"; then
            copy_binary "aarch64-apple-darwin" "macos-arm64" "mdde"
            create_package "macos-arm64" "mdde"
        fi
    else
        log_warning "跳过 macOS 构建 (需要在 macOS 系统上构建)"
    fi
    
    log_success "所有平台构建完成"
}

# 显示构建结果
show_results() {
    log_info "构建结果:"
    echo ""
    
    if [[ -d ${PACKAGE_DIR} ]]; then
        echo "生成的安装包:"
        ls -la ${PACKAGE_DIR}/
    fi
    
    echo ""
    echo "文件大小统计:"
    if [[ -d ${BUILD_DIR} ]]; then
        find ${BUILD_DIR} -name "mdde*" -exec ls -lh {} \;
    fi
}

# 主函数
main() {
    echo "MDDE 构建脚本"
    echo "============="
    echo "版本: ${VERSION}"
    echo ""
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                clean_build
                exit 0
                ;;
            --install-targets)
                install_targets
                exit 0
                ;;
            --help)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --clean           清理构建目录"
                echo "  --install-targets 安装编译目标"
                echo "  --help           显示帮助信息"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    check_dependencies
    install_targets
    build_all
    show_results
    
    log_success "构建完成！"
}

# 运行主函数
main "$@"

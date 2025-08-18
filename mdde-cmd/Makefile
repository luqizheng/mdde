# MDDE Makefile
# 简化构建和开发流程

.PHONY: help build test clean install uninstall release debug check fmt clippy doc cross-build build-windows build-linux build-macos build-macos-arm install-targets check-all clean-cross

# 默认目标
help:
	@echo "MDDE 命令行工具构建系统"
	@echo "========================"
	@echo ""
	@echo "基础命令:"
	@echo "  build     - 构建项目 (debug)"
	@echo "  release   - 构建项目 (release)"
	@echo "  test      - 运行测试"
	@echo "  check     - 检查代码"
	@echo "  fmt       - 格式化代码"
	@echo "  clippy    - 运行 clippy 检查"
	@echo "  doc       - 生成文档"
	@echo "  clean     - 清理构建产物"
	@echo "  install   - 安装到系统"
	@echo "  uninstall - 从系统卸载"
	@echo ""
	@echo "跨平台编译:"
	@echo "  cross-build    - 编译所有平台版本"
	@echo "  build-windows  - 编译 Windows 版本"
	@echo "  build-linux    - 编译 Linux 版本"
	@echo "  build-macos    - 编译 macOS Intel 版本"
	@echo "  build-macos-arm- 编译 macOS Apple Silicon 版本"
	@echo "  install-targets- 安装所有编译目标"
	@echo "  check-all      - 检查所有平台编译"
	@echo "  clean-cross    - 清理跨平台构建产物"
	@echo ""
	@echo "工具命令:"
	@echo "  help      - 显示此帮助信息"

# 构建项目 (debug)
build:
	cargo build

# 构建项目 (release)
release:
	cargo build --release

# 运行测试
test:
	cargo test

# 检查代码
check:
	cargo check

# 格式化代码
fmt:
	cargo fmt

# 运行 clippy 检查
clippy:
	cargo clippy

# 生成文档
doc:
	cargo doc --open

# 清理构建产物
clean:
	cargo clean

# 安装到系统
install: release
	cargo install --path .

# 从系统卸载
uninstall:
	cargo uninstall mdde

# 快速构建和测试
all: check test build

# 发布前检查
prep: fmt clippy test check

# 显示项目信息
info:
	@echo "项目信息:"
	@echo "  名称: $(shell cargo get name)"
	@echo "  版本: $(shell cargo get version)"
	@echo "  描述: $(shell cargo get description)"
	@echo "  作者: $(shell cargo get authors)"
	@echo "  许可证: $(shell cargo get license)"

# 显示依赖信息
deps:
	cargo tree

# 更新依赖
update:
	cargo update

# 审计依赖安全性
audit:
	cargo audit

# 运行示例
example:
	cargo run --example basic_usage

# 性能分析 (需要安装 flamegraph)
flamegraph: release
	cargo flamegraph --bin mdde

# 覆盖率报告 (需要安装 grcov)
coverage:
	CARGO_INCREMENTAL=0 RUSTFLAGS='-Cinstrument-coverage' LLVM_PROFILE_FILE='cargo-test-%p-%m.profraw' cargo test
	grcov . --binary-path ./target/debug/ -s . -t html --branch --ignore-not-existing -o ./coverage/
	@echo "覆盖率报告已生成到 ./coverage/ 目录"

# 跨平台编译目标
cross-build: prep
	@echo "开始跨平台编译..."
ifeq ($(OS),Windows_NT)
	powershell -ExecutionPolicy Bypass -File ./build-cross-platform.ps1
else
	./build-cross-platform.sh
endif

# 特定平台编译
build-windows:
	cargo build --release --target x86_64-pc-windows-msvc

build-linux:
	cargo build --release --target x86_64-unknown-linux-gnu

build-macos:
	cargo build --release --target x86_64-apple-darwin

build-macos-arm:
	cargo build --release --target aarch64-apple-darwin

# 安装编译目标
install-targets:
	rustup target add x86_64-pc-windows-msvc
	rustup target add x86_64-unknown-linux-gnu
	rustup target add x86_64-apple-darwin
	rustup target add aarch64-apple-darwin

# 清理跨平台构建
clean-cross:
	rm -rf release-builds/

# 检查所有平台编译
check-all:
	cargo check --target x86_64-pc-windows-msvc
	cargo check --target x86_64-unknown-linux-gnu
	cargo check --target x86_64-apple-darwin
	cargo check --target aarch64-apple-darwin


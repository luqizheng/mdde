# MDDE Makefile
# 简化构建和开发流程

.PHONY: help build test clean install uninstall release debug check fmt clippy doc

# 默认目标
help:
	@echo "MDDE 命令行工具构建系统"
	@echo "========================"
	@echo ""
	@echo "可用命令:"
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





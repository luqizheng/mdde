# GitHub Actions 工作流指南

本项目使用 GitHub Actions 进行自动化 CI/CD。以下是各个工作流的说明：

## 🔄 工作流文件

### 1. `build.yml` - 主构建和发布流程

**触发条件:**
- 推送到 `main` 或 `develop` 分支
- 创建 `v*` 格式的标签（自动发布）
- Pull Request 到 `main` 分支

**功能:**
- 跨平台构建（Linux x64、Windows x64、macOS Intel、macOS Apple Silicon）
- 运行测试和代码质量检查
- 自动创建 GitHub Release（仅标签触发）
- 上传构建产物

### 2. `pr-check.yml` - Pull Request 检查

**触发条件:**
- Pull Request 到 `main` 或 `develop` 分支

**功能:**
- 快速代码格式和语法检查
- 跨平台测试
- 构建预览版本（仅内部 PR）

### 3. `dependabot.yml` - 依赖项自动更新

**功能:**
- 每周检查 Rust 依赖项更新
- 每周检查 GitHub Actions 版本更新
- 自动创建 PR 进行依赖项升级

## 🚀 使用指南

### 创建新版本发布

1. **更新版本号**
   ```bash
   # 编辑 mdde-cmd/Cargo.toml
   vim mdde-cmd/Cargo.toml
   # 修改 version = "x.y.z"
   ```

2. **提交更改**
   ```bash
   git add mdde-cmd/Cargo.toml
   git commit -m "chore: bump version to vx.y.z"
   ```

3. **创建并推送标签**
   ```bash
   git tag vx.y.z
   git push origin main --tags
   ```

4. **自动发布**
   - GitHub Actions 将自动构建所有平台
   - 创建新的 Release 页面并上传二进制文件

### 开发流程

1. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature
   ```

2. **开发和测试**
   ```bash
   cd mdde-cmd
   cargo test
   cargo clippy -- -D warnings
   cargo fmt
   ```

3. **提交 PR**
   - PR 将自动运行 `pr-check.yml` 工作流
   - 所有检查通过后可以合并

### 本地测试工作流

在提交前，可以本地运行相同的检查：

```bash
# 进入项目目录
cd mdde-cmd

# 格式检查
cargo fmt -- --check

# 语法检查
cargo clippy -- -D warnings

# 运行测试
cargo test

# 构建检查
cargo build --release
```

## ⚙️ 工作流配置

### 修改构建目标

如需添加或修改构建目标，编辑 `.github/workflows/build.yml` 中的 `matrix.include` 部分：

```yaml
matrix:
  include:
    - target: 新目标架构
      os: 运行环境
      binary-name: 二进制文件名
      asset-name: 发布资源名
```

### 修改触发条件

可以在各个工作流文件的 `on:` 部分修改触发条件。

### 自定义构建步骤

在各个 job 的 `steps:` 部分添加或修改构建步骤。

## 🔧 故障排除

### 构建失败

1. 检查依赖项是否最新
2. 查看错误日志确定具体问题
3. 本地重现问题并修复

### 发布失败

1. 确保标签格式正确（`v*`）
2. 检查 GitHub token 权限
3. 确保没有同名 release 存在

### 测试失败

1. 本地运行相同的测试命令
2. 检查平台特定的依赖项
3. 更新测试代码以适应新变化

## 📝 最佳实践

1. **频繁提交**: 小而频繁的提交便于问题定位
2. **测试先行**: 本地测试通过后再推送
3. **语义化版本**: 遵循 [Semantic Versioning](https://semver.org/) 规范
4. **清晰的提交信息**: 使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式
5. **及时合并**: 避免长期存在的功能分支

## 🔗 相关链接

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Rust 交叉编译指南](https://rust-lang.github.io/rustup/cross-compilation.html)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

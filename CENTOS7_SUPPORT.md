# CentOS 7 支持实现总结

## 🎯 概述

本文档总结了为 MDDE 项目新增的 CentOS 7 / OpenSSL 1.0 兼容性支持实现。

## ✅ 已完成的工作

### 1. Cargo 配置修改

**文件**: `mdde-cmd/Cargo.toml`

- ✅ 新增 `openssl` 和 `openssl-sys` 可选依赖
- ✅ 添加 `centos7-compat` feature 支持
- ✅ 添加 `static-ssl` feature 用于静态链接

```toml
# Features 配置
[features]
default = []
# CentOS 7 兼容性（使用系统 OpenSSL 1.0）
centos7-compat = ["openssl", "openssl-sys"]
# 静态链接 OpenSSL（适用于老系统）
static-ssl = ["reqwest/native-tls-vendored"]
```

### 2. GitHub Actions 工作流增强

**文件**: `.github/workflows/build.yml`

- ✅ 新增 CentOS 7 构建矩阵项
- ✅ 集成 Docker 构建环境
- ✅ 添加 CentOS 7 专用构建步骤
- ✅ 更新发布流程包含 CentOS 7 版本

**新增构建目标**:
```yaml
# CentOS 7 兼容版本 (OpenSSL 1.0)
- target: x86_64-unknown-linux-gnu
  os: ubuntu-latest
  binary-name: mdde
  asset-name: mdde-linux-x64-centos7
  use-centos7-docker: true
  build-features: "centos7-compat"
```

### 3. Docker 构建环境

**文件**: 
- `docker/centos7.Dockerfile` - CentOS 7 构建镜像定义
- `docker/build-centos7.sh` - 专用构建脚本
- `docker/README.md` - Docker 环境使用文档

**特性**:
- ✅ 使用 CentOS 7 基础镜像
- ✅ 预安装 Rust 和开发工具
- ✅ 配置正确的 OpenSSL 环境变量
- ✅ 自动化构建和测试流程

### 4. 测试和验证脚本

**文件**: 
- `scripts/test-centos7-build.sh` - 本地构建测试脚本
- `scripts/README.md` - 脚本使用文档

**功能**:
- ✅ 完整的本地构建测试
- ✅ CentOS 7 环境运行验证
- ✅ 动态库依赖检查
- ✅ 基本功能测试

### 5. 文档更新

**文件**:
- `README.md` - 中文版主文档
- `README_EN.md` - 英文版主文档
- `CENTOS7_SUPPORT.md` - 本总结文档

**更新内容**:
- ✅ 新增 CentOS 7 下载链接说明
- ✅ 系统兼容性说明
- ✅ OpenSSL 版本兼容性指南
- ✅ 故障排除建议

## 🚀 使用方法

### 对于用户

**CentOS 7 / RHEL 7 用户请下载专用版本**:

```bash
# 下载 CentOS 7 兼容版本
wget https://github.com/luqizheng/mdde/releases/latest/download/mdde-linux-x64-centos7

# 安装
sudo mv mdde-linux-x64-centos7 /usr/local/bin/mdde
sudo chmod +x /usr/local/bin/mdde

# 验证安装
mdde --version
```

### 对于开发者

**本地测试 CentOS 7 构建**:

```bash
# 运行完整测试套件
./scripts/test-centos7-build.sh

# 或手动使用 Docker 构建
docker build -f docker/centos7.Dockerfile -t mdde-centos7-builder .
docker run --rm -v $(pwd):/workspace mdde-centos7-builder
```

**GitHub Actions 自动构建**:

推送代码到 GitHub 后，GitHub Actions 会自动构建所有平台版本，包括 CentOS 7 兼容版本。

## 🔧 技术细节

### OpenSSL 兼容性处理

- **现代系统** (`mdde-linux-x64`): 依赖 OpenSSL 3.0+
- **CentOS 7** (`mdde-linux-x64-centos7`): 兼容 OpenSSL 1.0.x

### 构建环境配置

CentOS 7 构建使用以下环境变量：

```bash
export PKG_CONFIG_ALLOW_CROSS=1
export OPENSSL_DIR=/usr
export OPENSSL_LIB_DIR=/usr/lib64
export OPENSSL_INCLUDE_DIR=/usr/include
export OPENSSL_STATIC=0
```

### Feature Flags

- `centos7-compat`: 启用 CentOS 7 兼容性
- `static-ssl`: 静态链接 OpenSSL（备选方案）

## 📊 发布流程

### 自动化发布

每次推送 `v*` 标签时，GitHub Actions 会：

1. ✅ 构建所有平台版本（包括 CentOS 7）
2. ✅ 运行测试和质量检查
3. ✅ 创建 GitHub Release
4. ✅ 上传所有二进制文件和压缩包
5. ✅ 生成详细的发布说明

### 发布产物

新增的 CentOS 7 相关发布文件：

- `mdde-linux-x64-centos7` - 二进制文件
- `mdde-linux-x64-centos7.tar.gz` - 压缩包

## 🧪 测试覆盖

### 自动化测试

- ✅ GitHub Actions CI/CD 流程
- ✅ 跨平台构建验证
- ✅ 基本功能测试

### 本地测试

- ✅ Docker 环境构建测试
- ✅ CentOS 7 容器运行验证
- ✅ 动态库依赖检查

## ⚠️ 注意事项

### 系统要求

- **CentOS 7 / RHEL 7**: 使用 `mdde-linux-x64-centos7`
- **现代 Linux**: 继续使用 `mdde-linux-x64`
- **Docker**: 本地测试需要 Docker 支持

### 故障排除

如果遇到 `libssl.so.3: cannot open shared object file` 错误：

1. 检查系统 OpenSSL 版本：`openssl version`
2. 下载 CentOS 7 兼容版本
3. 或者升级系统 OpenSSL 到 3.0+

## 📈 后续维护

### 定期检查项目

- [ ] CentOS 7 基础镜像安全更新
- [ ] Rust 版本兼容性测试
- [ ] OpenSSL 依赖更新
- [ ] 用户反馈处理

### 版本发布检查

每次发布新版本时，确保：

- [ ] CentOS 7 版本正常构建
- [ ] 在真实 CentOS 7 环境中测试
- [ ] 更新相关文档
- [ ] 验证下载链接可用

---

## 🎉 总结

通过以上实现，MDDE 项目现在完全支持 CentOS 7 / RHEL 7 系统。用户可以：

1. **无缝安装**: 直接下载兼容版本使用
2. **自动构建**: 每次发布都包含 CentOS 7 版本
3. **本地测试**: 开发者可以本地验证兼容性
4. **持续维护**: 自动化流程确保长期支持

这解决了原始问题中遇到的 `libssl.so.3: cannot open shared object file` 错误，为老旧系统用户提供了完整的解决方案。

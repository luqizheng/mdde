# Docker 构建环境

## 概述

此目录包含用于不同操作系统和版本兼容性的 Docker 构建环境。

## CentOS 7 兼容构建

### 背景

CentOS 7 使用较老的 OpenSSL 1.0.x 版本，而现代构建的 Rust 程序通常依赖 OpenSSL 3.x。为了确保 MDDE 能在 CentOS 7 系统上正常运行，我们提供了专门的构建环境。

**⚠️ 重要说明**: CentOS 7 于 2024年6月30日 结束生命周期 (EOL)。我们的构建环境已配置使用 `vault.centos.org` 镜像源来解决原官方源不可用的问题。

### 文件说明

- `centos7.Dockerfile` - CentOS 7 构建环境 Docker 镜像
- `build-centos7.sh` - CentOS 7 兼容构建脚本
- `README.md` - 本文档

### 使用方法

#### 方法一：使用 Docker 直接构建

```bash
# 在项目根目录执行
cd mdde

# 构建 Docker 镜像
docker build -f docker/centos7.Dockerfile -t mdde-centos7-builder .

# 运行构建
docker run --rm -v $(pwd):/workspace mdde-centos7-builder
```

#### 方法二：使用构建脚本

```bash
# 直接使用脚本构建（需要在 CentOS 7 环境中）
chmod +x docker/build-centos7.sh
docker/build-centos7.sh
```

#### 方法三：GitHub Actions 自动构建

推送代码到 GitHub 后，GitHub Actions 会自动使用这个环境构建 CentOS 7 兼容版本。

### 构建产物

构建成功后，会在以下位置生成二进制文件：

```
mdde-cmd/target/x86_64-unknown-linux-gnu/release/mdde
```

### 特性配置

CentOS 7 构建使用了以下 Cargo features：

- `centos7-compat` - 启用 CentOS 7 兼容性
- 使用系统 OpenSSL 1.0.x
- 动态链接系统库

### 兼容性验证

构建脚本会自动进行以下验证：

1. ✅ OpenSSL 版本检查
2. ✅ 动态库依赖检查
3. ✅ 基本功能测试（`--version` 命令）

### 系统要求

**目标系统（运行环境）:**
- CentOS 7.x
- RHEL 7.x  
- 其他基于 EL7 的发行版

**构建环境:**
- Docker
- 8GB+ 内存推荐
- 10GB+ 磁盘空间

### 故障排除

#### 构建失败

**CentOS 7 源问题**:
如果遇到 `Could not resolve host: mirrorlist.centos.org` 错误，我们的构建脚本会自动修复源配置。

```bash
# 检查 Docker 容器环境
docker run --rm -it centos:7 bash

# 手动修复源（如果需要）
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo
yum clean all

# 手动验证依赖
yum list installed | grep openssl-devel
pkg-config --exists openssl
```

#### 运行时错误

```bash
# 检查目标系统的 OpenSSL 版本
openssl version

# 检查动态库依赖
ldd /usr/local/bin/mdde

# 验证系统兼容性  
/usr/local/bin/mdde --version
```

### 开发建议

1. **本地测试**: 使用 Docker 容器本地测试构建流程
2. **CI/CD**: 依赖 GitHub Actions 进行自动化构建
3. **版本管理**: 确保 Dockerfile 和脚本与主项目版本同步

### 更新维护

定期检查和更新：

- [ ] CentOS 7 基础镜像安全更新
- [ ] Rust 版本兼容性
- [ ] OpenSSL 版本支持
- [ ] 依赖库更新

---

如有问题请提交 Issue 或参考项目主 README 文档。

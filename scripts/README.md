# 构建和测试脚本

## 概述

此目录包含用于构建、测试和验证 MDDE 项目的各种脚本。

## 脚本列表

### CentOS 7 兼容性支持

- **`test-centos7-build.sh`** - CentOS 7 兼容性构建和测试脚本

## 使用说明

### CentOS 7 构建测试

测试 CentOS 7 兼容版本的完整构建流程：

```bash
# 给予执行权限
chmod +x scripts/test-centos7-build.sh

# 运行测试
./scripts/test-centos7-build.sh
```

此脚本将：

1. ✅ 构建 CentOS 7 Docker 镜像
2. ✅ 在 CentOS 7 环境中编译 MDDE
3. ✅ 验证构建产物存在
4. ✅ 在 CentOS 7 容器中测试运行
5. ✅ 检查动态库依赖
6. ✅ 运行基本功能测试

## 系统要求

- Docker
- Bash 4.0+
- 10GB+ 磁盘空间
- 网络连接（下载基础镜像）

## 故障排除

### Docker 权限问题

```bash
# 添加当前用户到 docker 组
sudo usermod -aG docker $USER
# 重新登录或运行
newgrp docker
```

### 磁盘空间不足

```bash
# 清理 Docker 缓存
docker system prune -a

# 检查磁盘使用情况
df -h
docker system df
```

### 网络连接问题

```bash
# 测试 Docker Hub 连接
docker pull hello-world

# 使用镜像加速器（中国地区）
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
```

## 开发指南

### 添加新的测试脚本

1. 创建脚本文件
2. 添加执行权限：`chmod +x scripts/your-script.sh`
3. 更新此 README 文档
4. 确保脚本有适当的错误处理和用户反馈

### 脚本规范

- 使用 `set -euo pipefail` 进行严格错误处理
- 提供彩色输出以提高可读性
- 包含清理功能（清理临时文件、容器等）
- 添加适当的日志和进度指示

---

如有问题请查看项目主文档或提交 Issue。

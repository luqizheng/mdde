# CentOS 7 构建环境 - 用于创建兼容老系统的 MDDE 二进制文件
FROM centos:7

# 修复 CentOS 7 EOL 源问题（切换到 vault 镜像源）
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

# 更新包管理器和安装基础工具
RUN yum clean all && \
    yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
        openssl-devel \
        pkg-config \
        curl \
        file \
        git \
        which && \
    yum clean all

# 安装 Rust
ENV RUSTUP_HOME=/opt/rust
ENV CARGO_HOME=/opt/rust
ENV PATH=/opt/rust/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path && \
    echo 'export PATH=/opt/rust/bin:$PATH' >> /etc/profile

# 设置 OpenSSL 环境变量以使用系统版本
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV OPENSSL_DIR=/usr
ENV OPENSSL_LIB_DIR=/usr/lib64
ENV OPENSSL_INCLUDE_DIR=/usr/include
ENV OPENSSL_STATIC=0

# 创建工作目录
WORKDIR /workspace

# 设置默认的构建脚本
COPY docker/build-centos7.sh /usr/local/bin/build-centos7.sh
RUN chmod +x /usr/local/bin/build-centos7.sh

# 默认命令
CMD ["/usr/local/bin/build-centos7.sh"]

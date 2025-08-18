# 适用于 mdde-cmd 的多平台 Rust 交叉编译 Dockerfile

# 基础镜像，使用官方 Rust 镜像
FROM rust:1.89.0-trixie AS builder

RUN export RUSTUP_DIST_SERVER=http://192.168.2.8:8081/repository/rustup

# 修改 apt 源为清华源
# if you not in China, you can skip this step
RUN sed -i \
    -e 's|http://deb.debian.org/debian|https://mirrors.tuna.tsinghua.edu.cn/debian|g' \
    -e 's|http://security.debian.org|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' \
    /etc/apt/sources.list.d/debian.sources

# 安装交叉编译所需工具链和依赖
# if you not in China, you can skip this step
RUN rustup target add x86_64-pc-windows-msvc \
    && rustup target add x86_64-unknown-linux-gnu \
    && rustup target add x86_64-apple-darwin \
    && rustup target add aarch64-apple-darwin \
    && apt-get update \
    && apt-get install -y build-essential musl-tools mingw-w64 curl pkg-config libssl-dev

# # 拷贝项目源码
# WORKDIR /app
# COPY . .

# # 可选：清理旧的构建产物
# RUN cargo clean

# # 编译 Windows 64 位
# RUN cargo build --release --target x86_64-pc-windows-msvc

# # 编译 Linux 64 位
# RUN cargo build --release --target x86_64-unknown-linux-gnu

# # 编译 macOS Intel 64 位
# RUN cargo build --release --target x86_64-apple-darwin

# # 编译 macOS Apple Silicon
# RUN cargo build --release --target aarch64-apple-darwin

# 输出产物到 /output 目录
RUN mkdir -p /output/windows /output/linux /output/macos-intel /output/macos-arm \
    && cp target/x86_64-pc-windows-msvc/release/mdde-cmd.exe /output/windows/ || true \
    && cp target/x86_64-unknown-linux-gnu/release/mdde-cmd /output/linux/ || true \
    && cp target/x86_64-apple-darwin/release/mdde-cmd /output/macos-intel/ || true \
    && cp target/aarch64-apple-darwin/release/mdde-cmd /output/macos-arm/ || true

# 导出产物阶段
FROM scratch AS export-stage
COPY --from=builder /output /output


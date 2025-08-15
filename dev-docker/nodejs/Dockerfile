FROM node:18-alpine

# 安装系统依赖
RUN apk add --no-cache \
    git \
    curl \
    vim \
    nano \
    python3 \
    make \
    g++

# 设置工作目录
WORKDIR /workspace

# 全局安装常用开发工具
RUN npm install -g \
    nodemon \
    typescript \
    ts-node \
    @types/node \
    eslint \
    prettier \
    jest \
    yarn

# 设置环境变量
ENV NODE_ENV=development
ENV CHOKIDAR_USEPOLLING=true

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /workspace
USER nodejs

CMD ["tail", "-f", "/dev/null"]

# MDDE 日志查看命令使用指南

## 概述
`mdde logs` 命令用于查看 Docker 容器的日志，直接调用 `docker logs` 命令。支持多种参数组合来满足不同的日志查看需求。

## 命令语法

```bash
mdde logs [OPTIONS] [LINES]
```

## 参数说明

### 位置参数
- `LINES` - 显示最后 N 行日志（可直接写数字）

### 选项参数
- `-l, --tail <TAIL>` - 显示最后 N 行
- `-a, --all` - 显示所有日志
- `-f, --follow` - 实时跟踪日志

## 使用示例

### 1. 基础用法

```bash
# 使用位置参数（推荐）- 显示最后 100 行日志
mdde logs 100
# 等同于: docker logs container_name --tail 100

# 显示最后 50 行日志（默认）
mdde logs

# 显示所有日志
mdde logs -a
# 等同于: docker logs container_name
```

### 2. 参数组合

```bash
# 使用 --tail 参数（与位置参数效果相同）
mdde logs -l 100
mdde logs --tail 100

# 实时跟踪日志
mdde logs -f
mdde logs --follow

# 跟踪最后 20 行并继续实时监控
mdde logs 20 -f
```

### 3. 参数优先级

位置参数优先于 `--tail` 参数：

```bash
# 位置参数优先，实际显示 100 行
mdde logs 100 --tail 50  # 显示 100 行（位置参数优先）

# 只有 --tail 参数时使用该值
mdde logs --tail 50      # 显示 50 行
```

## 对应的 Docker 命令

| MDDE 命令 | 对应的 Docker 命令 |
|-----------|-------------------|
| `mdde logs 100` | `docker logs container_name --tail 100` |
| `mdde logs -a` | `docker logs container_name` |
| `mdde logs -f` | `docker logs container_name -f --tail 50` |
| `mdde logs 20 -f` | `docker logs container_name --tail 20 -f` |

## 容器名称获取

命令会自动从以下位置获取容器名称（按优先级）：

1. `.mdde/cfg.env` 文件中的 `container_name` 变量
2. 配置中的 `container_name` 设置

如果未找到容器名称，命令会提示：
```
未找到容器名称，请先运行 'mdde create' 创建环境或使用 'mdde env --set container_name=your_name' 设置容器名
```

## 错误处理

### 常见错误和解决方案

1. **容器不存在**
   ```
   容器 'container_name' 不存在。请检查容器名称或先启动容器
   ```
   - 解决：检查容器名称是否正确，或先启动容器

2. **容器未运行**
   ```
   获取日志失败，容器 'container_name' 可能不存在或未运行
   ```
   - 解决：使用 `mdde start` 启动容器，或检查容器状态

3. **无日志输出**
   ```
   暂无日志输出
   提示: 容器可能未运行或没有产生日志输出
   ```
   - 解决：检查应用是否正在运行并产生日志

## 实时跟踪模式

使用 `-f` 参数时：
- 显示实时日志输出
- 按 `Ctrl+C` 停止跟踪
- 适合调试和监控应用状态

```bash
# 实时跟踪日志
mdde logs -f

# 先显示最后 100 行，然后实时跟踪
mdde logs 100 -f
```

## 最佳实践

1. **开发调试**：使用 `mdde logs 100 -f` 查看最近日志并实时监控
2. **错误排查**：使用 `mdde logs -a` 查看完整日志
3. **日常检查**：使用 `mdde logs 50` 快速查看最近状态
4. **生产监控**：使用 `mdde logs -f` 实时监控应用运行状态

## 与其他命令的配合

```bash
# 典型工作流程
mdde create dotnet9 --name my-app    # 创建环境
mdde start                           # 启动容器
mdde logs 50                         # 查看启动日志
mdde logs -f                         # 实时监控

# 问题排查流程
mdde status                          # 检查容器状态
mdde logs -a                         # 查看完整日志
mdde logs -f                         # 实时监控问题
```

## 注意事项

- 容器必须存在才能查看日志
- 某些容器可能需要运行一段时间后才会产生日志
- 使用 `-f` 参数时，通过 `Ctrl+C` 终止跟踪
- 日志内容取决于容器内应用的日志输出配置

# MDDE 环境变量管理命令使用指南

## 概述
`mdde env` 命令用于管理 `.mdde/cfg.env` 配置文件中的环境变量。支持添加、查看和删除环境变量。

## 命令语法

```bash
mdde env [OPTIONS]
```

## 选项

- `--set <key=value>` - 设置环境变量
- `--ls` - 显示所有环境变量  
- `--del <key>` - 删除环境变量

## 使用示例

### 1. 显示所有环境变量

```bash
mdde env --ls
```

输出示例：
```
环境变量配置 (.mdde/cfg.env):
================================
app_port=8080:80
host=http://localhost:3000
container_name=my-dev-env

总共 3 个环境变量
```

### 2. 设置环境变量

```bash
# 设置服务器地址
mdde env --set host=http://localhost:3000

# 设置应用端口
mdde env --set app_port=8080:80

# 设置容器名称
mdde env --set container_name=my-app

# 设置自定义环境变量
mdde env --set custom_var=value123
```

### 3. 删除环境变量

```bash
# 删除指定的环境变量
mdde env --del custom_var

# 删除端口配置
mdde env --del app_port
```

## 环境变量名称变更

为了简化配置，以下环境变量名已更新：

| 旧名称 | 新名称 | 说明 |
|--------|--------|------|
| `host` | `host` | MDDE 服务器地址 |
| `debug_port` | `app_port` | 应用端口映射 |

## 输入验证

### 环境变量名规则
- 只能包含字母、数字和下划线
- 不能为空
- 区分大小写

### 值格式
- 支持任意字符串值
- 支持空值（如 `key=`）
- 支持包含等号的值（如 `query=a=b&c=d`）

## 错误处理

### 常见错误示例

```bash
# 错误：格式不正确
mdde env --set invalid_format
# 错误: 无效的格式: 'invalid_format'. 应为 key=value 格式

# 错误：环境变量名包含非法字符
mdde env --set invalid-key=value
# 错误: 环境变量名只能包含字母、数字和下划线

# 错误：删除不存在的变量
mdde env --del nonexistent
# 错误: 环境变量 'nonexistent' 不存在

# 错误：同时使用多个操作
mdde env --set key=value --ls
# 错误: 只能同时使用一个操作选项
```

## 配置文件位置

环境变量存储在 `.mdde/cfg.env` 文件中，格式为：

```
host=http://localhost:3000
app_port=8080:80
container_name=my-dev-env
custom_var=value123
```

## 与其他命令的集成

这些环境变量会被其他 MDDE 命令自动加载和使用：

- `mdde init` - 设置 `host` 变量
- `mdde create` - 设置 `container_name`、`app_port`、`workspace` 变量
- 所有命令都会读取这些变量来覆盖默认配置

## 自动功能

- **排序显示**：`--ls` 命令会按字母顺序显示环境变量
- **自动创建目录**：首次设置变量时自动创建 `.mdde` 目录
- **gitignore 更新**：自动在 `.gitignore` 中添加 `.mdde/` 目录
- **彩色输出**：使用颜色区分不同类型的信息

## 最佳实践

1. **服务器配置**：使用 `host` 变量统一管理服务器地址
2. **端口管理**：使用 `app_port` 变量配置端口映射
3. **环境隔离**：为不同项目使用不同的 `container_name`
4. **定期检查**：使用 `--ls` 命令定期查看当前配置
5. **清理无用变量**：及时删除不再需要的环境变量

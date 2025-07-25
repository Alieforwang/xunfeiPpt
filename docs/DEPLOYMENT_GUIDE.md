# 部署指南

本指南提供了讯飞智文PPT生成服务的完整部署说明。

## 🚀 快速开始

### 专用uv环境部署（推荐）

使用专门的uv环境自动化部署脚本：

```bash
# 基本部署
bash uv_deploy.sh

# 自定义配置
bash uv_deploy.sh --host 127.0.0.1 --port 8080 --protocol http-stream
```

详细使用说明请参考：[uv部署指南](../UV_DEPLOY_README.md)

### 手动部署

如果需要手动部署：

```bash
# 1. 安装uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. 安装Python 3.13+
uv python install 3.13
uv python pin 3.13

# 3. 同步依赖
uv sync

# 4. 启动服务
uv run python main.py http-stream --host 0.0.0.0 --port 60
```

## 📋 脚本说明

### uv专用部署脚本

- **`uv_deploy.sh`** - 专用uv环境自动化部署脚本（推荐）
  - 按照MCP和uv官网标准配置
  - 支持参数化配置 (host/port/protocol)
  - 自动生成服务管理脚本
  - 完整的服务生命周期管理

### 服务管理

部署后会生成 `service_manager.sh` 脚本：
- 启动/停止/重启/状态查看
- 日志管理和进程监控
- PID文件管理

## 🔧 跨平台支持

### uv环境管理

部署脚本基于uv进行环境管理：

- **自动安装**: uv和Python 3.13+环境
- **标准配置**: 按照uv官网标准配置项目
- **依赖管理**: 使用`uv sync`管理依赖
- **虚拟环境**: 自动创建和管理虚拟环境

### 系统支持

- **Linux**: 所有主要发行版
- **macOS**: 完整支持
- **Windows**: WSL/Git Bash/MSYS2支持

## 🛠️ 手动部署步骤

如果需要完全手动部署：

### 1. 环境准备

```bash
# 安装uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 重新加载PATH
export PATH="$HOME/.cargo/bin:$PATH"
```

### 2. Python环境

```bash
# 安装Python 3.13+
uv python install 3.13

# 设置项目Python版本
uv python pin 3.13
```

### 3. 项目初始化

```bash
# 确保有pyproject.toml文件
# 如果没有，会自动创建

# 同步依赖
uv sync
```

### 4. 启动服务

```bash
# 直接启动
uv run python main.py http-stream --host 0.0.0.0 --port 60

# 后台启动
nohup uv run python main.py http-stream --host 0.0.0.0 --port 60 > service.log 2>&1 &
```

## 🔍 故障排除

### 常见问题

#### 1. Python版本问题

**症状**: 项目要求Python 3.13+
**解决方案**:
```bash
# 检查Python版本
python3.13 --version

# 如果没有Python 3.13，使用uv安装
curl -LsSf https://astral.sh/uv/install.sh | sh
uv python install 3.13
```

#### 2. 依赖验证失败

**症状**: 依赖包无法正确导入
**解决方案**:
```bash
# 使用正确的Python环境安装依赖
uv pip install --python python3.13 mcp requests requests-toolbelt starlette uvicorn
```

#### 3. systemd服务启动失败

**症状**: 服务配置错误或Python路径不正确
**解决方案**:
```bash
# 使用修复脚本
bash fix_deployment.sh

# 或手动检查systemd配置
sudo systemctl status ppt-mcp-sse
journalctl -u ppt-mcp-sse -n 20
```

#### 4. 端口被占用

**症状**: 端口60已被使用
**解决方案**:
```bash
# 检查端口占用
sudo netstat -tlnp | grep 60
sudo ss -tlnp | grep 60

# 停止占用端口的进程或更换端口
python3.13 main.py sse --host 0.0.0.0 --port 8060
```

### 服务管理

#### 使用生成的服务管理脚本

```bash
# 使用自动生成的服务管理脚本
./service_manager.sh start    # 启动服务
./service_manager.sh stop     # 停止服务
./service_manager.sh restart  # 重启服务
./service_manager.sh status   # 查看状态
./service_manager.sh logs     # 查看日志
./service_manager.sh logs -f  # 实时日志
```

## 🌐 网络配置

### 防火墙设置

#### Linux (firewalld)
```bash
sudo firewall-cmd --permanent --add-port=60/tcp
sudo firewall-cmd --reload
```

#### Linux (ufw)
```bash
sudo ufw allow 60
```

### 访问地址

部署成功后，可通过以下地址访问服务：

- **本地访问**: http://localhost:60
- **局域网访问**: http://内网IP:60
- **公网访问**: http://公网IP:60 (需配置防火墙)

### 状态页面

访问根路径可看到服务状态页面：
- 服务运行状态
- 可用工具列表
- SSE连接测试
- 使用说明

## 🔄 更新和维护

### 更新服务

```bash
# 停止服务
./service_manager.sh stop

# 更新代码
git pull origin main

# 同步依赖
uv sync

# 重启服务
./service_manager.sh start
```

### 备份配置

```bash
# 备份工作目录
tar -czf ppt-mcp-backup-$(date +%Y%m%d).tar.gz ./
```

## 📞 技术支持

如果遇到部署问题：

1. 查看[使用指南](./USAGE.md)了解基本功能
2. 检查系统兼容性和Python版本
3. 查看错误日志和运行诊断
4. 使用修复脚本解决常见问题
5. 提交GitHub Issue获取帮助

## 相关文档

- [使用指南](./USAGE.md) - 完整的功能使用说明
- [HTTP Stream指南](./HTTP_STREAM_GUIDE.md) - 新的传输协议说明
- [API密钥池指南](./API_KEY_POOL_GUIDE.md) - 多密钥配置说明
- [脚本说明](../scripts/README.md) - 详细的脚本使用说明
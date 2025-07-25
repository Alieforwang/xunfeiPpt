# 部署指南

本指南提供了讯飞智文PPT生成服务的完整部署说明。

## 🚀 快速开始

### 方案一：自动部署脚本（推荐）

支持跨平台自动适配，包含完整的系统检测和服务管理：

```bash
# 运行自动部署脚本
bash scripts/auto_deploy.sh
```

### 方案二：手动修复部署问题

如果自动部署遇到问题，可以使用修复脚本：

```bash
# 运行修复脚本
bash fix_deployment.sh
```

## 📋 脚本说明

### 部署脚本

- **`scripts/auto_deploy.sh`** - 完整自动部署脚本（推荐生产环境）
- **`scripts/quick_deploy.sh`** - 简化一键部署脚本（推荐测试环境）
- **`scripts/deploy.sh`** - 原始部署脚本
- **`fix_deployment.sh`** - 修复部署问题的临时脚本

### 服务管理脚本

- **`scripts/install_service.sh`** - systemd服务安装脚本（Linux）
- **`scripts/uninstall_service.sh`** - systemd服务卸载脚本（Linux）

## 🔧 跨平台支持

### 自动检测功能

部署脚本会自动检测以下系统环境：

- **操作系统**: Linux, macOS, Windows (Cygwin/MSYS)
- **Linux发行版**: Ubuntu, CentOS, Debian 等
- **Python版本**: 优先Python 3.13+，支持自动安装
- **包管理器**: 优先使用 uv，回退到 pip
- **文件编码**: 自动转换 Windows CRLF 到 Unix LF

### 系统特定配置

| 系统 | 工作目录 | 服务管理 | 端口配置 |
|------|----------|----------|----------|
| Linux | `/www/wwwroot/xunfeiPpt` | systemd 或通用脚本 | 60 |
| macOS | `~/xunfeiPpt` | 通用脚本 | 60 |
| Windows | `/c/xunfeiPpt` | 通用脚本 | 60 |

## 🛠️ 手动部署步骤

如果自动部署遇到问题，可以按以下步骤手动部署：

### 1. 环境准备

```bash
# 创建工作目录
mkdir -p /www/wwwroot/xunfeiPpt
cd /www/wwwroot/xunfeiPpt

# 检查Python环境（需要Python 3.13+）
python3.13 --version || python3 --version || python --version
```

### 2. 安装依赖

```bash
# 使用uv安装（推荐）
uv pip install mcp requests requests-toolbelt starlette uvicorn

# 或使用pip安装
pip3 install mcp requests requests-toolbelt starlette uvicorn
```

### 3. 复制main.py文件

从项目根目录复制main.py到工作目录。

### 4. 启动服务

```bash
# 直接启动
python3.13 main.py sse --host 0.0.0.0 --port 60

# 后台启动
nohup python3.13 main.py sse --host 0.0.0.0 --port 60 > service.log 2>&1 &
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

#### Linux systemd服务

```bash
# 查看服务状态
systemctl status ppt-mcp-sse

# 启动/停止/重启服务
sudo systemctl start ppt-mcp-sse
sudo systemctl stop ppt-mcp-sse
sudo systemctl restart ppt-mcp-sse

# 查看服务日志
journalctl -u ppt-mcp-sse -f
```

#### 通用服务管理

```bash
# 使用服务管理脚本（自动部署时创建）
bash service_manager.sh start
bash service_manager.sh stop
bash service_manager.sh restart
bash service_manager.sh status
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
bash service_manager.sh stop

# 更新代码
git pull origin main

# 重启服务
bash service_manager.sh start
```

### 备份配置

```bash
# 备份工作目录
tar -czf ppt-mcp-backup-$(date +%Y%m%d).tar.gz /www/wwwroot/xunfeiPpt
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
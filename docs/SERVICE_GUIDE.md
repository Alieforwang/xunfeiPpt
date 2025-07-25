# 服务管理指南

本指南说明如何管理讯飞智文PPT生成服务的systemd服务配置。

## 📋 服务文件

### systemd服务配置
- `scripts/ppt-mcp-sse.service` - systemd服务配置文件
- `scripts/install_service.sh` - 自动安装脚本
- `scripts/uninstall_service.sh` - 自动卸载脚本

## 🚀 安装步骤

### 1. 确保部署完成

首先确保已经完成基本部署：
```bash
# 使用自动部署脚本
bash scripts/auto_deploy.sh
```

### 2. 手动安装systemd服务（如果需要）

```bash
# 给安装脚本执行权限
chmod +x scripts/install_service.sh
chmod +x scripts/uninstall_service.sh

# 运行安装脚本
sudo bash scripts/install_service.sh
```

## 🎯 服务管理命令

### 基本操作
```bash
# 查看服务状态
systemctl status ppt-mcp-sse

# 启动服务
sudo systemctl start ppt-mcp-sse

# 停止服务
sudo systemctl stop ppt-mcp-sse

# 重启服务
sudo systemctl restart ppt-mcp-sse

# 重新加载配置
sudo systemctl reload ppt-mcp-sse
```

### 开机启动
```bash
# 启用开机自启动
sudo systemctl enable ppt-mcp-sse

# 禁用开机自启动
sudo systemctl disable ppt-mcp-sse
```

### 日志查看
```bash
# 查看实时日志
journalctl -u ppt-mcp-sse -f

# 查看最近20条日志
journalctl -u ppt-mcp-sse -n 20

# 查看今天的日志
journalctl -u ppt-mcp-sse --since today
```

## 🌐 服务访问

安装成功后，服务将在以下地址提供：

- **状态页面**: `http://your-server-ip:60/`
- **SSE端点**: `http://your-server-ip:60/sse`
- **消息端点**: `http://your-server-ip:60/messages/`
- **HTTP Stream端点**: `http://your-server-ip:60/mcp` (推荐)

## 🔧 配置修改

### 修改服务配置

如需修改配置，编辑服务文件：
```bash
sudo nano /etc/systemd/system/ppt-mcp-sse.service
```

修改后重新加载：
```bash
sudo systemctl daemon-reload
sudo systemctl restart ppt-mcp-sse
```

### 常见配置修改

#### 更改端口
```ini
# 在服务文件中修改ExecStart行
ExecStart=python3.13 main.py sse --host 0.0.0.0 --port 8060
```

#### 更改工作目录
```ini
# 修改WorkingDirectory
WorkingDirectory=/path/to/your/directory
```

#### 更改Python路径
```ini
# 修改ExecStart中的python命令
ExecStart=/usr/bin/python3.13 main.py sse --host 0.0.0.0 --port 60
```

## 🔥 防火墙设置

### firewalld (CentOS/RHEL)
```bash
# 开放60端口
sudo firewall-cmd --permanent --add-port=60/tcp
sudo firewall-cmd --reload

# 验证端口开放
sudo firewall-cmd --list-ports
```

### ufw (Ubuntu/Debian)
```bash
# 开放60端口
sudo ufw allow 60

# 查看防火墙状态
sudo ufw status
```

## 🗑️ 卸载服务

如需卸载服务：
```bash
sudo bash scripts/uninstall_service.sh
```

或手动卸载：
```bash
# 停止并禁用服务
sudo systemctl stop ppt-mcp-sse
sudo systemctl disable ppt-mcp-sse

# 删除服务文件
sudo rm /etc/systemd/system/ppt-mcp-sse.service

# 重新加载systemd
sudo systemctl daemon-reload
```

## 🐛 故障排除

### 服务启动失败

```bash
# 查看详细错误信息
systemctl status ppt-mcp-sse
journalctl -u ppt-mcp-sse -n 50
```

### 常见问题

#### 1. Python路径错误
**症状**: 服务显示 `code=exited, status=203/EXEC`
**解决方案**: 
```bash
# 使用修复脚本
bash fix_deployment.sh

# 或手动检查Python路径
which python3.13
# 更新服务文件中的ExecStart路径
```

#### 2. 工作目录不存在
**症状**: 服务无法启动，找不到main.py
**解决方案**:
```bash
# 确保工作目录存在
ls -la /www/wwwroot/xunfeiPpt/main.py

# 重新运行部署脚本
bash scripts/auto_deploy.sh
```

#### 3. 权限问题
**症状**: 权限拒绝错误
**解决方案**:
```bash
# 检查文件权限
ls -la /www/wwwroot/xunfeiPpt/

# 修正权限
sudo chown -R root:root /www/wwwroot/xunfeiPpt/
sudo chmod +x /www/wwwroot/xunfeiPpt/main.py
```

#### 4. 端口被占用
**症状**: 端口绑定失败
**解决方案**:
```bash
# 检查端口占用
sudo netstat -tlnp | grep 60
sudo ss -tlnp | grep 60

# 停止占用端口的进程或更改服务端口
```

### 检查服务依赖

```bash
# 验证Python环境
python3.13 --version

# 验证依赖包
python3.13 -c "import mcp, requests, starlette, uvicorn; print('Dependencies OK')"

# 测试服务启动
cd /www/wwwroot/xunfeiPpt
python3.13 main.py sse --host 0.0.0.0 --port 60
```

## 📊 性能监控

### 查看服务状态
```bash
# 查看服务基本信息
systemctl show ppt-mcp-sse

# 查看服务进程
ps aux | grep ppt-mcp-sse

# 查看端口监听
ss -tlnp | grep 60
```

### 日志分析
```bash
# 查看错误日志
journalctl -u ppt-mcp-sse -p err

# 查看最近1小时的日志
journalctl -u ppt-mcp-sse --since "1 hour ago"

# 导出日志到文件
journalctl -u ppt-mcp-sse > ppt-service.log
```

## 相关文档

- [部署指南](./DEPLOYMENT_GUIDE.md) - 完整的部署说明
- [使用指南](./USAGE.md) - 功能使用说明
- [脚本说明](../scripts/README.md) - 部署脚本详细说明
# 讯飞智文PPT生成服务 - 系统服务配置

## 📋 文件说明

### 服务配置文件
- `ppt-mcp-sse.service` - systemd服务配置文件
- `install_service.sh` - 自动安装脚本
- `uninstall_service.sh` - 自动卸载脚本

## 🚀 安装步骤

1. **复制文件到Linux服务器**
   ```bash
   # 确保文件在正确的目录
   cd /www/wwwroot/xunfeiPpt
   ```

2. **给安装脚本执行权限**
   ```bash
   chmod +x install_service.sh
   chmod +x uninstall_service.sh
   ```

3. **运行安装脚本**
   ```bash
   sudo bash install_service.sh
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

## 🌐 访问地址

安装成功后，服务将在以下地址提供：

- **状态页面**: `http://your-server-ip:8001/`
- **SSE端点**: `http://your-server-ip:8001/sse`
- **消息端点**: `http://your-server-ip:8001/messages/`

## 🔧 配置修改

如需修改配置，编辑服务文件：
```bash
sudo nano /etc/systemd/system/ppt-mcp-sse.service
```

修改后重新加载：
```bash
sudo systemctl daemon-reload
sudo systemctl restart ppt-mcp-sse
```

## 🔥 防火墙设置

```bash
# 开放8001端口
sudo firewall-cmd --permanent --add-port=8001/tcp
sudo firewall-cmd --reload

# 验证端口开放
sudo firewall-cmd --list-ports
```

## 🗑️ 卸载服务

如需卸载服务：
```bash
sudo bash uninstall_service.sh
```

## 🐛 故障排除

### 服务启动失败
```bash
# 查看详细错误信息
systemctl status ppt-mcp-sse
journalctl -u ppt-mcp-sse -n 50
```

### 常见问题
1. **Python路径错误**: 修改服务文件中的`ExecStart`路径
2. **工作目录不存在**: 确保`/www/wwwroot/xunfeiPpt`目录存在
3. **权限问题**: 确保文件有正确的读写权限
4. **端口被占用**: 检查8001端口是否被其他程序占用

### 检查端口占用
```bash
# 检查8001端口
sudo netstat -tlnp | grep 8001
sudo ss -tlnp | grep 8001
```
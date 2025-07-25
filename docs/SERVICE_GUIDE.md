# 服务管理指南

本指南说明如何管理讯飞智文PPT生成服务，包括三协议同时启动模式和传统systemd服务管理。

## 🌟 核心特性

### 三协议同时启动
- **HTTP** (端口60): RESTful API接口
- **SSE** (端口61): Server-Sent Events实时通信
- **HTTP Stream** (端口62): MCP 2025-03-26标准协议
- **独立进程管理**: 每个协议独立的PID和日志文件
- **环境变量配置**: HOST/PORT灵活设置

## 🚀 快速开始

### 方案1：三协议服务管理器（推荐）

```bash
# 1. 部署服务管理器
bash uv_deploy.sh

# 2. 启动所有三种协议服务
./service_manager.sh start

# 3. 查看服务状态
./service_manager.sh status

# 4. 管理服务
./service_manager.sh stop      # 停止所有服务
./service_manager.sh restart   # 重启所有服务
./service_manager.sh logs      # 查看所有服务日志
```

### 方案2：传统systemd服务（向后兼容）

```bash
# 安装systemd服务（如果需要）
sudo bash scripts/install_service.sh

# 管理systemd服务
sudo systemctl start ppt-mcp-sse
sudo systemctl status ppt-mcp-sse
sudo systemctl stop ppt-mcp-sse
```

## 📋 服务管理详解

### 三协议服务管理器

#### 基本命令

```bash
# 服务生命周期管理
./service_manager.sh start     # 启动所有三种协议服务
./service_manager.sh stop      # 停止所有服务
./service_manager.sh restart   # 重启所有服务
./service_manager.sh status    # 查看详细服务状态
```

#### 日志管理

```bash
# 查看所有服务日志
./service_manager.sh logs

# 查看特定服务日志
./service_manager.sh logs http     # HTTP服务日志
./service_manager.sh logs sse      # SSE服务日志
./service_manager.sh logs stream   # HTTP-STREAM服务日志

# 实时查看日志
./service_manager.sh logs http -f
./service_manager.sh logs sse -f
./service_manager.sh logs stream -f
```

#### 环境变量配置

```bash
# 自定义绑定地址
HOST=0.0.0.0 ./service_manager.sh start

# 自定义基础端口（自动分配+1, +2）
PORT=8080 ./service_manager.sh start
# 启动: HTTP(8080), SSE(8081), HTTP-STREAM(8082)

# 组合配置
HOST=127.0.0.1 PORT=9000 ./service_manager.sh start

# 临时配置（仅当次有效）
export HOST=0.0.0.0
export PORT=8080
./service_manager.sh start
```

### 服务状态说明

#### 完整状态输出示例

```bash
$ ./service_manager.sh status

=== PPT MCP服务状态总览 ===
绑定地址: 0.0.0.0
基础端口: 60

✅ HTTP服务正在运行
   PID: 12345
   端口: 60
   地址: http://0.0.0.0:60
   日志: /path/to/service_http.log

✅ SSE服务正在运行
   PID: 12346
   端口: 61
   地址: http://0.0.0.0:61
   日志: /path/to/service_sse.log

✅ HTTP-STREAM服务正在运行
   PID: 12347
   端口: 62
   地址: http://0.0.0.0:62
   日志: /path/to/service_stream.log

=== 总体状态 ===
运行中服务: 3/3
🎉 所有服务正常运行

完整访问地址:
  HTTP:        http://0.0.0.0:60
  SSE:         http://0.0.0.0:61
  HTTP-STREAM: http://0.0.0.0:62
```

#### 状态码说明

- **✅ 正常运行**: 服务进程存在且响应正常
- **❌ 已停止**: 服务未运行或进程不存在
- **⚠️ 部分运行**: 部分服务正常，部分服务异常

## 🗂️ 文件管理

### PID文件管理

```bash
# PID文件位置
service_http.pid      # HTTP服务进程ID
service_sse.pid       # SSE服务进程ID
service_stream.pid    # HTTP-STREAM服务进程ID

# 手动清理PID文件（如果进程已死但文件存在）
rm -f service_*.pid
```

### 日志文件管理

```bash
# 日志文件位置
service_http.log      # HTTP服务日志
service_sse.log       # SSE服务日志
service_stream.log    # HTTP-STREAM服务日志

# 日志文件操作
tail -f service_http.log          # 实时查看HTTP日志
tail -n 100 service_sse.log       # 查看SSE最近100行日志
grep "ERROR" service_*.log        # 搜索所有错误日志

# 日志清理（谨慎操作）
> service_http.log                # 清空HTTP日志
> service_sse.log                 # 清空SSE日志
> service_stream.log              # 清空HTTP-STREAM日志
```

## 🌐 服务访问地址

### 三协议并发访问

```bash
# 状态页面（GET请求）
http://localhost:60/        # HTTP服务状态
http://localhost:61/        # SSE服务状态
http://localhost:62/        # HTTP-STREAM服务状态

# API端点
http://localhost:60/mcp           # HTTP API (POST)
http://localhost:61/sse           # SSE连接端点 (GET)
http://localhost:61/messages/     # SSE消息端点 (POST)
http://localhost:62/mcp           # HTTP-STREAM API (POST)
```

### 外部访问配置

```bash
# 绑定所有接口以允许外部访问
HOST=0.0.0.0 ./service_manager.sh start

# 访问地址将变为
http://your-server-ip:60/    # HTTP服务
http://your-server-ip:61/    # SSE服务
http://your-server-ip:62/    # HTTP-STREAM服务
```

## 🔧 高级配置

### 自定义启动脚本

```bash
#!/bin/bash
# custom_start.sh - 自定义启动脚本

# 设置环境变量
export HOST=0.0.0.0
export PORT=8080

# 启动服务
./service_manager.sh start

# 验证启动
sleep 5
./service_manager.sh status
```

### 服务监控脚本

```bash
#!/bin/bash
# monitor.sh - 服务监控脚本

check_service() {
    local service_name=$1
    local port=$2
    
    if curl -f -s "http://localhost:$port/" > /dev/null; then
        echo "✅ $service_name (端口$port) - 正常"
        return 0
    else
        echo "❌ $service_name (端口$port) - 异常"
        return 1
    fi
}

echo "=== 服务健康检查 $(date) ==="
check_service "HTTP" 60
check_service "SSE" 61
check_service "HTTP-STREAM" 62

# 如果有服务异常，自动重启
if ! check_service "HTTP" 60 || ! check_service "SSE" 61 || ! check_service "HTTP-STREAM" 62; then
    echo "检测到服务异常，正在重启..."
    ./service_manager.sh restart
fi
```

### 自动重启cron配置

```bash
# 添加到crontab实现定期检查
# crontab -e

# 每5分钟检查一次服务状态，异常时自动重启
*/5 * * * * /path/to/pptMcpSeriver/monitor.sh >> /var/log/ppt-mcp-monitor.log 2>&1

# 每天凌晨重启服务（可选）
0 2 * * * /path/to/pptMcpSeriver/service_manager.sh restart
```

## 🔍 故障排除

### 常见问题诊断

#### 1. 服务启动失败

```bash
# 诊断步骤
./service_manager.sh logs        # 查看错误日志
./service_manager.sh status      # 检查详细状态
ps aux | grep python             # 检查Python进程

# 常见原因
# - 端口被占用
sudo netstat -tlnp | grep -E ":(60|61|62)\s"

# - uv环境问题
uv --version
uv sync

# - 权限问题
chmod +x service_manager.sh
ls -la service_*.*
```

#### 2. 部分服务异常

```bash
# 查看特定服务日志
./service_manager.sh logs http
./service_manager.sh logs sse
./service_manager.sh logs stream

# 重启特定服务（手动方式）
# 先停止所有服务
./service_manager.sh stop

# 然后重新启动
./service_manager.sh start
```

#### 3. 外部访问问题

```bash
# 检查防火墙设置
sudo firewall-cmd --list-ports
sudo ufw status

# 开放端口
sudo firewall-cmd --permanent --add-port=60-62/tcp
sudo firewall-cmd --reload

# 或使用ufw
sudo ufw allow 60:62/tcp
```

#### 4. 性能问题

```bash
# 检查系统资源
top -p $(cat service_http.pid),$(cat service_sse.pid),$(cat service_stream.pid)
free -h
df -h

# 检查网络连接
ss -tlnp | grep -E ":(60|61|62)\s"
```

### 诊断命令集合

```bash
# 完整诊断脚本
#!/bin/bash
echo "=== 系统信息 ==="
uname -a
python3 --version
uv --version

echo "=== 服务状态 ==="
./service_manager.sh status

echo "=== 进程信息 ==="
ps aux | grep "python.*main.py"

echo "=== 端口监听 ==="
sudo netstat -tlnp | grep -E ":(60|61|62)\s"

echo "=== 磁盘空间 ==="
df -h .

echo "=== 内存使用 ==="
free -h

echo "=== 最近日志 ==="
./service_manager.sh logs | tail -20
```

## 📊 传统systemd服务管理

### systemd服务配置

```bash
# 服务文件位置
/etc/systemd/system/ppt-mcp-sse.service

# 基本操作
sudo systemctl status ppt-mcp-sse    # 查看状态
sudo systemctl start ppt-mcp-sse     # 启动服务
sudo systemctl stop ppt-mcp-sse      # 停止服务
sudo systemctl restart ppt-mcp-sse   # 重启服务
sudo systemctl enable ppt-mcp-sse    # 开机自启
sudo systemctl disable ppt-mcp-sse   # 禁用自启

# 日志查看
journalctl -u ppt-mcp-sse -f         # 实时日志
journalctl -u ppt-mcp-sse -n 50      # 最近50条
journalctl -u ppt-mcp-sse --since today # 今天的日志
```

### systemd服务配置文件示例

```ini
[Unit]
Description=PPT MCP Server - iFlytek Zhiwen Service
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/pptMcpSeriver
ExecStart=/usr/local/bin/uv run python main.py sse --host 0.0.0.0 --port 60
Restart=always
RestartSec=10
Environment=PATH=/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
```

## 🚦 最佳实践

### 生产环境部署建议

1. **使用三协议服务管理器**
   ```bash
   # 推荐使用service_manager.sh进行生产部署
   HOST=0.0.0.0 PORT=60 ./service_manager.sh start
   ```

2. **配置监控和自动重启**
   ```bash
   # 设置cron监控
   */5 * * * * /path/to/monitor.sh
   ```

3. **日志管理**
   ```bash
   # 定期清理大日志文件
   find . -name "service_*.log" -size +100M -exec truncate -s 50M {} \;
   ```

4. **备份配置**
   ```bash
   # 定期备份重要文件
   tar -czf backup-$(date +%Y%m%d).tar.gz \
     service_manager.sh main.py pyproject.toml
   ```

### 开发环境建议

1. **使用单协议模式**
   ```bash
   # 开发时可以只启动需要的协议
   uv run python main.py http --port 60
   ```

2. **实时日志监控**
   ```bash
   # 开发时实时查看日志
   ./service_manager.sh logs http -f
   ```

## 📚 相关文档

- **[主文档](../README.md)** - 项目总览和快速开始
- **[部署指南](./DEPLOYMENT_GUIDE.md)** - 详细部署说明
- **[使用指南](./USAGE.md)** - 完整功能使用说明
- **[HTTP Stream指南](./HTTP_STREAM_GUIDE.md)** - HTTP Stream协议说明
- **[API密钥池指南](./API_KEY_POOL_GUIDE.md)** - 多密钥配置说明

---

**🌟 新特性**: 现已支持三协议同时启动模式，提供HTTP、SSE、HTTP-STREAM三种访问方式，满足不同场景需求！
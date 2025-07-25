# 部署指南

本指南提供了讯飞智文PPT生成服务的完整部署说明，现已支持三协议同时启动模式。

## 🚀 快速开始

### 方案1：UV专用自动部署（推荐新用户）

使用专门的uv环境自动化部署脚本：

```bash
# 1. 基本部署（生成三协议服务管理器）
bash uv_deploy.sh

# 2. 启动所有三种协议服务
./service_manager.sh start

# 3. 验证部署
./service_manager.sh status
```

### 方案2：开箱即用部署（推荐服务器）

直接使用独立的三协议服务管理器：

```bash
# 1. 下载服务管理器
wget https://raw.githubusercontent.com/your-repo/pptMcpSeriver/main/service_manager.sh
chmod +x service_manager.sh

# 2. 确保uv环境（如果没有）
curl -LsSf https://astral.sh/uv/install.sh | sh

# 3. 启动所有服务（HTTP:60, SSE:61, HTTP-STREAM:62）
./service_manager.sh start
```

### 方案3：手动部署（开发调试）

如果需要手动部署：

```bash
# 1. 安装uv和Python 3.13+
curl -LsSf https://astral.sh/uv/install.sh | sh
uv python install 3.13

# 2. 同步依赖
uv sync

# 3. 启动单个服务（调试用）
uv run python main.py http --host 0.0.0.0 --port 60
```

## 📋 核心特性

### 🌟 三协议同时启动

现在可以同时启动三种传输协议：

- **HTTP** (端口60): RESTful API接口
- **SSE** (端口61): Server-Sent Events实时通信  
- **HTTP Stream** (端口62): MCP 2025-03-26标准协议

### 🔧 服务管理特性

- **独立脚本**: service_manager.sh不依赖配置文件
- **PID管理**: 每个协议独立的进程ID管理
- **日志分离**: 各协议独立的日志文件
- **环境变量**: HOST/PORT灵活配置
- **状态监控**: 完整的服务状态检查

## 🛠️ 部署方案对比

| 特性 | uv_deploy.sh | service_manager.sh | 手动部署 |
|------|--------------|-------------------|----------|
| **UV环境管理** | ✅ 专用安装 | ✅ 使用现有 | ⚠️ 手动配置 |
| **三协议同启** | ✅ 自动生成 | ✅ 开箱即用 | ❌ 不支持 |
| **配置文件** | ✅ 自动生成 | ❌ 无需配置 | ⚠️ 手动配置 |
| **错误处理** | ✅ 完整验证 | ✅ 智能检测 | ⚠️ 基础处理 |
| **进程管理** | ✅ PID文件 | ✅ PID文件 | ❌ 无管理 |
| **服务监控** | ✅ 状态检查 | ✅ 详细状态 | ❌ 无监控 |
| **适用场景** | 首次部署 | 服务器运维 | 开发调试 |

## 📁 部署后目录结构

```
pptMcpSeriver/
├── main.py                     # 主服务文件
├── service_manager.sh          # 🌟 三协议服务管理器
├── service_http.pid            # HTTP服务PID文件
├── service_sse.pid             # SSE服务PID文件  
├── service_stream.pid          # HTTP-STREAM服务PID文件
├── service_http.log            # HTTP服务日志
├── service_sse.log             # SSE服务日志
├── service_stream.log          # HTTP-STREAM服务日志
├── pyproject.toml              # 项目配置
├── uv.lock                     # 依赖锁定
└── ...                         # 其他文件
```

## 🚀 详细部署步骤

### 步骤1：环境准备

```bash
# 检查系统环境
uname -a                    # 查看系统信息
python3 --version          # 检查Python版本

# 安装uv（如果没有）
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.cargo/env    # 重新加载环境变量
```

### 步骤2：获取项目

```bash
# 方案A：完整项目部署
git clone <repository-url>
cd pptMcpSeriver
bash uv_deploy.sh

# 方案B：仅服务管理器
wget https://raw.githubusercontent.com/your-repo/pptMcpSeriver/main/service_manager.sh
chmod +x service_manager.sh
```

### 步骤3：启动服务

```bash
# 启动所有三种协议服务
./service_manager.sh start

# 查看启动状态
./service_manager.sh status
```

### 步骤4：验证部署

```bash
# 检查端口监听
sudo netstat -tlnp | grep -E ":(60|61|62)\s"

# 访问三个协议端点
curl http://localhost:60/    # HTTP状态页面
curl http://localhost:61/    # SSE状态页面  
curl http://localhost:62/    # HTTP-STREAM状态页面

# 测试API调用
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

## 🔧 服务管理

### 基本管理命令

```bash
# 启动所有服务
./service_manager.sh start

# 停止所有服务
./service_manager.sh stop

# 重启所有服务
./service_manager.sh restart

# 查看详细状态
./service_manager.sh status
```

### 日志管理

```bash
# 查看所有服务日志
./service_manager.sh logs

# 查看特定服务日志
./service_manager.sh logs http     # HTTP服务
./service_manager.sh logs sse      # SSE服务
./service_manager.sh logs stream   # HTTP-STREAM服务

# 实时查看日志
./service_manager.sh logs http -f
```

### 环境变量配置

```bash
# 自定义绑定地址
HOST=0.0.0.0 ./service_manager.sh start

# 自定义基础端口（会自动分配+1, +2）
PORT=8080 ./service_manager.sh start
# 启动: HTTP(8080), SSE(8081), HTTP-STREAM(8082)

# 组合配置
HOST=127.0.0.1 PORT=9000 ./service_manager.sh start
```

## 🌐 网络配置

### 防火墙设置

```bash
# Linux (firewalld) - 开放三协议端口
sudo firewall-cmd --permanent --add-port=60-62/tcp
sudo firewall-cmd --reload

# Linux (ufw) - 开放端口范围
sudo ufw allow 60:62/tcp

# 检查防火墙状态
sudo firewall-cmd --list-ports    # firewalld
sudo ufw status                   # ufw
```

### 端口规划

| 服务类型 | 默认端口 | 自定义示例 | 说明 |
|----------|----------|------------|------|
| HTTP | 60 | PORT=8080 → 8080 | 基础端口 |
| SSE | 61 | PORT=8080 → 8081 | 基础端口+1 |
| HTTP-STREAM | 62 | PORT=8080 → 8082 | 基础端口+2 |

### 访问地址

部署成功后的访问地址：

```bash
# 本地访问
http://localhost:60/     # HTTP服务状态页面
http://localhost:61/     # SSE服务状态页面
http://localhost:62/     # HTTP-STREAM服务状态页面

# API端点
http://localhost:60/mcp           # HTTP API
http://localhost:61/sse           # SSE连接
http://localhost:61/messages/     # SSE消息
http://localhost:62/mcp           # HTTP-STREAM API
```

## 🔍 故障排除

### 常见问题与解决方案

#### 1. 服务启动失败

**症状**: 部分或全部服务启动失败

```bash
# 诊断步骤
./service_manager.sh logs        # 查看错误日志
./service_manager.sh status      # 检查服务状态

# 常见原因与解决
# 原因1：端口被占用
sudo netstat -tlnp | grep -E ":(60|61|62)\s"
PORT=8080 ./service_manager.sh start

# 原因2：uv环境问题
uv --version
uv sync

# 原因3：Python版本不匹配
uv python install 3.13
```

#### 2. API调用失败

**症状**: curl请求返回错误或超时

```bash
# 检查服务是否运行
./service_manager.sh status

# 检查端口监听
sudo ss -tlnp | grep -E ":(60|61|62)\s"

# 测试本地连接
telnet localhost 60
telnet localhost 61  
telnet localhost 62
```

#### 3. 日志文件权限问题

**症状**: 无法写入日志文件

```bash
# 检查文件权限
ls -la service_*.log service_*.pid

# 修复权限
chmod 644 service_*.log
chmod 644 service_*.pid
chown $(whoami):$(whoami) service_*.*
```

#### 4. 内存或CPU占用过高

**症状**: 服务占用资源过多

```bash
# 查看进程资源占用
ps aux | grep "python.*main.py"
top -p $(cat service_http.pid),$(cat service_sse.pid),$(cat service_stream.pid)

# 重启服务释放资源
./service_manager.sh restart
```

### 诊断工具

```bash
# 系统环境检查
uv --version                     # 检查uv版本
uv python list                   # 查看可用Python版本
uv sync --dry-run               # 检查依赖状态

# 网络连接测试
curl -I http://localhost:60/     # HTTP连接测试
curl -I http://localhost:61/     # SSE连接测试
curl -I http://localhost:62/     # HTTP-STREAM连接测试

# 服务功能测试
cd tests
python test_api_pool.py          # API密钥池测试
python test_sse.py              # SSE传输测试
```

## 🔄 更新和维护

### 服务更新

```bash
# 1. 停止所有服务
./service_manager.sh stop

# 2. 更新代码
git pull origin main

# 3. 同步依赖
uv sync

# 4. 重启服务
./service_manager.sh start

# 5. 验证更新
./service_manager.sh status
```

### 配置更新

```bash
# 更新API密钥池配置
# 编辑 main.py 中的 API_KEY_POOL

# 重启服务应用配置
./service_manager.sh restart
```

### 备份和恢复

```bash
# 创建备份
tar -czf ppt-mcp-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  main.py service_manager.sh pyproject.toml uv.lock \
  service_*.log service_*.pid

# 恢复备份
tar -xzf ppt-mcp-backup-*.tar.gz
./service_manager.sh start
```

## 🚦 健康检查

### 服务监控脚本

```bash
#!/bin/bash
# health_check.sh - 服务健康检查脚本

check_service() {
    local service_name=$1
    local port=$2
    
    if curl -f -s "http://localhost:$port/" > /dev/null; then
        echo "✅ $service_name (端口$port) - 正常"
    else
        echo "❌ $service_name (端口$port) - 异常"
        return 1
    fi
}

echo "=== PPT MCP服务健康检查 ==="
check_service "HTTP" 60
check_service "SSE" 61  
check_service "HTTP-STREAM" 62
```

### 自动重启配置

```bash
# 添加到crontab实现自动监控重启
# crontab -e
*/5 * * * * /path/to/pptMcpSeriver/health_check.sh || /path/to/pptMcpSeriver/service_manager.sh restart
```

## 📞 技术支持

### 获取帮助的优先级

1. **查看日志**: `./service_manager.sh logs`
2. **检查状态**: `./service_manager.sh status`  
3. **运行诊断**: 使用tests目录下的测试脚本
4. **查看文档**: 参考相关文档链接
5. **提交Issue**: GitHub Issue提供详细信息

### 提交Issue时需要的信息

```bash
# 收集系统信息
echo "=== 系统信息 ==="
uname -a
python3 --version
uv --version

echo "=== 服务状态 ==="
./service_manager.sh status

echo "=== 服务日志 ==="
./service_manager.sh logs | tail -50

echo "=== 端口监听 ==="
sudo netstat -tlnp | grep -E ":(60|61|62)\s"
```

## 📚 相关文档

- **[主文档](../README.md)** - 项目总览和快速开始
- **[使用指南](./USAGE.md)** - 完整功能使用说明
- **[服务管理指南](./SERVICE_GUIDE.md)** - 详细服务管理说明
- **[HTTP Stream指南](./HTTP_STREAM_GUIDE.md)** - HTTP Stream协议说明
- **[API密钥池指南](./API_KEY_POOL_GUIDE.md)** - 多密钥配置说明
- **[UV部署指南](../UV_DEPLOY_README.md)** - uv专用脚本说明

---

**🌟 新特性**: 支持三协议同时启动，一次部署即可同时提供HTTP、SSE和HTTP-STREAM三种访问方式！
# 讯飞智文PPT服务 - 跨平台自动部署指南

## 🚀 快速开始

### 方案一：一键简化部署 (推荐新手)

适用于快速测试和简单部署场景：

```bash
# 下载并运行简化部署脚本
curl -o quick_deploy.sh https://your-server/quick_deploy.sh
bash quick_deploy.sh
```

或者直接复制粘贴脚本内容后运行。

### 方案二：完整自动部署 (推荐生产环境)

支持跨平台自动适配，包含完整的系统检测和服务管理：

```bash
# 下载并运行完整部署脚本
curl -o auto_deploy.sh https://your-server/auto_deploy.sh
bash auto_deploy.sh
```

## 🔧 跨平台支持

### 自动检测功能

部署脚本会自动检测以下系统环境：

- **操作系统**: Linux, macOS, Windows (Cygwin/MSYS)
- **Linux发行版**: Ubuntu, CentOS, Debian 等
- **Python版本**: 自动选择 python3 或 python
- **包管理器**: 优先使用 uv，回退到 pip
- **文件编码**: 自动转换 Windows CRLF 到 Unix LF

### 系统特定配置

| 系统 | 工作目录 | 服务管理 | 端口配置 |
|------|----------|----------|----------|
| Linux | `/www/wwwroot/xunfeiPpt` | systemd 或通用脚本 | 60 |
| macOS | `~/xunfeiPpt` | 通用脚本 | 60 |
| Windows | `/c/xunfeiPpt` | 通用脚本 | 60 |

## 📋 部署脚本说明

### auto_deploy.sh (完整版)

功能特性：
- ✅ 跨平台系统检测
- ✅ 自动文件编码转换
- ✅ Python环境智能适配
- ✅ 依赖自动安装
- ✅ systemd服务配置 (Linux)
- ✅ 通用服务管理脚本
- ✅ 服务状态检测
- ✅ 彩色日志输出
- ✅ 错误处理和恢复

使用场景：
- 生产环境部署
- 需要systemd服务管理
- 多平台支持需求
- 复杂环境配置

### quick_deploy.sh (简化版)

功能特性：
- ✅ 快速一键部署
- ✅ 基础环境检测
- ✅ 简化版MCP服务器
- ✅ 基本服务管理
- ✅ 最小依赖需求

使用场景：
- 快速测试
- 开发环境
- 学习和演示
- 简单部署需求

## 🛠️ 手动部署步骤

如果自动部署遇到问题，可以按以下步骤手动部署：

### 1. 环境准备

```bash
# 创建工作目录
mkdir -p /www/wwwroot/xunfeiPpt
cd /www/wwwroot/xunfeiPpt

# 检查Python环境
python3 --version || python --version
```

### 2. 安装依赖

```bash
# 使用pip安装
pip3 install mcp requests requests-toolbelt starlette uvicorn

# 或使用uv安装（如果可用）
uv pip install mcp requests requests-toolbelt starlette uvicorn
```

### 3. 创建main.py

复制完整的main.py文件内容，或从仓库下载。

### 4. 启动服务

```bash
# 直接启动
python3 main.py sse --host 0.0.0.0 --port 60

# 后台启动
nohup python3 main.py sse --host 0.0.0.0 --port 60 > service.log 2>&1 &
```

## 🔍 故障排除

### 常见问题

#### 1. 文件编码问题

**症状**: `line 2: $'\r': command not found`

**解决方案**:
```bash
# 使用dos2unix转换
dos2unix deploy.sh

# 或使用sed转换
sed -i 's/\r$//' deploy.sh

# 或使用tr转换
tr -d '\r' < deploy.sh > deploy_fixed.sh
```

#### 2. Python版本问题

**症状**: 语法错误或模块缺失

**解决方案**:
```bash
# 检查Python版本
python3 --version

# 如果是旧版本Python，需要修改f-string语法
# 脚本会自动处理，也可以手动替换：
# f"text {var}" -> "text {}".format(var)
```

#### 3. 端口被占用

**症状**: 端口60已被使用

**解决方案**:
```bash
# 检查端口占用
sudo netstat -tlnp | grep 60
sudo ss -tlnp | grep 60

# 停止占用端口的进程或更换端口
python3 main.py sse --host 0.0.0.0 --port 8060
```

#### 4. 权限问题

**症状**: 无法创建文件或目录

**解决方案**:
```bash
# 给脚本执行权限
chmod +x auto_deploy.sh
chmod +x quick_deploy.sh

# 使用sudo运行（如果需要）
sudo bash auto_deploy.sh
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
# 使用服务管理脚本
bash service_manager.sh start
bash service_manager.sh stop
bash service_manager.sh restart
bash service_manager.sh status

# 或使用简化版脚本
bash service.sh start
bash service.sh stop
bash service.sh status
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

#### 检查防火墙状态
```bash
# firewalld
sudo firewall-cmd --list-ports

# ufw
sudo ufw status
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

## 📊 性能监控

### 查看服务日志

```bash
# systemd服务日志
journalctl -u ppt-mcp-sse -f

# 直接启动的服务日志
tail -f /www/wwwroot/xunfeiPpt/service.log
```

### API密钥池状态

可通过MCP工具查看密钥池使用情况：
- 总密钥数量
- 活跃密钥数量
- 并发使用情况
- 错误率统计

## 🔄 更新和维护

### 更新服务

```bash
# 停止服务
bash service_manager.sh stop

# 更新代码
# 复制新的main.py文件

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

1. 检查系统兼容性
2. 查看错误日志
3. 使用诊断脚本
4. 查阅故障排除指南
5. 联系技术支持

## 📝 更新日志

### v2.0 - 跨平台自动部署
- ✅ 新增跨平台自动检测
- ✅ 新增文件编码自动转换
- ✅ 新增Python环境智能适配
- ✅ 新增简化部署脚本
- ✅ 改进错误处理和恢复
- ✅ 新增彩色日志输出

### v1.0 - 基础部署
- ✅ Linux systemd服务支持
- ✅ 基础MCP服务器功能
- ✅ API密钥池管理
- ✅ SSE传输协议支持

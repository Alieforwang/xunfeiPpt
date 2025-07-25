# 讯飞智文PPT生成服务 - 脚本工具集

本目录包含项目的所有部署、管理和配置脚本。

## 📁 脚本文件说明

### 🚀 部署脚本

#### `auto_deploy.sh` - 完整自动部署脚本
**推荐用于生产环境**

功能特性：
- ✅ 跨平台系统检测 (Linux/macOS/Windows)
- ✅ 自动文件编码转换 (CRLF→LF)
- ✅ Python环境智能适配
- ✅ 依赖自动安装 (uv/pip)
- ✅ systemd服务配置 (Linux)
- ✅ 通用服务管理脚本
- ✅ 彩色日志输出
- ✅ 错误处理和恢复

使用方法：
```bash
bash scripts/auto_deploy.sh
```

#### `quick_deploy.sh` - 简化一键部署脚本
**推荐用于测试和开发环境**

功能特性：
- ✅ 快速一键部署
- ✅ 基础环境检测
- ✅ 简化版MCP服务器
- ✅ 最小依赖需求

使用方法：
```bash
bash scripts/quick_deploy.sh
```

#### `deploy.sh` - 原始部署脚本
**已更新为跨平台兼容版本**

包含完整的main.py内容，适用于需要完整代码部署的场景。

### 🛠️ 服务管理脚本

#### `install_service.sh` - systemd服务安装脚本
**仅适用于Linux系统**

功能：
- 创建systemd服务配置
- 设置服务权限和安全配置
- 启用开机自启动
- 启动服务并检查状态

使用方法：
```bash
sudo bash scripts/install_service.sh
```

#### `uninstall_service.sh` - systemd服务卸载脚本
**仅适用于Linux系统**

功能：
- 停止并禁用服务
- 删除服务配置文件
- 清理systemd缓存

使用方法：
```bash
sudo bash scripts/uninstall_service.sh
```

### ⚙️ 配置文件

#### `ppt-mcp-sse.service` - systemd服务配置
**Linux systemd服务单元文件**

配置说明：
- 服务名称：ppt-mcp-sse
- 工作目录：/www/wwwroot/xunfeiPpt
- 启动命令：python main.py sse --host 0.0.0.0 --port 60
- 自动重启：always
- 重启间隔：10秒

## 📖 文档

#### `DEPLOYMENT_GUIDE.md` - 完整部署指南
详细的跨平台部署指南，包含：
- 快速开始指南
- 跨平台支持说明
- 详细部署步骤
- 故障排除指南
- 网络配置说明

#### `SERVICE_README.md` - 服务管理说明
systemd服务管理的详细说明，包含：
- 安装和卸载步骤
- 服务管理命令
- 日志查看方法
- 防火墙配置
- 故障排除

## 🎯 使用场景

### 场景一：生产环境部署
```bash
# 1. 使用完整自动部署脚本
bash scripts/auto_deploy.sh

# 2. 验证服务状态
systemctl status ppt-mcp-sse

# 3. 查看服务日志
journalctl -u ppt-mcp-sse -f
```

### 场景二：开发测试环境
```bash
# 1. 使用简化部署脚本
bash scripts/quick_deploy.sh

# 2. 检查服务状态
bash scripts/service.sh status

# 3. 查看运行日志
tail -f /www/wwwroot/xunfeiPpt/service.log
```

### 场景三：手动服务管理
```bash
# 安装systemd服务
sudo bash scripts/install_service.sh

# 管理服务
sudo systemctl start ppt-mcp-sse
sudo systemctl stop ppt-mcp-sse
sudo systemctl restart ppt-mcp-sse

# 卸载服务
sudo bash scripts/uninstall_service.sh
```

## 🔧 脚本特性对比

| 特性 | auto_deploy.sh | quick_deploy.sh | deploy.sh |
|------|----------------|-----------------|-----------|
| 跨平台检测 | ✅ 完整 | ⚠️ 基础 | ❌ 无 |
| 文件编码修复 | ✅ 自动 | ✅ 自动 | ❌ 无 |
| Python环境适配 | ✅ 智能 | ✅ 基础 | ⚠️ 基础 |
| systemd服务 | ✅ 完整 | ❌ 无 | ✅ 完整 |
| 通用服务管理 | ✅ 包含 | ✅ 基础 | ❌ 无 |
| 错误处理 | ✅ 完善 | ⚠️ 基础 | ⚠️ 基础 |
| 彩色日志 | ✅ 支持 | ❌ 无 | ❌ 无 |
| 文件引用 | ✅ 引用主目录 | ❌ 内嵌代码 | ❌ 内嵌代码 |
| 适用场景 | 生产环境 | 测试/开发 | 原始部署 |

## 🌍 跨平台支持

### 自动检测功能

脚本会自动检测以下环境：
- **操作系统**: Linux, macOS, Windows (Cygwin/MSYS)
- **Linux发行版**: Ubuntu, CentOS, Debian 等
- **Python命令**: python3, python
- **包管理器**: uv, pip
- **文件编码**: CRLF, LF

### 系统特定配置

| 系统 | 工作目录 | 服务管理 | Python命令 |
|------|----------|----------|-------------|
| Linux | `/www/wwwroot/xunfeiPpt` | systemd | python3 优先 |
| macOS | `~/xunfeiPpt` | 通用脚本 | python3 优先 |
| Windows | `/c/xunfeiPpt` | 通用脚本 | python3 优先 |

## 🔍 故障排除

### 常见问题

1. **脚本权限问题**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **文件编码问题**
   ```bash
   # 脚本会自动处理，或手动转换
   dos2unix scripts/auto_deploy.sh
   ```

3. **Python版本兼容**
   ```bash
   # 脚本会自动选择合适的Python命令
   # 手动检查
   python3 --version || python --version
   ```

4. **systemd服务权限**
   ```bash
   # 需要root权限
   sudo bash scripts/install_service.sh
   ```

### 诊断步骤

1. **检查脚本语法**
   ```bash
   bash -n scripts/auto_deploy.sh
   ```

2. **查看执行日志**
   ```bash
   # 启用详细输出
   bash -x scripts/auto_deploy.sh
   ```

3. **验证文件编码**
   ```bash
   file scripts/auto_deploy.sh
   ```

## 🚀 更新和维护

### 更新脚本
```bash
# 拉取最新版本
git pull origin main

# 确保脚本可执行
chmod +x scripts/*.sh

# 重新部署
bash scripts/auto_deploy.sh
```

### 备份配置
```bash
# 备份当前配置
tar -czf ppt-mcp-backup-$(date +%Y%m%d).tar.gz /www/wwwroot/xunfeiPpt
```

## 📞 技术支持

如遇到脚本相关问题：
1. 查看相关文档 (DEPLOYMENT_GUIDE.md, SERVICE_README.md)
2. 检查系统兼容性
3. 运行诊断命令
4. 查看错误日志
5. 提交Issue报告

---

**注意**: 运行脚本前请确保有足够的权限，Linux系统的systemd服务配置需要root权限。
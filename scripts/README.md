# 脚本工具集

本目录包含项目的所有部署、管理和配置脚本。

## 📁 脚本文件

### 🚀 部署脚本

- **`auto_deploy.sh`** - 完整自动部署脚本（推荐生产环境）
  - 跨平台系统检测 (Linux/macOS/Windows)
  - Python环境智能适配 (优先Python 3.13+)
  - uv/pip包管理器自动选择
  - systemd服务配置 (Linux)
  - 彩色日志输出和错误处理

- **`quick_deploy.sh`** - 简化一键部署脚本（推荐测试环境）  
  - 快速部署和基础环境检测
  - 简化版MCP服务器
  - 最小依赖需求

- **`deploy.sh`** - 原始部署脚本
  - 包含完整main.py内容的单文件部署

### 🛠️ 服务管理脚本

- **`install_service.sh`** - systemd服务安装脚本（Linux）
  - 自动创建和配置systemd服务
  - 设置服务权限和安全配置
  - 启用开机自启动

- **`uninstall_service.sh`** - systemd服务卸载脚本（Linux）
  - 停止并禁用服务
  - 清理配置文件和systemd缓存

### ⚙️ 配置文件

- **`ppt-mcp-sse.service`** - systemd服务配置模板

## 🎯 快速使用

### 生产环境部署
```bash
bash scripts/auto_deploy.sh
```

### 测试环境部署  
```bash
bash scripts/quick_deploy.sh
```

### 手动服务管理
```bash
# 安装systemd服务
sudo bash scripts/install_service.sh

# 卸载systemd服务
sudo bash scripts/uninstall_service.sh
```

## 🔧 脚本特性对比

| 特性 | auto_deploy.sh | quick_deploy.sh | deploy.sh |
|------|----------------|-----------------|-----------|
| 跨平台检测 | ✅ 完整 | ⚠️ 基础 | ❌ 无 |
| Python 3.13+支持 | ✅ 自动安装 | ✅ 检测 | ⚠️ 基础 |
| uv包管理器 | ✅ 智能选择 | ✅ 支持 | ❌ 无 |
| systemd服务 | ✅ 完整 | ❌ 无 | ✅ 完整 |
| 错误处理 | ✅ 完善 | ⚠️ 基础 | ⚠️ 基础 |
| 彩色日志 | ✅ 支持 | ❌ 无 | ❌ 无 |
| 适用场景 | 生产环境 | 测试/开发 | 原始部署 |

## 📖 详细文档

- [部署指南](../docs/DEPLOYMENT_GUIDE.md) - 完整的部署说明和故障排除
- [服务管理指南](../docs/SERVICE_GUIDE.md) - systemd服务管理详细说明
- [使用指南](../docs/USAGE.md) - 完整的功能使用说明

## 🔍 故障排除

常见问题的快速解决方法：

1. **权限问题**: `chmod +x scripts/*.sh`
2. **Python版本**: 脚本会自动安装Python 3.13+
3. **服务启动失败**: 使用 `../fix_deployment.sh` 修复
4. **文件编码**: 脚本会自动处理CRLF→LF转换

详细的故障排除指南请参考[部署指南](../docs/DEPLOYMENT_GUIDE.md)。
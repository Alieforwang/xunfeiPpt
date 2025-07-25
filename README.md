# 讯飞智文PPT生成服务 - MCP Server

[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://python.org)
[![MCP](https://img.shields.io/badge/MCP-Compatible-green.svg)](https://github.com/microsoft/mcp)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

基于讯飞智文API的PPT生成服务MCP Server，支持多种传输协议和跨平台自动部署。

## 🚀 快速开始

### 一键部署（推荐）

```bash
# 下载并运行自动部署脚本
curl -o auto_deploy.sh https://your-server/scripts/auto_deploy.sh
bash auto_deploy.sh
```

### 简化部署（适合测试）

```bash
# 下载并运行简化部署脚本
curl -o quick_deploy.sh https://your-server/scripts/quick_deploy.sh
bash quick_deploy.sh
```

### 手动部署

```bash
# 1. 克隆项目
git clone <repository-url>
cd pptMcpSeriver

# 2. 安装依赖
pip install -r requirements.txt

# 3. 启动服务
python main.py sse --host 0.0.0.0 --port 60
```

## 📁 项目结构

```
pptMcpSeriver/
├── main.py                     # 主服务文件
├── README.md                   # 项目说明
├── pyproject.toml             # 项目配置
├── uv.lock                    # 依赖锁定文件
├── fixed_sse_transport.py     # SSE传输修复
├── http_stream_transport.py   # HTTP Stream传输
├── scripts/                   # 部署脚本目录
│   ├── auto_deploy.sh         # 完整自动部署脚本
│   ├── quick_deploy.sh        # 简化一键部署脚本
│   ├── deploy.sh              # 原部署脚本
│   ├── install_service.sh     # systemd服务安装
│   ├── uninstall_service.sh   # systemd服务卸载
│   ├── ppt-mcp-sse.service    # systemd服务配置
│   ├── DEPLOYMENT_GUIDE.md    # 部署指南
│   └── SERVICE_README.md      # 服务管理说明
├── docs/                      # 文档目录
│   ├── README.md              # 文档索引
│   ├── USAGE.md               # 使用说明
│   ├── API_KEY_POOL_GUIDE.md  # API密钥池指南
│   ├── HTTP_STREAM_GUIDE.md   # HTTP Stream指南
│   └── SSE_ISSUE_ANALYSIS.md  # SSE问题分析
└── tests/                     # 测试目录
    ├── README.md              # 测试说明
    ├── test_api_pool.py       # API池测试
    ├── test_sse.py            # SSE传输测试
    └── ...                    # 其他测试文件
```

## ✨ 核心功能

### 🎯 PPT生成工具
- **模板管理**: 获取和筛选PPT模板
- **内容生成**: 基于文本创建PPT
- **大纲生成**: 智能生成PPT结构
- **文档导入**: 支持从文档创建大纲
- **ReACT工作流**: 智能代理推理和行动模式

### 🔄 传输协议支持
- **stdio**: 标准输入输出（默认）
- **HTTP**: RESTful API接口
- **SSE**: Server-Sent Events实时通信
- **HTTP Stream**: 流式传输协议

### 🔑 API密钥池管理
- **负载均衡**: 自动轮询和最优选择
- **故障转移**: 自动切换可用密钥
- **并发控制**: 密钥级别的并发限制
- **统计监控**: 使用情况和错误率跟踪

### 🌍 跨平台支持
- **操作系统**: Linux, macOS, Windows
- **自动检测**: 系统环境智能识别
- **文件编码**: 自动处理换行符兼容性
- **Python适配**: 智能选择Python命令

## 🛠️ 部署选项

### 🔧 自动部署脚本对比

| 特性 | auto_deploy.sh | quick_deploy.sh |
|------|----------------|-----------------|
| 跨平台检测 | ✅ | ⚠️ 基础 |
| 文件编码修复 | ✅ | ✅ |
| Python环境适配 | ✅ | ✅ |
| systemd服务 | ✅ | ❌ |
| 通用服务管理 | ✅ | ✅ |
| 错误处理 | ✅ | ⚠️ 基础 |
| 彩色日志 | ✅ | ❌ |
| 适用场景 | 生产环境 | 测试/开发 |

### 🚀 部署步骤

1. **选择部署方式**
   - 生产环境：使用 `scripts/auto_deploy.sh`
   - 测试环境：使用 `scripts/quick_deploy.sh`
   - 手动部署：参考文档

2. **运行部署脚本**
   ```bash
   # 进入项目目录
   cd pptMcpSeriver
   
   # 运行完整部署
   bash scripts/auto_deploy.sh
   
   # 或运行简化部署
   bash scripts/quick_deploy.sh
   ```

3. **验证部署**
   ```bash
   # 检查服务状态
   bash scripts/service_manager.sh status
   
   # 访问状态页面
   curl http://localhost:60
   ```

## 📖 使用说明

### 🔌 连接MCP服务器

#### SSE连接（推荐）
```bash
# 访问状态页面
http://localhost:60/

# SSE端点
http://localhost:60/sse

# 消息端点
http://localhost:60/messages/
```

#### HTTP连接
```bash
# HTTP端点
http://localhost:50/mcp

# 状态页面
http://localhost:50/
```

### 🛠️ 可用工具

1. **get_theme_list** - 获取PPT模板列表
2. **create_ppt_task** - 创建PPT生成任务
3. **get_task_progress** - 查询任务进度
4. **create_outline** - 创建PPT大纲
5. **create_outline_by_doc** - 从文档创建大纲
6. **create_ppt_by_outline** - 根据大纲创建PPT
7. **create_full_ppt_workflow** - ReACT模式完整工作流
8. **get_api_pool_stats** - 获取API密钥池状态

### 📋 工作流示例

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "create_full_ppt_workflow",
    "arguments": {
      "topic": "人工智能在教育中的应用",
      "style_preference": "简约",
      "industry": "教育培训",
      "author": "AI助手",
      "enable_figures": true,
      "enable_notes": true
    }
  }
}
```

## 🔧 服务管理

### Linux systemd服务
```bash
# 服务状态
systemctl status ppt-mcp-sse

# 启动/停止/重启
sudo systemctl start ppt-mcp-sse
sudo systemctl stop ppt-mcp-sse
sudo systemctl restart ppt-mcp-sse

# 查看日志
journalctl -u ppt-mcp-sse -f
```

### 通用服务管理
```bash
# 使用服务管理脚本
bash scripts/service_manager.sh start
bash scripts/service_manager.sh stop
bash scripts/service_manager.sh restart
bash scripts/service_manager.sh status
```

## 🌐 网络配置

### 防火墙设置
```bash
# Linux (firewalld)
sudo firewall-cmd --permanent --add-port=60/tcp
sudo firewall-cmd --reload

# Linux (ufw)
sudo ufw allow 60
```

### 端口说明
- **50**: HTTP传输协议
- **60**: SSE传输协议（默认）
- **70**: HTTP Stream传输协议

## 📚 文档

- **[部署指南](scripts/DEPLOYMENT_GUIDE.md)** - 完整部署说明
- **[服务管理](scripts/SERVICE_README.md)** - 服务管理指南
- **[使用说明](docs/USAGE.md)** - 详细使用教程
- **[API密钥池](docs/API_KEY_POOL_GUIDE.md)** - 密钥池配置指南
- **[HTTP Stream](docs/HTTP_STREAM_GUIDE.md)** - HTTP Stream使用指南

## 🔍 故障排除

### 常见问题

1. **文件编码错误**
   ```bash
   # 转换文件编码
   dos2unix script.sh
   # 或
   sed -i 's/\r$//' script.sh
   ```

2. **端口被占用**
   ```bash
   # 检查端口占用
   sudo netstat -tlnp | grep 60
   # 或使用其他端口
   python main.py sse --port 8060
   ```

3. **Python版本兼容性**
   ```bash
   # 检查Python版本
   python3 --version
   # 脚本会自动处理f-string兼容性
   ```

### 诊断工具

项目提供了多个诊断脚本帮助排查问题：

```bash
# API测试
python tests/test_api_pool.py

# SSE连接测试
python tests/test_sse.py

# 完整功能测试
python tests/test_simple_ppt.py
```

## 🤝 贡献

欢迎提交Issue和Pull Request来改进项目！

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🔗 相关链接

- [MCP官方文档](https://github.com/microsoft/mcp)
- [讯飞智文API](https://zwapi.xfyun.cn/)
- [项目文档](docs/)

---

**注意**: 使用前请确保已获得有效的讯飞智文API密钥，并在`main.py`中配置`API_KEY_POOL`。

## ✨ 核心特性

### 🤖 AI工作流支持
- **ReACT模式** - Reasoning and Acting智能代理工作流
- **自动化流程** - 模板选择→大纲生成→PPT创建→进度监控
- **智能推理** - 基于讯飞星火大模型的内容分析和优化

### 🔗 多协议支持
- **stdio** - 标准输入输出（默认，适合Claude Desktop）
- **http** - HTTP协议（端口8000，适合Web应用）
- **sse** - Server-Sent Events（端口8001，已保留兼容）
- **~~http-stream~~** - ~~HTTP Stream传输（端口8002，测试中）~~

### 🛠️ 完整工具集
- 🎨 获取PPT模板列表
- 📝 创建PPT生成任务
- 📊 查询任务进度
- 📋 创建PPT大纲
- 📄 从文档创建PPT大纲
- 🎯 根据大纲创建PPT
- **🚀 ReACT模式完整工作流（推荐）**
- **🔑 API密钥池状态监控（新增）**

## 🚀 快速开始

### 1. 安装依赖
```bash
uv sync
```

### 2. 选择启动模式

#### 🤖 ReACT模式（推荐AI代理使用）
```bash
python main.py http  # 暂时使用HTTP协议
```
- **端口**: 8000
- **访问**: http://localhost:8000/mcp
- **特点**: 支持ReACT工作流，稳定可靠

#### 🖥️ Claude Desktop集成
```bash
python main.py stdio
```
- **配置**: 添加到Claude Desktop MCP配置
- **特点**: 本地集成，性能最佳

#### 🌐 Web应用集成
```bash
python main.py http --port 8000
```
- **端口**: 8000
- **访问**: http://localhost:8000/mcp
- **特点**: RESTful API，广泛兼容

### 3. 测试连接
```bash
# 测试HTTP + ReACT工作流
cd tests
python test_simple_ppt.py  # 或使用基础测试
```

## 🤖 ReACT工作流详解

### 什么是ReACT模式？
ReACT（Reasoning and Acting）是一种AI代理工作模式，结合推理和行动：

```
🧠 THINK → 🎯 ACT → 👁️ OBSERVE → 🔄 ITERATE
```

### 工作流程
1. **🧠 THINK（思考）** - 分析用户需求，规划PPT结构
2. **🎯 ACT（行动）** - 调用API获取模板、生成大纲、创建PPT
3. **👁️ OBSERVE（观察）** - 检查每步结果，验证质量
4. **🔄 ITERATE（迭代）** - 根据结果优化，确保输出质量

### 使用示例
```bash
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "create_full_ppt_workflow",
      "arguments": {
        "topic": "人工智能在教育中的应用",
        "style_preference": "简约",
        "industry": "教育培训",
        "author": "AI助手"
      }
    }
  }'
```

## 🔧 集成配置

### Claude Desktop配置
```json
{
  "mcpServers": {
    "pptmcpseriver": {
      "command": "python",
      "args": ["D:/pptMcpSeriver/main.py", "stdio"],
      "cwd": "D:/pptMcpSeriver"
    }
  }
}
```

### Cherry Studio配置

#### stdio模式
```json
{
  "name": "讯飞智文PPT生成服务",
  "command": "python",
  "args": ["D:/pptMcpSeriver/main.py", "stdio"],
  "cwd": "D:/pptMcpSeriver"
}
```

#### HTTP协议配置（推荐）
```json
{
  "name": "PPT生成服务-HTTP",
  "type": "http",
  "url": "http://localhost:8000/mcp"
}
```

#### ~~HTTP Stream模式（测试中）~~
```json
{
  "name": "PPT生成服务-HTTP-Stream",
  "type": "http-stream", 
  "url": "http://localhost:8002/mcp"
}
```

## 📊 协议对比

| 协议 | 状态 | 适用场景 | ReACT支持 | 端口 |
|------|------|----------|-----------|------|
| **stdio** | ✅ 稳定 | Claude Desktop集成 | ✅ | - |
| **http** | ✅ **推荐** | **Web应用、AI代理** | **✅** | **8000** |
| **sse** | ⚠️ 兼容 | 向后兼容 | ✅ | 8001 |
| **~~http-stream~~** | 🧪 **测试中** | ~~实时通信~~ | ~~✅~~ | ~~8002~~ |

## 🛠️ 工具说明

### 基础工具
- **get_theme_list** - 获取PPT模板列表
- **create_ppt_task** - 直接创建PPT任务
- **get_task_progress** - 查询生成进度
- **create_outline** - 生成PPT大纲
- **create_outline_by_doc** - 从文档生成大纲
- **create_ppt_by_outline** - 基于大纲创建PPT

### 🚀 高级工具
- **create_full_ppt_workflow** - ReACT模式完整工作流
  - 自动模板选择
  - 智能大纲生成
  - 自动PPT创建
  - 实时进度监控
  - 详细执行日志

## 🔍 状态监控

### 状态页面
- **HTTP**: http://localhost:8000/
- **SSE**: http://localhost:8001/
- **HTTP Stream**: http://localhost:8002/

### API端点
- **HTTP**: http://localhost:8000/mcp
- **SSE**: http://localhost:8001/sse
- **HTTP Stream**: http://localhost:8002/mcp

## 🎯 使用建议

### 选择协议指南
1. **AI代理/智能助手** → 使用 `http`（稳定推荐）
2. **Claude Desktop** → 使用 `stdio`
3. **Web应用集成** → 使用 `http`
4. **向后兼容** → 保留 `sse`

### ReACT工作流优势
- 🧠 **智能决策** - 自动选择最佳模板和参数
- 🔄 **自动重试** - 失败时自动调整策略
- 📋 **详细日志** - 完整记录执行过程
- ⚡ **高效率** - 一次调用完成整个流程

## 🔧 开发说明

### 项目结构
```
pptMcpSeriver/
├── main.py                          # 主程序
├── http_stream_transport.py         # HTTP Stream实现
├── fixed_sse_transport.py           # SSE修复实现
├── pyproject.toml                   # 依赖配置
├── tests/                           # 测试文件
│   ├── README.md                    # 测试说明
│   ├── test_http_stream.py          # HTTP Stream测试
│   ├── test_simple_ppt.py           # 基础功能测试
│   └── diagnose_api.py              # API诊断工具
└── docs/                            # 项目文档
    ├── README.md                    # 文档目录
    ├── USAGE.md                     # 详细使用说明
    ├── HTTP_STREAM_GUIDE.md         # HTTP Stream指南
    └── SSE_ISSUE_ANALYSIS.md        # SSE问题分析
```

### 技术栈
- **MCP SDK**: Python官方SDK
- **AI模型**: 讯飞星火认知大模型
- **API服务**: 讯飞智文PPT生成API
- **Web框架**: Starlette + Uvicorn

## 📈 版本历程
- **v0.1.0** - 基础功能，stdio/http协议
- **v0.1.1** - 修复create_outline，添加SSE支持
- **v0.2.0** - 🚀 **新增API密钥池 + ReACT工作流**

## ⚡ 快速测试

```bash
# 1. 启动HTTP模式服务器（推荐）
python main.py http

# 2. 测试API密钥池功能
cd tests
python test_api_pool.py

# 3. 查看状态
curl http://localhost:8000/
```

## 📚 文档资源

- 📖 [详细使用说明](./docs/USAGE.md) - 完整功能指南
- 🔑 [API密钥池配置](./docs/API_KEY_POOL_GUIDE.md) - **🆕 多密钥并发配置**
- 🌐 [HTTP Stream指南](./docs/HTTP_STREAM_GUIDE.md) - 最新传输协议
- 🔧 [SSE问题分析](./docs/SSE_ISSUE_ANALYSIS.md) - 兼容性修复
- 🧪 [测试说明](./tests/README.md) - 测试工具使用

## 🤝 支持与反馈

如遇问题请检查：
1. 端口是否被占用
2. 依赖是否正确安装  
3. API密钥是否有效

更多帮助请查看：
- [完整文档](./docs/) - 详细技术文档
- [测试工具](./tests/) - 功能验证和调试
- [故障排除](./docs/USAGE.md#注意事项) - 常见问题解决
# 讯飞智文PPT生成服务 - MCP Server

[![Python](https://img.shields.io/badge/Python-3.13+-blue.svg)](https://python.org)
[![MCP](https://img.shields.io/badge/MCP-Compatible-green.svg)](https://github.com/microsoft/mcp)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![UV](https://img.shields.io/badge/UV-Powered-orange.svg)](https://docs.astral.sh/uv/)

基于讯飞智文API的PPT生成服务MCP Server，支持多种传输协议和UV专用自动化部署。现已支持三协议同时启动模式！

## 🚀 快速开始

### 一键自动部署（推荐）

```bash
# 运行uv专用自动部署脚本（生成三协议服务管理器）
bash uv_deploy.sh

# 启动所有三种协议服务
./service_manager.sh start

# 查看服务状态
./service_manager.sh status
```

### 直接使用服务管理器（开箱即用）

```bash
# 下载最新服务管理器
wget https://raw.githubusercontent.com/Alieforwang/xunfeiPpt/main/service_manager.sh
chmod +x service_manager.sh

# 启动所有服务（HTTP端口60，SSE端口61，HTTP-STREAM端口62）
./service_manager.sh start
```

### 手动部署

```bash
# 1. 克隆项目
git clone https://github.com/Alieforwang/xunfeiPpt.git
cd xunfeiPpt

# 2. 安装uv和Python 3.13+
curl -LsSf https://astral.sh/uv/install.sh | sh
uv python install 3.13

# 3. 同步依赖
uv sync

# 4. 启动单个服务（调试用）
uv run python main.py http --host 0.0.0.0 --port 60
```

## 📚 完整文档

- **[uv部署指南](./UV_DEPLOY_README.md)** - 专用uv脚本详细使用说明
- **[使用指南](./docs/USAGE.md)** - 完整的功能使用说明
- **[部署指南](./docs/DEPLOYMENT_GUIDE.md)** - 详细的部署说明和故障排除
- **[服务管理](./docs/SERVICE_GUIDE.md)** - 服务管理指南
- **[HTTP Stream指南](./docs/HTTP_STREAM_GUIDE.md)** - 新的传输协议说明
- **[API密钥池](./docs/API_KEY_POOL_GUIDE.md)** - 多密钥配置指南

## ⚡ 核心特性

### 🎯 PPT生成功能
- **智能PPT模板选择** - 支持风格、行业、颜色筛选
- **自动内容大纲生成** - 基于AI的结构化大纲生成
- **文档转PPT功能** - 支持PDF、DOC、DOCX、TXT、MD
- **完整的ReACT工作流** - THINK → ACT → OBSERVE → ITERATE
- **任务进度追踪** - 实时监控PPT生成状态
- **API密钥池管理** - 多密钥负载均衡和故障转移

### 🌐 传输协议支持（三协议同启）
- **http** - HTTP协议（端口60，Web应用集成）
- **sse** - Server-Sent Events（端口61，实时通信）
- **http-stream** - HTTP Stream Transport（端口62，MCP 2025-03-26）
- **stdio** - 标准输入输出（单独模式，Claude Desktop集成）

### 🔧 部署特性
- **三协议并发** - HTTP(60) + SSE(61) + HTTP-STREAM(62) 同时运行
- **开箱即用** - 独立service_manager.sh脚本，无需配置文件
- **专用uv环境管理** - 按MCP+uv官网标准
- **Python 3.13+ 环境自动安装**
- **标准pyproject.toml配置和uv sync依赖管理**
- **环境变量配置** - HOST/PORT灵活设置
- **PID文件管理** - 独立进程控制和监控

## 📁 项目结构

```
pptMcpSeriver/
├── main.py                     # 主服务文件（支持所有协议）
├── service_manager.sh          # 🌟 三协议服务管理脚本（开箱即用）
├── uv_deploy.sh               # UV专用部署脚本
├── README.md                   # 项目说明
├── pyproject.toml             # 项目配置
├── uv.lock                    # 依赖锁定文件
├── fixed_sse_transport.py     # SSE传输修复
├── http_stream_transport.py   # HTTP Stream传输
├── docs/                      # 文档目录
│   ├── README.md              # 文档索引
│   ├── USAGE.md               # 使用说明
│   ├── DEPLOYMENT_GUIDE.md    # 部署指南
│   ├── SERVICE_GUIDE.md       # 服务管理指南
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
- **API密钥池**: 支持多密钥负载均衡和故障转移

### 🔄 三协议并发支持
- **HTTP** (端口60): RESTful API接口
- **SSE** (端口61): Server-Sent Events实时通信
- **HTTP Stream** (端口62): 流式传输协议
- **stdio**: 标准输入输出（独立模式）

### 🔑 API密钥池管理
- **负载均衡**: 自动轮询和最优选择
- **故障转移**: 自动切换可用密钥
- **并发控制**: 密钥级别的并发限制
- **统计监控**: 使用情况和错误率跟踪

## 🛠️ 部署选项

### 🔧 部署方案对比

| 特性 | uv_deploy.sh | service_manager.sh | 手动部署 |
|------|--------------|-------------------|----------|
| UV环境管理 | ✅ 专用 | ✅ 使用现有 | ⚠️ 手动 |
| 三协议同启 | ✅ 自动生成 | ✅ 开箱即用 | ❌ |
| 配置文件依赖 | ✅ 自动生成 | ❌ 独立运行 | ⚠️ 手动 |
| 错误处理 | ✅ 完整 | ✅ 完整 | ⚠️ 基础 |
| 进程管理 | ✅ PID文件 | ✅ PID文件 | ❌ |
| 适用场景 | 首次部署 | 日常使用 | 开发调试 |

### 🚀 部署步骤

#### 方案1：UV专用部署（推荐新用户）
```bash
# 1. 克隆项目
git clone https://github.com/Alieforwang/xunfeiPpt.git
cd xunfeiPpt

# 2. 运行UV部署脚本
bash uv_deploy.sh

# 3. 启动三协议服务
./service_manager.sh start
```

#### 方案2：开箱即用（推荐服务器）
```bash
# 1. 下载服务管理器
wget https://raw.githubusercontent.com/your-repo/pptMcpSeriver/main/service_manager.sh
chmod +x service_manager.sh

# 2. 确保uv环境已安装
curl -LsSf https://astral.sh/uv/install.sh | sh

# 3. 启动服务
./service_manager.sh start
```

#### 验证部署
```bash
# 检查所有服务状态
./service_manager.sh status

# 访问三个协议端点
curl http://localhost:60    # HTTP
curl http://localhost:61    # SSE
curl http://localhost:62    # HTTP-STREAM
```

## 📖 使用说明

### 🔌 连接MCP服务器

#### 三协议并发访问
```bash
# HTTP协议（端口60）
http://localhost:60/mcp
http://localhost:60/        # 状态页面

# SSE协议（端口61）
http://localhost:61/sse     # SSE端点
http://localhost:61/messages/ # 消息端点
http://localhost:61/        # 状态页面

# HTTP Stream协议（端口62）
http://localhost:62/mcp     # HTTP Stream端点
http://localhost:62/        # 状态页面
```

#### 环境变量配置
```bash
# 自定义绑定地址和端口
HOST=0.0.0.0 PORT=8080 ./service_manager.sh start
# 将启动: HTTP(8080), SSE(8081), HTTP-STREAM(8082)
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

### 📋 ReACT工作流示例

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

### 三协议服务管理（推荐）
```bash
# 启动所有三种协议服务
./service_manager.sh start

# 停止所有服务
./service_manager.sh stop

# 重启所有服务
./service_manager.sh restart

# 查看所有服务状态
./service_manager.sh status

# 查看服务日志
./service_manager.sh logs          # 所有服务日志
./service_manager.sh logs http     # HTTP服务日志
./service_manager.sh logs sse      # SSE服务日志
./service_manager.sh logs stream   # HTTP-STREAM服务日志
./service_manager.sh logs http -f  # 实时查看HTTP日志
```

### 单协议启动（调试用）
```bash
# 启动单个协议（用于调试）
uv run python main.py http --host 0.0.0.0 --port 60
uv run python main.py sse --host 0.0.0.0 --port 61
uv run python main.py http-stream --host 0.0.0.0 --port 62
uv run python main.py stdio  # Claude Desktop集成
```

## 🌐 网络配置

### 防火墙设置
```bash
# Linux (firewalld)
sudo firewall-cmd --permanent --add-port=60-62/tcp
sudo firewall-cmd --reload

# Linux (ufw)
sudo ufw allow 60:62/tcp
```

### 端口说明（三协议模式）
- **60**: HTTP传输协议（基础端口）
- **61**: SSE传输协议（基础端口+1）
- **62**: HTTP Stream传输协议（基础端口+2）

### 端口自定义
```bash
# 使用环境变量自定义基础端口
PORT=8080 ./service_manager.sh start
# 将启动: HTTP(8080), SSE(8081), HTTP-STREAM(8082)

# 自定义绑定地址
HOST=127.0.0.1 ./service_manager.sh start
```

## 🔍 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查三协议端口占用
   sudo netstat -tlnp | grep -E ":(60|61|62)\s"
   
   # 使用其他端口
   PORT=8080 ./service_manager.sh start
   ```

2. **服务启动失败**
   ```bash
   # 查看具体错误日志
   ./service_manager.sh logs
   
   # 检查uv环境
   uv --version
   uv sync
   ```

3. **文件权限错误**
   ```bash
   # 确保脚本可执行
   chmod +x service_manager.sh
   chmod +x uv_deploy.sh
   ```

4. **API密钥配置**
   ```bash
   # 检查main.py中的API_KEY_POOL配置
   # 确保至少有一个有效的讯飞智文API密钥
   ```

### 诊断工具

```bash
# API测试
python tests/test_api_pool.py

# SSE连接测试
python tests/test_sse.py

# 完整功能测试
python tests/test_simple_ppt.py
```

## 🔗 集成配置

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

### Cherry Studio配置（HTTP协议）
```json
{
  "name": "PPT生成服务-HTTP",
  "type": "http",
  "url": "http://localhost:60/mcp"
}
```

## 📊 协议对比

| 协议 | 状态 | 适用场景 | ReACT支持 | 端口 |
|------|------|----------|-----------|------|
| **http** | ✅ **推荐** | **Web应用、AI代理** | **✅** | **60** |
| **sse** | ✅ 稳定 | 实时通信、流式响应 | ✅ | 61 |
| **http-stream** | ✅ 稳定 | 新标准、高性能 | ✅ | 62 |
| **stdio** | ✅ 稳定 | Claude Desktop集成 | ✅ | - |

## 📚 文档资源

- 📖 [详细使用说明](./docs/USAGE.md) - 完整功能指南
- 🔑 [API密钥池配置](./docs/API_KEY_POOL_GUIDE.md) - 多密钥并发配置
- 🌐 [HTTP Stream指南](./docs/HTTP_STREAM_GUIDE.md) - 最新传输协议
- 🔧 [服务管理指南](./docs/SERVICE_GUIDE.md) - 服务管理详解
- 🧪 [测试说明](./tests/README.md) - 测试工具使用

## 🎯 使用建议

### 选择协议指南
1. **AI代理/智能助手** → 使用 `http`（稳定推荐）
2. **Claude Desktop** → 使用 `stdio`
3. **Web应用集成** → 使用 `http`
4. **实时通信需求** → 使用 `sse`
5. **最新标准支持** → 使用 `http-stream`

### ReACT工作流优势
- 🧠 **智能决策** - 自动选择最佳模板和参数
- 🔄 **自动重试** - 失败时自动调整策略
- 📋 **详细日志** - 完整记录执行过程
- ⚡ **高效率** - 一次调用完成整个流程

## 🚀 快速测试

```bash
# 1. 启动三协议服务
./service_manager.sh start

# 2. 测试API密钥池功能
cd tests
python test_api_pool.py

# 3. 查看服务状态
./service_manager.sh status

# 4. 访问状态页面
curl http://localhost:60/
curl http://localhost:61/
curl http://localhost:62/
```

## 🤝 贡献

欢迎提交Issue和Pull Request来改进项目！

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📦 仓库地址

- **GitHub**: [https://github.com/Alieforwang/xunfeiPpt.git](https://github.com/Alieforwang/xunfeiPpt.git)
- **Gitee**: [https://gitee.com/xiao-wang-oh/xunfei-ppt.git](https://gitee.com/xiao-wang-oh/xunfei-ppt.git)

## 🔗 相关链接

- [MCP官方文档](https://github.com/microsoft/mcp)
- [讯飞智文API](https://zwapi.xfyun.cn/)
- [UV官方文档](https://docs.astral.sh/uv/)

---

**注意**: 使用前请确保已获得有效的讯飞智文API密钥，并在`main.py`中配置`API_KEY_POOL`。

**🌟 新特性**: 现已支持三协议同时启动，一次部署即可同时提供HTTP、SSE和HTTP-STREAM三种访问方式！
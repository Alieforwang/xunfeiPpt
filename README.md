# xunfeiPpt

# 讯飞智文PPT生成服务 MCP Server

基于讯飞星火大模型的智能PPT生成服务，支持多种传输协议的MCP Server实现。

## ✨ 核心特性

### 🤖 AI工作流支持
- **ReACT模式** - Reasoning and Acting智能代理工作流
- **自动化流程** - 模板选择→大纲生成→PPT创建→进度监控
- **智能推理** - 基于讯飞星火大模型的内容分析和优化

### 🔗 多协议支持
- **stdio** - 标准输入输出（默认，适合Claude Desktop）
- **http** - HTTP协议（端口8000，适合Web应用）
- **sse** - Server-Sent Events（端口8001，已保留兼容）
- **🆕 http-stream** - HTTP Stream传输（端口8002，**推荐ReACT模式使用**）

### 🛠️ 完整工具集
- 🎨 获取PPT模板列表
- 📝 创建PPT生成任务
- 📊 查询任务进度
- 📋 创建PPT大纲
- 📄 从文档创建PPT大纲
- 🎯 根据大纲创建PPT
- **🚀 ReACT模式完整工作流（推荐）**

## 🚀 快速开始

### 1. 安装依赖
```bash
uv sync
```

### 2. 选择启动模式

#### 🤖 ReACT模式（推荐AI代理使用）
```bash
python main.py http-stream
```
- **端口**: 8002
- **访问**: http://localhost:8002/mcp
- **特点**: 支持实时工作流反馈，适合AI代理

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
# 测试HTTP Stream + ReACT工作流
cd tests
python test_http_stream.py
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
curl -X POST http://localhost:8002/mcp \
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

#### HTTP Stream模式（支持ReACT）
```json
{
  "name": "PPT生成服务-ReACT模式",
  "type": "http-stream",
  "url": "http://localhost:8002/mcp"
}
```

## 📊 协议对比

| 协议 | 状态 | 适用场景 | ReACT支持 | 端口 |
|------|------|----------|-----------|------|
| **stdio** | ✅ 稳定 | Claude Desktop集成 | ✅ | - |
| **http** | ✅ 稳定 | Web应用、RESTful | ✅ | 8000 |
| **sse** | ⚠️ 兼容 | 向后兼容 | ✅ | 8001 |
| **http-stream** | 🚀 **推荐** | **AI代理、ReACT工作流** | **🎯 优化** | **8002** |

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
1. **AI代理/智能助手** → 使用 `http-stream`
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
- **v0.2.0** - 🚀 **新增HTTP Stream + ReACT工作流**

## ⚡ 快速测试

```bash
# 1. 启动ReACT模式服务器
python main.py http-stream

# 2. 测试工作流
cd tests
python test_http_stream.py

# 3. 查看状态
curl http://localhost:8002/
```

## 📚 文档资源

- 📖 [详细使用说明](./docs/USAGE.md) - 完整功能指南
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
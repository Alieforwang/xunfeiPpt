# 讯飞智文PPT生成服务MCP Server

基于讯飞星火大模型的智能PPT生成服务，支持多种传输协议的MCP Server实现。

## 功能特性

### 支持的PPT生成功能
- 获取PPT模板列表
- 创建PPT生成任务
- 查询任务进度
- 创建PPT大纲
- 从文档创建PPT大纲
- 根据大纲创建PPT
- **🆕 ReACT模式完整工作流** - 智能代理推荐使用

### 支持的传输协议
- **stdio** - 标准输入输出，适合本地集成和命令行工具
- **http** - HTTP协议，适合Web应用和远程调用
- **sse** - Server-Sent Events，支持实时双向通信 (已废弃)
- **🆕 http-stream** - HTTP Stream Transport，MCP 2025-03-26规范 ✅ **推荐使用**

## 快速开始

### 1. 安装依赖
```bash
uv sync
```

### 2. 启动服务器

#### stdio模式（默认）
```bash
python main.py stdio
# 或者
python main.py
```

#### HTTP模式
```bash
# 默认端口8000
python main.py http

# 自定义端口
python main.py http --port 8080

# 绑定所有网络接口
python main.py http --host 0.0.0.0 --port 8000
```

#### SSE模式（已废弃，不推荐）
```bash
# 默认端口8001
python main.py sse

# 自定义端口
python main.py sse --port 8002
```

#### 🆕 HTTP Stream模式（推荐）
```bash
# 默认端口8002
python main.py http-stream

# 自定义端口
python main.py http-stream --port 8003

# 绑定所有网络接口
python main.py http-stream --host 0.0.0.0 --port 8002
```

### 3. 查看帮助
```bash
python main.py --help
```

## 🆕 ReACT模式工作流

新增的 `create_full_ppt_workflow` 工具支持 Reasoning and Acting (ReACT) 模式，为AI代理提供完整的PPT生成工作流：

### ReACT执行流程

1. **🧠 THINK (思考阶段)**
   - 分析用户的PPT需求和主题
   - 确定适合的PPT风格和行业类别
   - 规划内容结构和要点

2. **🎯 ACT (行动阶段)**
   - 调用 `get_theme_list` 获取适合的PPT模板
   - 调用 `create_outline` 生成结构化大纲
   - 调用 `create_ppt_by_outline` 基于大纲生成PPT
   - 调用 `get_task_progress` 监控生成进度

3. **👁️ OBSERVE (观察阶段)**
   - 检查每步的执行结果
   - 验证模板选择的合理性
   - 确认大纲内容的完整性
   - 监控PPT生成状态直到完成

4. **🔄 ITERATE (迭代优化)**
   - 根据结果调整参数
   - 必要时重新选择模板或修改大纲
   - 确保最终输出质量

### ReACT工作流使用示例

```bash
# HTTP Stream模式下的ReACT工作流调用
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
        "requirements": "面向大学生，需要包含实际案例",
        "style_preference": "简约",
        "industry": "教育培训",
        "author": "AI助手",
        "enable_figures": true,
        "enable_notes": true,
        "enable_search": false
      }
    }
  }'
```

## 使用示例

### HTTP协议使用示例

启动HTTP服务器后，可以通过POST请求调用MCP工具：

```bash
# 获取PPT模板列表
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "get_theme_list",
      "arguments": {
        "pay_type": "free",
        "page_size": 5
      }
    }
  }'

# 创建PPT大纲
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "create_outline",
      "arguments": {
        "text": "机器学习中的贝叶斯方法完整解析",
        "language": "cn",
        "search": true
      }
    }
  }'
```

### 🆕 HTTP Stream协议使用示例

HTTP Stream协议提供更好的性能和功能，适合现代MCP应用：

#### 发送请求
```bash
# 1. 发送请求（自动创建会话）
curl -X POST http://localhost:8002/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "create_outline",
      "arguments": {
        "text": "人工智能发展历程",
        "search": true
      }
    }
  }'
```

#### 接收响应流
```bash
# 2. 接收响应（使用会话ID）
curl -H "x-session-id: [从POST响应头获取]" \
  http://localhost:8002/mcp
```

#### JavaScript客户端示例
```javascript
// 连接HTTP Stream端点
const eventSource = new EventSource('http://localhost:8002/mcp', {
  headers: {
    'x-session-id': sessionId
  }
});

eventSource.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('收到响应:', data);
};

eventSource.onerror = function(event) {
  console.error('连接错误:', event);
};
```

### SSE协议使用示例（已废弃）

**注意：SSE协议已在MCP 2024-11-05版本中废弃，推荐使用HTTP Stream。**

```bash
# 通过POST请求发送MCP命令
curl -X POST http://localhost:8001/messages/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "create_outline",
      "arguments": {
        "text": "人工智能发展历程",
        "search": true
      }
    }
  }'
```

### 状态页面

各种协议模式下，可以访问以下地址查看服务器状态：

- **HTTP模式**: http://localhost:8000/
- **SSE模式**: http://localhost:8001/ (已废弃)
- **🆕 HTTP Stream模式**: http://localhost:8002/
- **MCP端点**: 
  - HTTP: http://localhost:8000/mcp
  - SSE: http://localhost:8001/sse (已废弃)
  - 🆕 HTTP Stream: http://localhost:8002/mcp

## 配置说明

### API密钥
API密钥已内置在代码中，无需额外配置。

### 端口配置
- **stdio**: 无需端口配置
- **http**: 默认端口8000
- **sse**: 默认端口8001 (已废弃)
- **🆕 http-stream**: 默认端口8002

### 日志级别
支持以下日志级别：
- DEBUG - 详细调试信息
- INFO - 一般信息（默认）
- WARNING - 警告信息
- ERROR - 错误信息

使用示例：
```bash
python main.py http-stream --log-level DEBUG
```

## 集成指南

### 与Claude Desktop集成
将以下配置添加到Claude Desktop的MCP配置文件中：

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

### 与Cherry Studio集成

#### stdio模式配置
```json
{
  "name": "讯飞智文PPT生成服务",
  "command": "python",
  "args": ["D:/pptMcpSeriver/main.py", "stdio"],
  "cwd": "D:/pptMcpSeriver"
}
```

#### 🆕 HTTP Stream模式配置
如果Cherry Studio支持HTTP Stream连接：
```json
{
  "name": "PPT生成服务-HTTP-Stream",
  "type": "http-stream",
  "url": "http://localhost:8002/mcp"
}
```

### 作为Web服务使用
- **HTTP模式**: 适合RESTful API调用，简单易用
- **🆕 HTTP Stream模式**: 适合需要实时通信的应用，支持流式响应，**推荐使用**
- **SSE模式**: 已废弃，不推荐使用

## 协议对比

| 协议 | 状态 | 适用场景 | 特点 | 端口 |
|------|------|----------|------|------|
| stdio | ✅ 稳定 | 本地集成、Claude Desktop | 完整MCP协议支持，性能最佳 | - |
| http | ✅ 稳定 | Web应用、RESTful调用 | 简单易用，广泛兼容 | 8000 |
| sse | ❌ 已废弃 | ~~实时应用、流式响应~~ | ~~支持双向通信~~ | 8001 |
| **http-stream** | ✅ **推荐** | **现代MCP应用、实时通信** | **最新规范、更好性能、断线重连** | **8002** |

## 工具说明

### 1. get_theme_list
获取可用的PPT模板列表
- 支持按付费类型、风格、颜色、行业筛选
- 返回模板ID，用于后续PPT生成

### 2. create_ppt_task
直接创建PPT生成任务
- 需要提供内容描述和模板ID
- 返回任务ID，用于查询进度

### 3. get_task_progress
查询PPT生成任务进度
- 提供任务ID
- 返回进度状态和下载地址

### 4. create_outline ✅ 已修复
根据文本生成PPT大纲
- 支持联网搜索
- 生成的大纲可用于后续PPT生成
- 使用form-data格式，已修复参数问题

### 5. create_outline_by_doc
从文档生成PPT大纲
- 支持PDF、DOC、DOCX、TXT、MD格式
- 可通过URL或本地路径上传

### 6. create_ppt_by_outline ✅ 已修复
根据大纲创建PPT
- 使用预生成的大纲
- 支持自动配图和演讲备注
- 已修复API兼容性问题，使用直接创建方式

### 🆕 7. create_full_ppt_workflow (ReACT模式)
完整的PPT生成工作流，支持ReACT模式
- **智能代理推荐使用**
- 自动执行：模板选择 → 大纲生成 → PPT创建 → 进度监控
- 提供详细的执行日志和错误处理
- 支持自定义风格、行业、配图等参数
- 返回完整的工作流执行报告

## 🆕 新功能亮点

### HTTP Stream Transport (MCP 2025-03-26)
- ✅ **单端点架构** - 简化客户端实现
- ✅ **会话管理** - 支持多客户端并发
- ✅ **断线重连** - Last-Event-ID恢复机制
- ✅ **心跳机制** - 保持连接活跃
- ✅ **安全防护** - CORS和DNS重绑定保护

### ReACT模式工作流
- 🧠 **智能推理** - 分析用户需求，选择最佳策略
- 🎯 **自动执行** - 按步骤执行复杂任务流程
- 👁️ **实时观察** - 监控每步执行结果和状态
- 🔄 **自适应优化** - 根据结果调整后续步骤
- 📋 **详细日志** - 完整记录执行过程和决策逻辑

## 注意事项

1. 文档上传限制：文件大小≤10M，字数≤8000字
2. API调用频率限制根据讯飞开放平台规则
3. **推荐使用HTTP Stream模式**以获得最佳性能和功能
4. stdio模式适合本地集成，HTTP Stream模式适合Web应用
5. 生产环境建议使用stdio或http-stream模式
6. SSE模式已废弃，建议迁移到HTTP Stream模式

## 开发说明

项目基于MCP Python SDK开发，核心文件：
- `main.py` - 主程序文件，包含MCP服务器和PPT生成逻辑
- `http_stream_transport.py` - HTTP Stream传输实现
- `fixed_sse_transport.py` - SSE传输修复版本（向后兼容）
- `pyproject.toml` - 项目配置和依赖管理
- `USAGE.md` - 使用说明文档

如需扩展功能，可以修改 `AIPPTClient` 类或添加新的MCP工具处理函数。

### 版本更新
- v0.1.0: 基础功能，支持stdio和http协议
- v0.1.1: 修复create_outline接口，添加SSE协议支持
- **v0.2.0**: 添加HTTP Stream支持和ReACT工作流，修复PPT生成bug

## 测试和调试

### 测试HTTP Stream功能
```bash
python test_http_stream.py
```

### 测试ReACT工作流
```bash
# 启动HTTP Stream服务器
python main.py http-stream

# 在另一个终端运行测试
python test_http_stream.py
```

### 诊断API问题
```bash
python diagnose_api.py
```
# 讯飞智文PPT生成服务MCP Server - 使用指南

基于讯飞星火大模型的智能PPT生成服务，支持三协议同时启动的MCP Server实现。

## 🌟 功能特性

### 🎯 PPT生成功能
- **智能模板选择** - 支持风格、行业、颜色筛选
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

### 🔧 服务管理特性
- **三协议并发** - 同时提供三种访问方式
- **独立进程管理** - 每个协议独立的PID和日志
- **环境变量配置** - HOST/PORT灵活设置
- **开箱即用** - service_manager.sh无需配置文件

## 🚀 快速开始

### 方案1：三协议同时启动（推荐）

```bash
# 1. 部署服务管理器
bash uv_deploy.sh

# 2. 启动所有三种协议服务
./service_manager.sh start

# 3. 查看服务状态
./service_manager.sh status
```

### 方案2：单协议启动（调试用）

```bash
# 安装依赖
uv sync

# 启动单个协议
uv run python main.py http --host 0.0.0.0 --port 60       # HTTP
uv run python main.py sse --host 0.0.0.0 --port 61        # SSE
uv run python main.py http-stream --host 0.0.0.0 --port 62 # HTTP-STREAM
uv run python main.py stdio                                # stdio
```

### 方案3：自定义配置

```bash
# 自定义端口和地址
HOST=127.0.0.1 PORT=8080 ./service_manager.sh start
# 将启动: HTTP(8080), SSE(8081), HTTP-STREAM(8082)
```

## 🔗 服务访问地址

### 三协议并发访问

```bash
# 状态页面
http://localhost:60/        # HTTP服务状态
http://localhost:61/        # SSE服务状态  
http://localhost:62/        # HTTP-STREAM服务状态

# API端点
http://localhost:60/mcp           # HTTP API
http://localhost:61/sse           # SSE连接端点
http://localhost:61/messages/     # SSE消息端点
http://localhost:62/mcp           # HTTP-STREAM API
```

### Claude Desktop集成

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

```json
{
  "name": "PPT生成服务-HTTP",
  "type": "http",
  "url": "http://localhost:60/mcp"
}
```

## 🛠️ 可用工具

### 基础工具

1. **get_theme_list** - 获取PPT模板列表
   ```json
   {
     "pay_type": "not_free",
     "style": "简约",
     "industry": "教育培训",
     "page_size": 10
   }
   ```

2. **create_ppt_task** - 创建PPT生成任务
   ```json
   {
     "text": "人工智能在教育中的应用",
     "template_id": "template_123",
     "author": "AI助手"
   }
   ```

3. **get_task_progress** - 查询任务进度
   ```json
   {
     "sid": "task_id_12345"
   }
   ```

4. **create_outline** - 创建PPT大纲
   ```json
   {
     "text": "人工智能在教育中的应用",
     "language": "cn",
     "search": false
   }
   ```

5. **create_outline_by_doc** - 从文档创建大纲
   ```json
   {
     "file_name": "document.pdf",
     "file_url": "https://example.com/doc.pdf",
     "text": "补充说明"
   }
   ```

6. **create_ppt_by_outline** - 根据大纲创建PPT
   ```json
   {
     "text": "基础描述",
     "outline": { /* 大纲数据 */ },
     "template_id": "template_123"
   }
   ```

### 🌟 高级工具

7. **create_full_ppt_workflow** - ReACT模式完整工作流
   ```json
   {
     "topic": "人工智能在教育中的应用",
     "style_preference": "简约",
     "industry": "教育培训",
     "author": "AI助手",
     "enable_figures": true,
     "enable_notes": true
   }
   ```

8. **get_api_pool_stats** - 获取API密钥池状态
   ```json
   {}
   ```

## 🤖 ReACT模式工作流详解

### 什么是ReACT模式？

ReACT（Reasoning and Acting）是一种AI代理工作模式，结合推理和行动：

```
🧠 THINK → 🎯 ACT → 👁️ OBSERVE → 🔄 ITERATE
```

### 工作流程说明

#### 1. 🧠 THINK（思考阶段）
- 分析用户的PPT需求和主题
- 确定适合的PPT风格和行业类别
- 规划内容结构和要点

#### 2. 🎯 ACT（行动阶段）
- 调用 `get_theme_list` 获取适合的PPT模板
- 调用 `create_outline` 生成结构化大纲
- 调用 `create_ppt_by_outline` 基于大纲生成PPT
- 调用 `get_task_progress` 监控生成进度

#### 3. 👁️ OBSERVE（观察阶段）
- 检查每步的执行结果
- 验证模板选择的合理性
- 确认大纲内容的完整性
- 监控PPT生成状态直到完成

#### 4. 🔄 ITERATE（迭代优化）
- 根据结果调整参数
- 必要时重新选择模板或修改大纲
- 确保最终输出质量

### ReACT工作流使用示例

```bash
# HTTP API调用示例
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "create_full_ppt_workflow",
      "arguments": {
        "topic": "人工智能在教育中的应用",
        "requirements": "面向教师群体，重点介绍AI工具的实际应用",
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

## 📊 API密钥池管理

### 密钥池配置

在 `main.py` 中配置API密钥池：

```python
API_KEY_POOL = [
    {
        "app_id": "your_app_id_1",
        "api_secret": "your_api_secret_1",
        "name": "主密钥",
        "max_concurrent": 10,
        "enabled": True
    },
    {
        "app_id": "your_app_id_2", 
        "api_secret": "your_api_secret_2",
        "name": "备用密钥",
        "max_concurrent": 5,
        "enabled": True
    }
]
```

### 密钥池特性

- **负载均衡** - 自动轮询和最优选择算法
- **故障转移** - 自动切换到可用密钥
- **并发控制** - 每个密钥独立的并发限制
- **统计监控** - 实时跟踪使用情况和错误率
- **智能重试** - 失败时自动使用其他密钥

### 查看密钥池状态

```bash
# 通过API查看密钥池状态
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "get_api_pool_stats",
      "arguments": {}
    }
  }'
```

## 🔧 服务管理

### 三协议服务管理

```bash
# 基本管理命令
./service_manager.sh start     # 启动所有服务
./service_manager.sh stop      # 停止所有服务
./service_manager.sh restart   # 重启所有服务
./service_manager.sh status    # 查看服务状态

# 日志管理
./service_manager.sh logs             # 所有服务日志
./service_manager.sh logs http        # HTTP服务日志
./service_manager.sh logs sse         # SSE服务日志
./service_manager.sh logs stream      # HTTP-STREAM服务日志
./service_manager.sh logs http -f     # 实时查看HTTP日志
```

### 环境变量配置

```bash
# 自定义绑定地址
HOST=0.0.0.0 ./service_manager.sh start

# 自定义基础端口
PORT=8080 ./service_manager.sh start
# 将启动: HTTP(8080), SSE(8081), HTTP-STREAM(8082)

# 组合配置
HOST=127.0.0.1 PORT=9000 ./service_manager.sh start
```

### 服务状态检查

```bash
# 检查进程状态
ps aux | grep "python.*main.py"

# 检查端口监听
sudo netstat -tlnp | grep -E ":(60|61|62)\s"

# 检查服务响应
curl -I http://localhost:60/
curl -I http://localhost:61/
curl -I http://localhost:62/
```

## 📝 完整使用流程示例

### 示例1：基础PPT生成流程

```bash
# 1. 启动服务
./service_manager.sh start

# 2. 获取模板列表
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "get_theme_list",
      "arguments": {
        "style": "简约",
        "industry": "教育培训"
      }
    }
  }'

# 3. 创建PPT任务（使用获得的template_id）
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "create_ppt_task",
      "arguments": {
        "text": "人工智能在教育中的应用",
        "template_id": "获得的模板ID",
        "author": "AI助手"
      }
    }
  }'

# 4. 查询任务进度（使用获得的task_id）
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "get_task_progress",
      "arguments": {
        "sid": "获得的任务ID"
      }
    }
  }'
```

### 示例2：ReACT模式一键生成（推荐）

```bash
# 使用ReACT工作流一次性完成整个流程
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "create_full_ppt_workflow",
      "arguments": {
        "topic": "人工智能在教育中的应用",
        "requirements": "面向教师群体，介绍实用的AI工具",
        "style_preference": "简约",
        "industry": "教育培训",
        "author": "AI教学助手",
        "enable_figures": true,
        "enable_notes": true
      }
    }
  }'
```

### 示例3：文档转PPT流程

```bash
# 1. 从文档创建大纲
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "create_outline_by_doc",
      "arguments": {
        "file_name": "教学文档.pdf",
        "file_url": "https://example.com/doc.pdf",
        "text": "基于此文档制作PPT"
      }
    }
  }'

# 2. 基于大纲生成PPT
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "create_ppt_by_outline",
      "arguments": {
        "text": "根据文档生成PPT",
        "outline": "从步骤1获得的大纲数据",
        "template_id": "适合的模板ID"
      }
    }
  }'
```

## 🔍 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 查看错误日志
./service_manager.sh logs

# 检查端口占用
sudo netstat -tlnp | grep -E ":(60|61|62)\s"

# 使用其他端口
PORT=8080 ./service_manager.sh start
```

#### 2. API调用超时
```bash
# 检查服务状态
./service_manager.sh status

# 查看API密钥池状态
curl -X POST http://localhost:60/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "get_api_pool_stats",
      "arguments": {}
    }
  }'
```

#### 3. PPT生成失败
```bash
# 检查API密钥配置
# 确保main.py中的API_KEY_POOL至少有一个有效密钥

# 查看详细错误信息
./service_manager.sh logs http
```

### 诊断工具

```bash
# 环境检查
uv --version
python3 --version

# 服务测试
cd tests
python test_api_pool.py
python test_sse.py
```

## 📚 协议选择指南

| 使用场景 | 推荐协议 | 端口 | 说明 |
|----------|----------|------|------|
| **AI代理/智能助手** | **HTTP** | **60** | **稳定可靠，支持ReACT** |
| **Claude Desktop** | stdio | - | 本地集成，性能最佳 |
| **Web应用集成** | HTTP | 60 | RESTful API，广泛兼容 |
| **实时通信需求** | SSE | 61 | 支持流式响应 |
| **新标准支持** | HTTP-STREAM | 62 | MCP 2025-03-26标准 |

## 📊 性能优化建议

### 1. 密钥池优化
- 配置多个API密钥实现负载均衡
- 根据并发需求调整max_concurrent参数
- 定期检查密钥池状态和错误率

### 2. 服务部署优化
- 生产环境使用0.0.0.0绑定地址
- 配置防火墙开放必要端口
- 定期备份配置和日志文件

### 3. 网络优化
- 确保良好的网络连接到讯飞智文API
- 考虑配置反向代理提高稳定性
- 监控API调用延迟和成功率

## ✨ 新特性说明

### 🌟 三协议同时启动
- 一次部署即可同时提供HTTP、SSE、HTTP-STREAM三种访问方式
- 每个协议独立的进程管理和日志记录
- 支持环境变量灵活配置端口和地址

### 🤖 ReACT工作流
- 智能代理推荐使用的完整PPT生成流程
- 自动化模板选择、大纲生成、PPT创建全流程
- 详细的执行日志和错误处理

### 🔧 API密钥池管理
- 多密钥负载均衡和故障转移
- 实时监控使用情况和错误率
- 智能重试和并发控制

---

**注意**: 使用前请确保已获得有效的讯飞智文API密钥，并在`main.py`中正确配置`API_KEY_POOL`。

**🌟 推荐**: 使用ReACT模式的`create_full_ppt_workflow`工具可以一次性完成整个PPT生成流程，特别适合AI代理使用。
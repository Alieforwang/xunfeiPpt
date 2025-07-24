# MCP HTTP Stream Transport 实现指南

## 概述

本项目已成功集成MCP 2025-03-26规范的HTTP Stream Transport，提供现代化的HTTP流式传输支持。这是对原有SSE传输的升级，提供更好的性能、安全性和功能。

## 新增功能

### 1. HTTP Stream Transport支持

- **协议版本**: MCP 2025-03-26
- **单一端点**: `/mcp` 处理所有通信
- **双响应模式**: JSON模式和SSE流模式
- **会话管理**: 完整的会话ID和状态管理
- **断线重连**: 支持Last-Event-ID恢复机制
- **安全防护**: DNS重绑定保护

### 2. 传输协议对比

| 特性 | SSE Transport | HTTP Stream Transport |
|------|---------------|----------------------|
| **MCP版本** | 2024-11-05及之前 | 2025-03-26 |
| **端点数量** | 2个 (GET /sse + POST /messages/) | 1个 (/mcp) |
| **会话管理** | 基础 | 完整（会话ID + 恢复） |
| **响应模式** | 仅SSE流 | JSON + SSE流 |
| **安全性** | 基础 | DNS重绑定保护 |
| **推荐状态** | 已弃用 | **推荐使用** |

## 使用方法

### 1. 启动HTTP Stream服务器

```bash
# 启动HTTP Stream传输服务器（推荐）
python main.py http-stream

# 自定义端口
python main.py http-stream --port 8003

# 绑定所有接口
python main.py http-stream --host 0.0.0.0 --port 8002
```

**服务器信息:**
- 默认端口: 8002
- MCP端点: `http://localhost:8002/mcp`
- 状态页面: `http://localhost:8002/`
- 协议: MCP 2025-03-26 HTTP Stream Transport

### 2. 客户端连接

#### 使用MCP客户端库 (推荐)

```python
from mcp.client.streamable_http import streamablehttp_client
from mcp.shared.message import SessionMessage
import mcp.types as types

async def connect_to_server():
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/event-stream',
        'Mcp-Protocol-Version': '2025-03-26'
    }
    
    async with streamablehttp_client(
        url="http://localhost:8002/mcp",
        headers=headers,
        timeout=30.0,
        sse_read_timeout=300.0
    ) as (read_stream, write_stream, get_session_id):
        
        # 发送初始化
        init_request = types.JSONRPCMessage(
            types.JSONRPCRequest(
                jsonrpc="2.0",
                id="init-1",
                method="initialize",
                params={
                    "protocolVersion": "2025-03-26",
                    "capabilities": {"tools": {}},
                    "clientInfo": {"name": "my-client", "version": "1.0.0"}
                }
            )
        )
        
        await write_stream.send(SessionMessage(init_request))
        
        # 读取响应
        async for message in read_stream:
            if isinstance(message, Exception):
                print(f"错误: {message}")
                break
            print(f"收到: {message.message}")
```

#### 直接HTTP请求

```python
import httpx
import json

async def direct_http_request():
    url = "http://localhost:8002/mcp"
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/event-stream',
        'Mcp-Protocol-Version': '2025-03-26'
    }
    
    data = {
        "jsonrpc": "2.0",
        "id": "test-1",
        "method": "tools/list",
        "params": {}
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=data, headers=headers)
        
        if response.headers.get('content-type', '').startswith('application/json'):
            # JSON响应模式
            result = response.json()
            print(f"JSON响应: {json.dumps(result, indent=2)}")
        
        elif response.headers.get('content-type', '').startswith('text/event-stream'):
            # SSE流响应模式
            async for line in response.aiter_lines():
                if line.startswith('data: '):
                    data = json.loads(line[6:])
                    print(f"SSE消息: {data}")
```

### 3. cURL测试

```bash
# 获取工具列表
curl -X POST http://localhost:8002/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Protocol-Version: 2025-03-26" \
  -d '{"jsonrpc":"2.0","id":"test-1","method":"tools/list","params":{}}'

# 调用工具
curl -X POST http://localhost:8002/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Protocol-Version: 2025-03-26" \
  -d '{"jsonrpc":"2.0","id":"test-2","method":"tools/call","params":{"name":"get_theme_list","arguments":{"page_num":1,"page_size":5}}}'
```

### 4. 测试客户端

运行提供的测试客户端：

```bash
# 确保HTTP Stream服务器正在运行
python main.py http-stream

# 在另一个终端运行测试
python test_http_stream.py
```

## 协议特性详解

### 1. 单一端点架构

HTTP Stream Transport使用单一的`/mcp`端点处理所有通信：
- **POST请求**: 发送JSON-RPC消息
- **GET请求**: 建立SSE流接收服务器主动消息

### 2. 双响应模式

服务器根据请求类型和配置返回不同格式的响应：

#### JSON响应模式
- 立即返回完整的JSON-RPC响应
- 适合快速请求-响应交互
- Content-Type: `application/json`

#### SSE流响应模式
- 返回Server-Sent Events流
- 支持长时间运行的操作
- 支持实时通知和进度更新
- Content-Type: `text/event-stream`

### 3. 会话管理

- **会话ID**: 使用`Mcp-Session-Id`头跟踪客户端会话
- **协议版本**: 使用`Mcp-Protocol-Version`头协商协议版本
- **状态管理**: 支持有状态和无状态两种模式

### 4. 断线重连

- **Last-Event-ID**: 客户端可以通过此头恢复中断的连接
- **事件重放**: 服务器可以重放错过的事件
- **会话恢复**: 保持会话状态不丢失

### 5. 安全防护

- **DNS重绑定保护**: 防止恶意网站攻击本地服务
- **Origin验证**: 验证请求来源
- **CORS支持**: 跨域资源共享配置

## 配置选项

HTTP Stream Transport支持多种配置：

```python
from http_stream_transport import create_http_stream_transport

# 创建传输实例
transport = create_http_stream_transport(
    mcp_server=server,
    json_response=False,    # False=SSE流模式, True=JSON模式
    stateless=False,        # False=有状态会话, True=无状态
    enable_security=True    # 启用安全防护
)
```

### 配置参数说明

- **json_response**: 
  - `False`: 使用SSE流响应（默认，推荐）
  - `True`: 使用JSON响应（适合REST API风格）

- **stateless**:
  - `False`: 有状态会话管理（默认，推荐）
  - `True`: 无状态模式（每个请求独立处理）

- **enable_security**:
  - `True`: 启用DNS重绑定保护（默认，推荐）
  - `False`: 禁用安全防护（仅用于测试）

## 迁移指南

### 从SSE Transport迁移

1. **保持兼容性**: 现有SSE支持继续可用
   ```bash
   python main.py sse  # 继续使用SSE传输
   ```

2. **逐步迁移**: 同时运行两种传输
   ```bash
   # 终端1: SSE传输
   python main.py sse --port 8001
   
   # 终端2: HTTP Stream传输
   python main.py http-stream --port 8002
   ```

3. **客户端更新**: 更新客户端代码使用新的端点
   ```python
   # 旧的SSE端点
   old_sse_url = "http://localhost:8001/sse"
   
   # 新的HTTP Stream端点
   new_stream_url = "http://localhost:8002/mcp"
   ```

### 迁移检查清单

- [ ] HTTP Stream服务器启动正常
- [ ] 客户端可以连接到新端点
- [ ] 初始化消息交换成功
- [ ] 工具调用功能正常
- [ ] 会话管理工作正常
- [ ] 错误处理机制完善
- [ ] 性能表现满足要求

## 故障排除

### 常见问题

1. **连接失败**
   ```
   错误: Connection refused
   解决: 确保HTTP Stream服务器正在运行
   检查: python main.py http-stream
   ```

2. **协议版本不匹配**
   ```
   错误: Unsupported protocol version
   解决: 确保客户端发送正确的协议版本头
   修复: Mcp-Protocol-Version: 2025-03-26
   ```

3. **Accept头错误**
   ```
   错误: Not Acceptable
   解决: 确保Accept头包含必要的MIME类型
   修复: Accept: application/json, text/event-stream
   ```

4. **会话ID问题**
   ```
   错误: Invalid session ID
   解决: 检查会话管理配置和客户端实现
   修复: 确保正确处理Mcp-Session-Id头
   ```

### 调试技巧

1. **启用调试日志**
   ```bash
   python main.py http-stream --log-level DEBUG
   ```

2. **使用测试客户端**
   ```bash
   python test_http_stream.py
   ```

3. **检查网络通信**
   ```bash
   curl -v http://localhost:8002/mcp
   ```

4. **监控服务器状态**
   访问: http://localhost:8002/

## 性能建议

1. **连接复用**: 尽可能复用HTTP连接
2. **会话管理**: 对于长期客户端使用有状态模式
3. **响应模式**: 简单请求使用JSON模式，复杂操作使用SSE模式
4. **超时设置**: 根据操作复杂度调整超时时间
5. **错误处理**: 实现robust的重连和错误恢复机制

## 总结

HTTP Stream Transport为MCP服务器提供了现代化、高效的传输解决方案。相比传统的SSE传输，它提供了：

- 更简单的单端点架构
- 更强大的会话管理
- 更灵活的响应模式
- 更好的安全防护
- 更完善的错误恢复

建议新项目直接使用HTTP Stream Transport，现有项目可以渐进式迁移。
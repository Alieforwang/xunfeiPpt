#!/bin/bash

# 讯飞智文PPT服务简化部署脚本
# 一键部署，无需额外配置

set -e

echo "=== 讯飞智文PPT服务简化部署 ==="

# 工作目录
WORK_DIR="/www/wwwroot/xunfeiPpt"
SERVICE_NAME="ppt-mcp-sse"

# 创建工作目录
echo "创建工作目录..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 自动修复脚本编码
[ -f "$0" ] && (file "$0" | grep -q "CRLF" && sed -i 's/\r$//' "$0" || true)

# 检测Python
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
    PIP_CMD="pip3"
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
    PIP_CMD="pip"
    PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2)
else
    echo "错误: 未找到Python"
    exit 1
fi

echo "Python: $PYTHON_CMD"
echo "版本: $PYTHON_VERSION"

# 检查Python版本是否支持uv（需要3.8+）
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

# 安装依赖
echo "安装依赖..."
if command -v uv >/dev/null 2>&1 && [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
    echo "使用uv安装依赖..."
    uv pip install mcp requests requests-toolbelt starlette uvicorn
else
    if command -v uv >/dev/null 2>&1; then
        echo "⚠️ Python版本($PYTHON_VERSION)低于3.8，使用pip而非uv"
    fi
    echo "使用pip安装依赖..."
    $PIP_CMD install mcp requests requests-toolbelt starlette uvicorn
fi

# 创建main.py
echo "创建main.py..."
cat > main.py << 'MAIN_PY_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import asyncio
import os
import json
import time
import hashlib
import hmac
import base64
import argparse
import logging
from contextlib import AsyncExitStack
from typing import Any, Sequence, Optional

import requests
from requests_toolbelt.multipart.encoder import MultipartEncoder

from mcp.server.models import InitializationOptions
from mcp.server.stdio import stdio_server
from mcp.server.lowlevel import NotificationOptions, Server
from mcp.types import (
    Resource,
    Tool,
    TextContent,
    ImageContent,
    EmbeddedResource,
    LoggingLevel,
)
import mcp.types as types

# 讯飞智文API密钥池配置
API_KEY_POOL = [
    {
        "app_id": "2dc9dc12",
        "api_secret": "YWVmZjQ0NTI4MjkxMTEzMTA5MWZiY2M4",
        "name": "主密钥",
        "max_concurrent": 10,
        "enabled": True
    },
    {
        "app_id": "8767f4a7",
        "api_secret": "MDU0OTBlMzEwYjBiNDI3MDM3ODI2ZTZi", 
        "name": "备用密钥1",
        "max_concurrent": 2,
        "enabled": True
    },
]

class APIKeyPool:
    def __init__(self, key_pool):
        self.key_pool = [key for key in key_pool if key.get('enabled', True)]
        self.current_index = 0
        self.usage_stats = {i: {"requests": 0, "errors": 0, "concurrent": 0} 
                           for i in range(len(self.key_pool))}
    
    def get_next_key(self):
        if not self.key_pool:
            raise Exception("没有可用的API密钥")
        key_info = self.key_pool[self.current_index]
        stats = self.usage_stats[self.current_index]
        if stats["concurrent"] >= key_info.get("max_concurrent", 10):
            original_index = self.current_index
            while True:
                self.current_index = (self.current_index + 1) % len(self.key_pool)
                if self.current_index == original_index:
                    break
                key_info = self.key_pool[self.current_index]
                stats = self.usage_stats[self.current_index]
                if stats["concurrent"] < key_info.get("max_concurrent", 10):
                    break
        return self.current_index, key_info
    
    def get_best_key(self):
        if not self.key_pool:
            raise Exception("没有可用的API密钥")
        best_index = 0
        best_score = float('inf')
        for i, key_info in enumerate(self.key_pool):
            stats = self.usage_stats[i]
            if stats["concurrent"] >= key_info.get("max_concurrent", 10):
                continue
            error_rate = stats["errors"] / max(stats["requests"], 1)
            concurrent_load = stats["concurrent"] / key_info.get("max_concurrent", 10)
            score = error_rate * 0.7 + concurrent_load * 0.3
            if score < best_score:
                best_score = score
                best_index = i
        return best_index, self.key_pool[best_index]
    
    def mark_request_start(self, key_index):
        self.usage_stats[key_index]["requests"] += 1
        self.usage_stats[key_index]["concurrent"] += 1
        
    def mark_request_end(self, key_index, success=True):
        self.usage_stats[key_index]["concurrent"] = max(0, 
            self.usage_stats[key_index]["concurrent"] - 1)
        if not success:
            self.usage_stats[key_index]["errors"] += 1
            
    def get_stats(self):
        return {
            "total_keys": len(self.key_pool),
            "active_keys": len([k for k in self.key_pool if k.get('enabled', True)]),
            "usage_stats": self.usage_stats,
            "key_info": [{"name": k.get("name", "密钥{}".format(i)), 
                         "concurrent": self.usage_stats[i]["concurrent"],
                         "max_concurrent": k.get("max_concurrent", 10)} 
                        for i, k in enumerate(self.key_pool)]
        }

class AIPPTClient:
    def __init__(self, key_pool=None):
        self.key_pool_manager = APIKeyPool(key_pool or API_KEY_POOL)
        self.base_url = "https://zwapi.xfyun.cn/api/ppt/v2"
        self.max_retries = 3
        
    def _get_signature(self, app_id: str, api_secret: str, timestamp: int) -> str:
        try:
            auth = self._md5(app_id + str(timestamp))
            return self._hmac_sha1_encrypt(auth, api_secret)
        except Exception as e:
            raise Exception("签名生成失败: {}".format(e))
    
    def _hmac_sha1_encrypt(self, encrypt_text: str, encrypt_key: str) -> str:
        return base64.b64encode(
            hmac.new(
                encrypt_key.encode('utf-8'),
                encrypt_text.encode('utf-8'),
                hashlib.sha1
            ).digest()
        ).decode('utf-8')
    
    def _md5(self, text: str) -> str:
        return hashlib.md5(text.encode('utf-8')).hexdigest()
    
    def _get_headers(self, key_info: dict, content_type: str = "application/json; charset=utf-8") -> dict:
        timestamp = int(time.time())
        signature = self._get_signature(key_info["app_id"], key_info["api_secret"], timestamp)
        return {
            "appId": key_info["app_id"],
            "timestamp": str(timestamp),
            "signature": signature,
            "Content-Type": content_type
        }
        
    def _make_request_with_retry(self, request_func, *args, **kwargs):
        last_exception = None
        for attempt in range(self.max_retries):
            try:
                key_index, key_info = self.key_pool_manager.get_best_key()
                self.key_pool_manager.mark_request_start(key_index)
                try:
                    result = request_func(key_info, *args, **kwargs)
                    self.key_pool_manager.mark_request_end(key_index, success=True)
                    return result
                except Exception as req_error:
                    self.key_pool_manager.mark_request_end(key_index, success=False)
                    if "限制" in str(req_error) or "rate" in str(req_error).lower():
                        print("密钥 {} 达到限制，尝试其他密钥...".format(key_info.get('name', key_index)))
                        continue
                    else:
                        raise req_error
            except Exception as e:
                last_exception = e
                if attempt < self.max_retries - 1:
                    print("请求失败 (尝试 {}/{}): {}".format(attempt + 1, self.max_retries, e))
                    time.sleep(1)
                else:
                    print("所有重试均失败")
        raise last_exception or Exception("请求失败，已达到最大重试次数")
    
    def get_pool_stats(self):
        return self.key_pool_manager.get_stats()
    
    def get_theme_list(self, pay_type: str = "not_free", style: str = None, 
                      color: str = None, industry: str = None, 
                      page_num: int = 1, page_size: int = 10) -> dict:
        def _request(key_info):
            url = "{}/template/list".format(self.base_url)
            headers = self._get_headers(key_info)
            params = {
                "payType": pay_type,
                "pageNum": page_num,
                "pageSize": page_size
            }
            if style:
                params["style"] = style
            if color:
                params["color"] = color
            if industry:
                params["industry"] = industry
            response = requests.get(url, headers=headers, params=params)
            return response.json()
        return self._make_request_with_retry(_request)

# 简化版MCP服务器
server = Server("pptmcpseriver")
aippt_client = AIPPTClient()

@server.list_tools()
async def handle_list_tools() -> list[Tool]:
    return [
        Tool(
            name="get_theme_list",
            description="获取PPT模板列表",
            inputSchema={
                "type": "object",
                "properties": {
                    "pay_type": {"type": "string", "default": "not_free"},
                    "style": {"type": "string"},
                    "color": {"type": "string"},
                    "industry": {"type": "string"},
                    "page_num": {"type": "integer", "default": 1},
                    "page_size": {"type": "integer", "default": 10}
                }
            }
        ),
        Tool(
            name="get_api_pool_stats",
            description="获取API密钥池状态",
            inputSchema={"type": "object", "properties": {}}
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict | None) -> list[types.TextContent]:
    if arguments is None:
        arguments = {}
    try:
        if name == "get_theme_list":
            result = aippt_client.get_theme_list(**arguments)
            return [types.TextContent(type="text", text=json.dumps(result, ensure_ascii=False, indent=2))]
        elif name == "get_api_pool_stats":
            stats = aippt_client.get_pool_stats()
            return [types.TextContent(type="text", text=json.dumps(stats, ensure_ascii=False, indent=2))]
        else:
            raise ValueError("未知工具: {}".format(name))
    except Exception as e:
        return [types.TextContent(type="text", text="错误: {}".format(str(e)))]

# SSE服务器
async def run_sse_server(host: str = "localhost", port: int = 60):
    try:
        from starlette.applications import Starlette
        from starlette.routing import Route, Mount
        from starlette.responses import Response
        from starlette.requests import Request
        from mcp.server.sse import SseServerTransport
        import uvicorn
        
        sse_transport = SseServerTransport("/messages/")
        
        async def handle_sse(request: Request):
            async with sse_transport.connect_sse(
                request.scope, 
                request.receive, 
                request._send
            ) as (read_stream, write_stream):
                await server.run(
                    read_stream,
                    write_stream,
                    InitializationOptions(
                        server_name="pptmcpseriver",
                        server_version="0.1.0",
                        capabilities=server.get_capabilities(
                            notification_options=NotificationOptions(),
                            experimental_capabilities={},
                        ),
                    ),
                )
            return Response()
        
        async def handle_status_page(request: Request):
            return Response(
                content="""
                <html>
                <head><title>讯飞智文PPT生成服务</title></head>
                <body>
                    <h1>讯飞智文PPT生成服务MCP Server</h1>
                    <h2>SSE传输协议</h2>
                    <p>服务器正在运行中...</p>
                    <h3>连接信息:</h3>
                    <ul>
                        <li>SSE端点: <a href="/sse">/sse</a></li>
                        <li>消息端点: /messages/</li>
                        <li>协议: Server-Sent Events</li>
                    </ul>
                    <h3>可用工具:</h3>
                    <ul>
                        <li>get_theme_list - 获取PPT模板列表</li>
                        <li>get_api_pool_stats - 获取API密钥池状态</li>
                    </ul>
                </body>
                </html>
                """,
                media_type="text/html"
            )
        
        app = Starlette(routes=[
            Route("/sse", handle_sse, methods=["GET"]),
            Mount("/messages/", sse_transport.handle_post_message),
            Route("/", handle_status_page, methods=["GET"]),
        ])
        
        config = uvicorn.Config(app, host=host, port=port, log_level="info")
        server_instance = uvicorn.Server(config)
        await server_instance.serve()
        
    except ImportError as e:
        print("错误: 缺少SSE服务器依赖: {}".format(e))
        return

def main():
    parser = argparse.ArgumentParser(description="讯飞智文PPT生成服务MCP Server")
    parser.add_argument("transport", nargs="?", choices=["stdio", "sse"], default="sse")
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=60)
    args = parser.parse_args()
    
    if args.transport == "sse":
        print("启动 SSE 传输服务器 - http://{}:{}".format(args.host, args.port))
        asyncio.run(run_sse_server(args.host, args.port))
    else:
        print("仅支持SSE传输")

if __name__ == "__main__":
    main()
MAIN_PY_EOF

echo "设置文件权限..."
chmod +x main.py

echo "测试Python代码..."
$PYTHON_CMD -m py_compile main.py
echo "✅ Python代码语法检查通过"

# 创建简单的服务管理脚本
cat > service.sh << 'SERVICE_EOF'
#!/bin/bash
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_CMD="python3"
[ ! -x "$(command -v python3)" ] && PYTHON_CMD="python"

case "$1" in
    start)
        echo "启动服务..."
        cd "$WORK_DIR"
        nohup $PYTHON_CMD main.py sse --host 0.0.0.0 --port 60 > service.log 2>&1 &
        echo $! > service.pid
        echo "服务已启动，PID: $(cat service.pid)"
        echo "访问: http://localhost:60"
        ;;
    stop)
        [ -f service.pid ] && kill $(cat service.pid) && rm service.pid
        echo "服务已停止"
        ;;
    status)
        if [ -f service.pid ] && ps -p $(cat service.pid) > /dev/null; then
            echo "服务正在运行 (PID: $(cat service.pid))"
        else
            echo "服务已停止"
        fi
        ;;
    *)
        echo "使用: $0 {start|stop|status}"
        ;;
esac
SERVICE_EOF

chmod +x service.sh

# 自动启动服务
echo "启动服务..."
bash service.sh start

# 等待启动
sleep 3

# 测试服务
if command -v curl >/dev/null && curl -s http://localhost:60 >/dev/null; then
    echo "✅ 服务部署成功！"
else
    echo "⚠️ 服务可能未完全启动"
fi

echo ""
echo "=== 部署完成 ==="
echo "访问地址: http://localhost:60"
echo "日志文件: $WORK_DIR/service.log"
echo "管理命令: bash $WORK_DIR/service.sh {start|stop|status}"
echo "如需外网访问，请开放60端口"

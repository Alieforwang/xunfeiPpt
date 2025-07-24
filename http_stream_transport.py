#!/usr/bin/env python3
"""
HTTP Stream传输实现，基于MCP 2025-03-26规范
用于替代已废弃的SSE传输
"""
import asyncio
import json
import logging
import uuid
from typing import Dict, Optional, Any, List
from starlette.applications import Starlette
from starlette.routing import Route
from starlette.responses import Response, JSONResponse, StreamingResponse
from starlette.requests import Request
from mcp.server.models import InitializationOptions
from mcp.server.lowlevel import NotificationOptions

logger = logging.getLogger(__name__)

class HttpStreamTransport:
    """HTTP Stream传输实现"""
    
    def __init__(self, endpoint: str = "/mcp"):
        self.endpoint = endpoint
        self.sessions: Dict[str, Dict] = {}
        
    async def create_session(self, session_id: str = None) -> str:
        """创建新的HTTP Stream会话"""
        if not session_id:
            session_id = str(uuid.uuid4())
            
        self.sessions[session_id] = {
            "id": session_id,
            "created_at": asyncio.get_event_loop().time(),
            "last_activity": asyncio.get_event_loop().time(),
            "message_queue": asyncio.Queue(),
            "client_connected": True
        }
        
        logger.info(f"Created HTTP Stream session: {session_id}")
        return session_id
    
    async def get_session(self, session_id: str) -> Optional[Dict]:
        """获取会话信息"""
        session = self.sessions.get(session_id)
        if session:
            session["last_activity"] = asyncio.get_event_loop().time()
        return session
    
    async def close_session(self, session_id: str):
        """关闭会话"""
        if session_id in self.sessions:
            session = self.sessions[session_id]
            session["client_connected"] = False
            del self.sessions[session_id]
            logger.info(f"Closed HTTP Stream session: {session_id}")
    
    async def send_message(self, session_id: str, message: Dict[str, Any]):
        """向会话发送消息"""
        session = await self.get_session(session_id)
        if session and session["client_connected"]:
            await session["message_queue"].put(message)
    
    async def handle_request(self, request: Request) -> Response:
        """处理HTTP Stream请求"""
        method = request.method
        
        if method == "POST":
            return await self._handle_post_request(request)
        elif method == "GET":
            return await self._handle_get_request(request)
        else:
            return JSONResponse(
                {"error": "Method not allowed"}, 
                status_code=405
            )
    
    async def _handle_post_request(self, request: Request) -> Response:
        """处理POST请求（发送消息）"""
        try:
            # 获取或创建会话ID
            session_id = request.headers.get("x-session-id")
            if not session_id:
                session_id = await self.create_session()
            
            # 解析请求体
            body = await request.json()
            
            # 验证JSON-RPC格式
            if not isinstance(body, dict) or "jsonrpc" not in body:
                return JSONResponse({
                    "jsonrpc": "2.0",
                    "error": {
                        "code": -32600,
                        "message": "Invalid Request"
                    }
                }, status_code=400)
            
            # 获取会话
            session = await self.get_session(session_id)
            if not session:
                session_id = await self.create_session(session_id)
                session = await self.get_session(session_id)
            
            # 处理特殊的初始化请求
            method = body.get("method")
            if method == "initialize":
                # 直接返回初始化响应，不通过消息队列
                return await self._handle_initialize_request(body, session_id)
            
            # 将消息添加到会话队列处理
            await session["message_queue"].put(body)
            
            # 返回成功响应，包含会话ID
            return JSONResponse({
                "jsonrpc": "2.0",
                "result": {"status": "queued"},
                "id": body.get("id")
            }, headers={"x-session-id": session_id})
            
        except json.JSONDecodeError:
            return JSONResponse({
                "jsonrpc": "2.0",
                "error": {
                    "code": -32700,
                    "message": "Parse error"
                }
            }, status_code=400)
        except Exception as e:
            logger.error(f"HTTP Stream POST error: {e}")
            return JSONResponse({
                "jsonrpc": "2.0",
                "error": {
                    "code": -32603,
                    "message": f"Internal error: {str(e)}"
                }
            }, status_code=500)
    
    async def _handle_initialize_request(self, body: dict, session_id: str) -> Response:
        """处理MCP初始化请求"""
        try:
            # MCP标准初始化响应
            init_response = {
                "jsonrpc": "2.0",
                "id": body.get("id"),
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {
                        "tools": {},
                        "resources": {},
                        "prompts": {},
                        "logging": {}
                    },
                    "serverInfo": {
                        "name": "pptmcpseriver",
                        "version": "0.2.0"
                    }
                }
            }
            
            return JSONResponse(
                init_response,
                headers={"x-session-id": session_id}
            )
            
        except Exception as e:
            logger.error(f"Initialize request error: {e}")
            return JSONResponse({
                "jsonrpc": "2.0",
                "id": body.get("id"),
                "error": {
                    "code": -32603,
                    "message": f"Initialization failed: {str(e)}"
                }
            }, headers={"x-session-id": session_id})
    
    async def _handle_get_request(self, request: Request) -> Response:
        """处理GET请求（接收消息流）"""
        try:
            # 获取会话ID
            session_id = request.headers.get("x-session-id")
            last_event_id = request.headers.get("last-event-id")
            
            if not session_id:
                return JSONResponse({
                    "error": "Missing x-session-id header"
                }, status_code=400)
            
            # 获取或创建会话
            session = await self.get_session(session_id)
            if not session:
                return JSONResponse({
                    "error": "Session not found"
                }, status_code=404)
            
            # 创建SSE流式响应
            async def generate_events():
                try:
                    # 发送连接建立事件
                    yield f"data: {json.dumps({'type': 'connected', 'sessionId': session_id})}\n\n"
                    
                    # 持续读取会话消息队列
                    while session["client_connected"]:
                        try:
                            # 等待消息，设置超时避免阻塞
                            message = await asyncio.wait_for(
                                session["message_queue"].get(), 
                                timeout=30.0
                            )
                            
                            # 发送消息事件
                            event_data = json.dumps(message)
                            yield f"data: {event_data}\n\n"
                            
                        except asyncio.TimeoutError:
                            # 发送心跳保持连接
                            yield f"data: {json.dumps({'type': 'heartbeat'})}\n\n"
                        except asyncio.CancelledError:
                            break
                        except Exception as e:
                            logger.error(f"Message processing error: {e}")
                            error_data = json.dumps({
                                "jsonrpc": "2.0",
                                "error": {
                                    "code": -32603,
                                    "message": f"Internal error: {str(e)}"
                                }
                            })
                            yield f"data: {error_data}\n\n"
                            
                except Exception as e:
                    logger.error(f"Stream generation error: {e}")
                finally:
                    # 清理会话
                    await self.close_session(session_id)
            
            return StreamingResponse(
                generate_events(),
                media_type="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "Connection": "keep-alive",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "x-session-id, last-event-id",
                    "x-session-id": session_id
                }
            )
            
        except Exception as e:
            logger.error(f"HTTP Stream GET error: {e}")
            return JSONResponse({
                "error": f"Internal error: {str(e)}"
            }, status_code=500)
    
    def get_session_count(self) -> int:
        """获取活跃会话数量"""
        return len(self.sessions)
    
    def get_session_info(self) -> List[Dict]:
        """获取所有会话信息"""
        return [
            {
                "id": session_id,
                "created_at": session["created_at"],
                "last_activity": session["last_activity"],
                "connected": session["client_connected"]
            }
            for session_id, session in self.sessions.items()
        ]
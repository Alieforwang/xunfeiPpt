#!/usr/bin/env python3
"""
固定的SSE传输实现，修复arguments字符串解析问题
"""
import json
import logging
from typing import Any, Dict, Optional
from mcp.server.sse import SseServerTransport

logger = logging.getLogger(__name__)

class FixedSseServerTransport(SseServerTransport):
    """
    修复的SSE服务器传输，自动解析字符串形式的arguments参数
    """
    
    def _preprocess_message(self, message: Dict[str, Any]) -> Dict[str, Any]:
        """
        预处理消息，修复arguments字符串问题
        """
        try:
            # 检查是否是tools/call请求且arguments是字符串
            if (message.get("method") == "tools/call" and 
                "params" in message and 
                "arguments" in message["params"]):
                
                arguments = message["params"]["arguments"]
                
                # 如果arguments是字符串，尝试解析为字典
                if isinstance(arguments, str):
                    try:
                        parsed_arguments = json.loads(arguments)
                        message["params"]["arguments"] = parsed_arguments
                        logger.debug(f"已修复arguments字符串: {arguments[:100]}...")
                    except json.JSONDecodeError as e:
                        logger.warning(f"无法解析arguments字符串: {e}")
                        # 保持原始值，让MCP框架处理错误
                        
            return message
            
        except Exception as e:
            logger.error(f"预处理消息时出错: {e}")
            return message
    
    async def handle_post_message(self, scope, receive, send):
        """
        重写消息处理，添加预处理步骤
        """
        try:
            # 读取请求体
            body = b""
            while True:
                message = await receive()
                if message["type"] == "http.request":
                    body += message.get("body", b"")
                    if not message.get("more_body", False):
                        break
            
            # 解析JSON
            if body:
                try:
                    json_message = json.loads(body.decode('utf-8'))
                    # 预处理消息
                    processed_message = self._preprocess_message(json_message)
                    # 重新编码
                    processed_body = json.dumps(processed_message).encode('utf-8')
                    
                    # 创建新的receive函数返回处理后的数据
                    async def new_receive():
                        return {
                            "type": "http.request",
                            "body": processed_body,
                            "more_body": False
                        }
                    
                    # 调用父类方法
                    return await super().handle_post_message(scope, new_receive, send)
                    
                except json.JSONDecodeError:
                    logger.warning("无法解析POST消息体为JSON")
            
            # 如果无法处理，回退到原始实现
            async def original_receive():
                return {
                    "type": "http.request", 
                    "body": body,
                    "more_body": False
                }
            
            return await super().handle_post_message(scope, original_receive, send)
            
        except Exception as e:
            logger.error(f"处理POST消息时出错: {e}")
            # 发送错误响应
            await send({
                "type": "http.response.start",
                "status": 500,
                "headers": [[b"content-type", b"application/json"]],
            })
            await send({
                "type": "http.response.body",
                "body": json.dumps({
                    "jsonrpc": "2.0",
                    "error": {
                        "code": -32603,
                        "message": f"Internal error: {str(e)}"
                    }
                }).encode('utf-8'),
            })
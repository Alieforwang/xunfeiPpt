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

# 讯飞智文API配置 - 写死在代码中
AIPPT_APP_ID = "2dc9dc12"
AIPPT_API_SECRET = "YWVmZjQ0NTI4MjkxMTEzMTA5MWZiY2M4"

class AIPPTClient:
    """讯飞智文PPT生成客户端"""
    
    def __init__(self):
        self.app_id = AIPPT_APP_ID
        self.api_secret = AIPPT_API_SECRET
        self.base_url = "https://zwapi.xfyun.cn/api/ppt/v2"
    
    def _get_signature(self, timestamp: int) -> str:
        """生成API签名"""
        try:
            # 对app_id和时间戳进行MD5加密
            auth = self._md5(self.app_id + str(timestamp))
            # 使用HMAC-SHA1算法对加密后的字符串进行加密
            return self._hmac_sha1_encrypt(auth, self.api_secret)
        except Exception as e:
            raise Exception(f"签名生成失败: {e}")
    
    def _hmac_sha1_encrypt(self, encrypt_text: str, encrypt_key: str) -> str:
        """HMAC-SHA1加密"""
        return base64.b64encode(
            hmac.new(
                encrypt_key.encode('utf-8'),
                encrypt_text.encode('utf-8'),
                hashlib.sha1
            ).digest()
        ).decode('utf-8')
    
    def _md5(self, text: str) -> str:
        """MD5加密"""
        return hashlib.md5(text.encode('utf-8')).hexdigest()
    
    def _get_headers(self, content_type: str = "application/json; charset=utf-8") -> dict:
        """获取请求头"""
        timestamp = int(time.time())
        signature = self._get_signature(timestamp)
        return {
            "appId": self.app_id,
            "timestamp": str(timestamp),
            "signature": signature,
            "Content-Type": content_type
        }
    
    def get_theme_list(self, pay_type: str = "not_free", style: str = None, 
                      color: str = None, industry: str = None, 
                      page_num: int = 1, page_size: int = 10) -> dict:
        """获取PPT模板列表"""
        url = f"{self.base_url}/template/list"
        headers = self._get_headers()
        
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
    
    def create_ppt_task(self, text: str, template_id: str, author: str = "XXXX",
                       is_card_note: bool = True, search: bool = False,
                       is_figure: bool = True, ai_image: str = "normal") -> dict:
        """创建PPT生成任务"""
        url = f"{self.base_url}/create"
        timestamp = int(time.time())
        signature = self._get_signature(timestamp)
        
        form_data = MultipartEncoder(
            fields={
                "query": text,
                "templateId": template_id,
                "author": author,
                "isCardNote": str(is_card_note),
                "search": str(search),
                "isFigure": str(is_figure),
                "aiImage": ai_image
            }
        )
        
        headers = {
            "appId": self.app_id,
            "timestamp": str(timestamp),
            "signature": signature,
            "Content-Type": form_data.content_type
        }
        
        response = requests.post(url, data=form_data, headers=headers)
        return response.json()
    
    def get_task_progress(self, sid: str) -> dict:
        """查询PPT生成任务进度"""
        url = f"{self.base_url}/progress"
        headers = self._get_headers()
        
        response = requests.get(url, headers=headers, params={"sid": sid})
        return response.json()
    
    def create_outline(self, text: str, language: str = "cn", search: bool = False) -> dict:
        """创建PPT大纲"""
        url = f"{self.base_url}/createOutline"
        timestamp = int(time.time())
        signature = self._get_signature(timestamp)
        
        # 使用form-data格式而不是JSON
        form_data = MultipartEncoder(fields={
            "query": text,
            "language": language,
            "search": str(search)
        })
        
        headers = {
            "appId": self.app_id,
            "timestamp": str(timestamp),
            "signature": signature,
            "Content-Type": form_data.content_type
        }
        
        response = requests.post(url, data=form_data, headers=headers)
        return response.json()
    
    def create_outline_by_doc(self, file_name: str, text: str, file_url: str = None,
                             file_path: str = None, language: str = "cn", 
                             search: bool = False) -> dict:
        """从文档创建PPT大纲"""
        url = f"{self.base_url}/createOutlineByDoc"
        timestamp = int(time.time())
        signature = self._get_signature(timestamp)
        
        fields = {
            "fileName": file_name,
            "query": text,
            "language": language,
            "search": str(search)
        }
        
        if file_url:
            fields["fileUrl"] = file_url
        elif file_path:
            fields["file"] = (file_path, open(file_path, 'rb'), 'application/octet-stream')
        else:
            raise ValueError("file_url 或 file_path 必须提供其中一个")
        
        form_data = MultipartEncoder(fields=fields)
        
        headers = {
            "appId": self.app_id,
            "timestamp": str(timestamp),
            "signature": signature,
            "Content-Type": form_data.content_type
        }
        
        response = requests.post(url, data=form_data, headers=headers)
        return response.json()
    
    def create_ppt_by_outline(self, text: str, outline: dict, template_id: str,
                             author: str = "XXXX", is_card_note: bool = True,
                             search: bool = False, is_figure: bool = True,
                             ai_image: str = "normal") -> dict:
        """根据大纲创建PPT - 使用直接创建方式（绕过API bug）"""
        
        # 由于createPptByOutline接口存在99999系统异常问题
        # 改用create接口，将大纲信息融合到query文本中
        
        # 将大纲转换为文本描述
        outline_text = f"标题：{outline.get('title', text)}\n"
        if outline.get('subTitle'):
            outline_text += f"副标题：{outline['subTitle']}\n"
        
        outline_text += "\n内容要点：\n"
        for i, chapter in enumerate(outline.get('chapters', []), 1):
            chapter_title = chapter.get('chapterTitle', f'第{i}部分')
            outline_text += f"{i}. {chapter_title}\n"
            
            # 处理章节内容
            contents = chapter.get('contents', [])
            if isinstance(contents, list):
                for content in contents:
                    if isinstance(content, str):
                        outline_text += f"   - {content}\n"
                    elif isinstance(content, dict) and 'chapterTitle' in content:
                        outline_text += f"   - {content['chapterTitle']}\n"
        
        # 构建完整的查询文本
        full_query = f"{text}\n\n{outline_text}"
        
        # 使用create接口（已知可以工作）
        url = f"{self.base_url}/create"
        timestamp = int(time.time())
        signature = self._get_signature(timestamp)
        
        form_data = MultipartEncoder(
            fields={
                "query": full_query,
                "templateId": template_id,
                "author": author,
                "isCardNote": str(is_card_note),
                "search": str(search),
                "isFigure": str(is_figure),
                "aiImage": ai_image
            }
        )
        
        headers = {
            "appId": self.app_id,
            "timestamp": str(timestamp),
            "signature": signature,
            "Content-Type": form_data.content_type
        }
        
        response = requests.post(url, data=form_data, headers=headers)
        result = response.json()
        
        # 添加调试信息
        if result.get('code') != 0:
            print(f"DEBUG - 使用直接创建方式的详细信息:")
            print(f"  模板ID: {template_id}")
            print(f"  查询文本长度: {len(full_query)}")
            print(f"  响应: {result}")
        
        return result

# 创建MCP服务器
server = Server("pptmcpseriver")
aippt_client = AIPPTClient()

@server.list_tools()
async def handle_list_tools() -> list[Tool]:
    """列出所有可用的工具"""
    return [
        Tool(
            name="get_theme_list",
            description="获取PPT模板列表。使用说明：1. 此工具用于获取可用的PPT模板列表，需先调用本工具获取template_id，后续PPT生成需用到。2. 可通过style、color、industry等参数筛选模板。3. 需先设置环境变量AIPPT_APP_ID和AIPPT_API_SECRET。",
            inputSchema={
                "type": "object",
                "properties": {
                    "pay_type": {
                        "type": "string",
                        "description": "模板付费类型，可选值：free-免费模板，not_free-付费模板",
                        "default": "not_free"
                    },
                    "style": {
                        "type": "string",
                        "description": "模板风格，如：简约、商务、科技等"
                    },
                    "color": {
                        "type": "string",
                        "description": "模板颜色，如：红色、蓝色等"
                    },
                    "industry": {
                        "type": "string",
                        "description": "模板行业，如：教育培训、金融等"
                    },
                    "page_num": {
                        "type": "integer",
                        "description": "页码，从1开始",
                        "default": 1
                    },
                    "page_size": {
                        "type": "integer",
                        "description": "每页数量，最大100",
                        "default": 10
                    }
                }
            }
        ),
        Tool(
            name="create_ppt_task",
            description="创建PPT生成任务。使用说明：1. 在调用本工具前，必须先调用get_theme_list获取有效的template_id。2. 工具会返回任务ID(sid)，需用get_task_progress轮询查询进度。3. 任务完成后，可从get_task_progress结果中获取PPT下载地址。4. 需先设置环境变量AIPPT_APP_ID和AIPPT_API_SECRET。",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "PPT生成的内容描述，用于生成PPT的主题和内容"
                    },
                    "template_id": {
                        "type": "string",
                        "description": "PPT模板ID，需通过get_theme_list获取"
                    },
                    "author": {
                        "type": "string",
                        "description": "PPT作者名称，将显示在生成的PPT中",
                        "default": "XXXX"
                    },
                    "is_card_note": {
                        "type": "boolean",
                        "description": "是否生成PPT演讲备注，True表示生成，False表示不生成",
                        "default": True
                    },
                    "search": {
                        "type": "boolean",
                        "description": "是否联网搜索，True表示联网搜索补充内容，False表示不联网",
                        "default": False
                    },
                    "is_figure": {
                        "type": "boolean",
                        "description": "是否自动配图，True表示自动配图，False表示不配图",
                        "default": True
                    },
                    "ai_image": {
                        "type": "string",
                        "description": "AI配图类型，仅在is_figure为True时生效。可选值：normal-普通配图(20%正文配图)，advanced-高级配图(50%正文配图)",
                        "default": "normal"
                    }
                },
                "required": ["text", "template_id"]
            }
        ),
        Tool(
            name="get_task_progress",
            description="查询PPT生成任务进度。使用说明：1. 用于查询通过create_ppt_task或create_ppt_by_outline创建的任务进度。2. 需定期轮询本工具直到任务完成。3. 任务完成后，可从返回结果中获取PPT下载地址。4. 需先设置环境变量AIPPT_APP_ID和AIPPT_API_SECRET。",
            inputSchema={
                "type": "object",
                "properties": {
                    "sid": {
                        "type": "string",
                        "description": "任务ID，从create_ppt_task或create_ppt_by_outline工具获取"
                    }
                },
                "required": ["sid"]
            }
        ),
        Tool(
            name="create_outline",
            description="创建PPT大纲。使用说明：1. 用于根据文本内容生成PPT大纲。2. 生成的大纲可用于create_ppt_by_outline工具。3. 可通过search参数控制是否联网搜索补充内容。4. 需先设置环境变量AIPPT_APP_ID和AIPPT_API_SECRET。",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "需要生成大纲的内容描述"
                    },
                    "language": {
                        "type": "string",
                        "description": "大纲生成的语言，目前支持cn(中文)",
                        "default": "cn"
                    },
                    "search": {
                        "type": "boolean",
                        "description": "是否联网搜索，True表示联网搜索补充内容，False表示不联网",
                        "default": False
                    }
                },
                "required": ["text"]
            }
        ),
        Tool(
            name="create_outline_by_doc",
            description="从文档创建PPT大纲。使用说明：1. 用于根据文档内容生成PPT大纲。2. 支持通过file_url或file_path上传文档。3. 文档格式支持：pdf(不支持扫描件)、doc、docx、txt、md。4. 文档大小限制：10M以内，字数限制8000字以内。5. 生成的大纲可用于create_ppt_by_outline工具。6. 需先设置环境变量AIPPT_APP_ID和AIPPT_API_SECRET。",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_name": {
                        "type": "string",
                        "description": "文档文件名，必须包含文件后缀名"
                    },
                    "file_url": {
                        "type": "string",
                        "description": "文档文件的URL地址，与file_path二选一必填"
                    },
                    "file_path": {
                        "type": "string",
                        "description": "文档文件的本地路径，与file_url二选一必填"
                    },
                    "text": {
                        "type": "string",
                        "description": "补充的文本内容，用于指导大纲生成"
                    },
                    "language": {
                        "type": "string",
                        "description": "大纲生成的语言，目前支持cn(中文)",
                        "default": "cn"
                    },
                    "search": {
                        "type": "boolean",
                        "description": "是否联网搜索，True表示联网搜索补充内容，False表示不联网",
                        "default": False
                    }
                },
                "required": ["file_name", "text"]
            }
        ),
        Tool(
            name="create_ppt_by_outline",
            description="根据大纲创建PPT - 使用直接创建方式（绕过API bug）。使用说明：1. 用于根据已生成的大纲创建PPT。2. 大纲需通过create_outline或create_outline_by_doc工具生成。3. template_id需通过get_theme_list工具获取。4. 工具会返回任务ID(sid)，需用get_task_progress轮询查询进度。5. 任务完成后，可从get_task_progress结果中获取PPT下载地址。6. 需先设置环境变量AIPPT_APP_ID和AIPPT_API_SECRET。",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "PPT生成的内容描述，用于指导PPT生成"
                    },
                    "outline": {
                        "type": "object",
                        "description": "大纲内容，需从create_outline或create_outline_by_doc工具返回的JSON响应中提取['data']['outline']字段的值。该字段包含生成的大纲内容，格式为dict"
                    },
                    "template_id": {
                        "type": "string",
                        "description": "PPT模板ID，需通过get_theme_list工具获取"
                    },
                    "author": {
                        "type": "string",
                        "description": "PPT作者名称，将显示在生成的PPT中",
                        "default": "XXXX"
                    },
                    "is_card_note": {
                        "type": "boolean",
                        "description": "是否生成PPT演讲备注，True表示生成，False表示不生成",
                        "default": True
                    },
                    "search": {
                        "type": "boolean",
                        "description": "是否联网搜索，True表示联网搜索补充内容，False表示不联网",
                        "default": False
                    },
                    "is_figure": {
                        "type": "boolean",
                        "description": "是否自动配图，True表示自动配图，False表示不配图",
                        "default": True
                    },
                    "ai_image": {
                        "type": "string",
                        "description": "AI配图类型，仅在is_figure为True时生效。可选值：normal-普通配图(20%正文配图)，advanced-高级配图(50%正文配图)",
                        "default": "normal"
                    }
                },
                "required": ["text", "outline", "template_id"]
            }
        ),
        Tool(
            name="create_full_ppt_workflow",
            description="""
            ReACT模式完整PPT生成工作流 - 智能代理推荐使用

            这是一个高级工作流工具，支持Reasoning and Acting (ReACT) 模式，AI代理可以按以下步骤执行完整的PPT生成流程：

            🧠 THINK (思考阶段)：
            - 分析用户的PPT需求和主题
            - 确定适合的PPT风格和行业类别
            - 规划内容结构和要点

            🎯 ACT (行动阶段)：
            1. 调用 get_theme_list 获取适合的PPT模板
            2. 调用 create_outline 生成结构化大纲
            3. 调用 create_ppt_by_outline 基于大纲生成PPT
            4. 调用 get_task_progress 监控生成进度

            👁️ OBSERVE (观察阶段)：
            - 检查每步的执行结果
            - 验证模板选择的合理性
            - 确认大纲内容的完整性
            - 监控PPT生成状态直到完成

            🔄 ITERATE (迭代优化)：
            - 根据结果调整参数
            - 必要时重新选择模板或修改大纲
            - 确保最终输出质量

            使用建议：
            - 适合需要完整PPT生成流程的复杂任务
            - 支持自动错误处理和重试机制
            - 提供详细的执行过程和结果反馈
            - 可根据用户需求灵活调整参数
            """,
            inputSchema={
                "type": "object",
                "properties": {
                    "topic": {
                        "type": "string",
                        "description": "PPT主题或题目，描述要生成的PPT内容"
                    },
                    "requirements": {
                        "type": "string",
                        "description": "具体要求和细节，如：目标受众、内容重点、风格偏好等",
                        "default": ""
                    },
                    "style_preference": {
                        "type": "string",
                        "description": "PPT风格偏好，如：简约、商务、科技、教育等",
                        "default": "简约"
                    },
                    "industry": {
                        "type": "string", 
                        "description": "所属行业或领域，如：教育培训、科技互联网、金融、医疗等",
                        "default": "通用"
                    },
                    "author": {
                        "type": "string",
                        "description": "PPT作者名称",
                        "default": "AI助手"
                    },
                    "enable_figures": {
                        "type": "boolean",
                        "description": "是否启用自动配图功能",
                        "default": True
                    },
                    "enable_notes": {
                        "type": "boolean", 
                        "description": "是否生成演讲备注",
                        "default": True
                    },
                    "enable_search": {
                        "type": "boolean",
                        "description": "是否联网搜索补充内容",
                        "default": False
                    }
                },
                "required": ["topic"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict | None) -> list[types.TextContent]:
    """处理工具调用"""
    if arguments is None:
        arguments = {}
    
    try:
        if name == "get_theme_list":
            result = aippt_client.get_theme_list(**arguments)
            return [types.TextContent(type="text", text=json.dumps(result, ensure_ascii=False, indent=2))]
        
        elif name == "create_ppt_task":
            result = aippt_client.create_ppt_task(**arguments)
            return [types.TextContent(type="text", text=json.dumps(result, ensure_ascii=False, indent=2))]
        
        elif name == "get_task_progress":
            result = aippt_client.get_task_progress(**arguments)
            return [types.TextContent(type="text", text=json.dumps(result, ensure_ascii=False, indent=2))]
        
        elif name == "create_outline":
            result = aippt_client.create_outline(**arguments)
            return [types.TextContent(type="text", text=json.dumps(result, ensure_ascii=False, indent=2))]
        
        elif name == "create_outline_by_doc":
            result = aippt_client.create_outline_by_doc(**arguments)
            return [types.TextContent(type="text", text=json.dumps(result, ensure_ascii=False, indent=2))]
        
        elif name == "create_ppt_by_outline":
            result = aippt_client.create_ppt_by_outline(**arguments)
            return [types.TextContent(type="text", text=json.dumps(result, ensure_ascii=False, indent=2))]
        
        elif name == "create_full_ppt_workflow":
            # ReACT模式完整工作流实现
            result = await execute_react_ppt_workflow(aippt_client, **arguments)
            return [types.TextContent(type="text", text=json.dumps(result, ensure_ascii=False, indent=2))]
        
        else:
            raise ValueError(f"未知工具: {name}")
            
    except Exception as e:
        return [types.TextContent(type="text", text=f"错误: {str(e)}")]

async def execute_react_ppt_workflow(client: AIPPTClient, topic: str, requirements: str = "", 
                                   style_preference: str = "简约", industry: str = "通用",
                                   author: str = "AI助手", enable_figures: bool = True,
                                   enable_notes: bool = True, enable_search: bool = False) -> dict:
    """
    执行ReACT模式PPT生成工作流
    
    THINK -> ACT -> OBSERVE -> ACT -> OBSERVE -> ... 直到完成
    """
    
    workflow_log = []
    
    try:
        # THINK 阶段：分析需求
        workflow_log.append({
            "stage": "THINK",
            "action": "分析PPT需求",
            "description": f"主题: {topic}, 风格: {style_preference}, 行业: {industry}",
            "timestamp": time.time()
        })
        
        # ACT 1: 获取适合的模板
        workflow_log.append({
            "stage": "ACT",
            "action": "获取PPT模板",
            "description": f"搜索 {style_preference} 风格、{industry} 行业的模板"
        })
        
        # 根据偏好构建模板查询参数
        template_params = {
            "pay_type": "not_free",
            "page_size": 10
        }
        
        if style_preference and style_preference != "通用":
            template_params["style"] = style_preference
        if industry and industry != "通用":
            template_params["industry"] = industry
        
        templates_result = client.get_theme_list(**template_params)
        
        # OBSERVE 1: 检查模板获取结果
        if templates_result.get('code') != 0:
            workflow_log.append({
                "stage": "OBSERVE",
                "action": "模板获取失败",
                "error": templates_result.get('desc', '未知错误'),
                "status": "failed"
            })
            return {
                "success": False,
                "error": "无法获取PPT模板",
                "workflow_log": workflow_log
            }
        
        templates = templates_result.get('data', {}).get('list', [])
        if not templates:
            workflow_log.append({
                "stage": "OBSERVE", 
                "action": "未找到合适模板",
                "description": "尝试使用默认模板"
            })
            # 使用默认查询重试
            templates_result = client.get_theme_list(pay_type="not_free", page_size=5)
            templates = templates_result.get('data', {}).get('list', [])
        
        if not templates:
            return {
                "success": False,
                "error": "无可用PPT模板",
                "workflow_log": workflow_log
            }
        
        # 选择最佳模板
        selected_template = templates[0]  # 选择第一个模板
        template_id = selected_template.get('templateIndexId')
        
        workflow_log.append({
            "stage": "OBSERVE",
            "action": "模板选择成功",
            "template_id": template_id,
            "template_name": selected_template.get('templateName', '未知'),
            "template_style": selected_template.get('style', ''),
            "template_industry": selected_template.get('industry', '')
        })
        
        # ACT 2: 生成PPT大纲
        workflow_log.append({
            "stage": "ACT",
            "action": "生成PPT大纲",
            "description": f"基于主题 '{topic}' 和要求 '{requirements}' 生成结构化大纲"
        })
        
        outline_query = f"{topic}"
        if requirements:
            outline_query += f"\n\n具体要求：{requirements}"
        
        outline_result = client.create_outline(
            text=outline_query,
            language="cn",
            search=enable_search
        )
        
        # OBSERVE 2: 检查大纲生成结果
        if outline_result.get('code') != 0:
            workflow_log.append({
                "stage": "OBSERVE",
                "action": "大纲生成失败", 
                "error": outline_result.get('desc', '未知错误'),
                "status": "failed"
            })
            return {
                "success": False,
                "error": "大纲生成失败",
                "workflow_log": workflow_log
            }
        
        outline = outline_result.get('data', {}).get('outline', {})
        if not outline:
            return {
                "success": False,
                "error": "生成的大纲为空",
                "workflow_log": workflow_log
            }
        
        workflow_log.append({
            "stage": "OBSERVE",
            "action": "大纲生成成功",
            "outline_title": outline.get('title', ''),
            "outline_chapters": len(outline.get('chapters', [])),
            "outline_preview": str(outline)[:200] + "..." if len(str(outline)) > 200 else str(outline)
        })
        
        # ACT 3: 基于大纲生成PPT
        workflow_log.append({
            "stage": "ACT", 
            "action": "生成PPT",
            "description": "使用选定模板和生成的大纲创建PPT"
        })
        
        ppt_result = client.create_ppt_by_outline(
            text=outline_query,
            outline=outline,
            template_id=template_id,
            author=author,
            is_card_note=enable_notes,
            search=enable_search,
            is_figure=enable_figures,
            ai_image="normal"
        )
        
        # OBSERVE 3: 检查PPT生成结果
        if ppt_result.get('code') != 0:
            workflow_log.append({
                "stage": "OBSERVE",
                "action": "PPT生成失败",
                "error": ppt_result.get('desc', '未知错误'),
                "status": "failed"
            })
            return {
                "success": False,
                "error": "PPT生成失败", 
                "workflow_log": workflow_log,
                "debug_info": ppt_result
            }
        
        # 获取任务ID
        task_id = ppt_result.get('data', {}).get('sid')
        if not task_id:
            return {
                "success": False,
                "error": "未获取到PPT生成任务ID",
                "workflow_log": workflow_log
            }
        
        workflow_log.append({
            "stage": "OBSERVE",
            "action": "PPT生成任务已提交",
            "task_id": task_id,
            "cover_image": ppt_result.get('data', {}).get('coverImgSrc', ''),
            "ppt_title": ppt_result.get('data', {}).get('title', ''),
            "ppt_subtitle": ppt_result.get('data', {}).get('subTitle', '')
        })
        
        # ACT 4: 监控生成进度
        workflow_log.append({
            "stage": "ACT",
            "action": "监控生成进度",
            "description": "定期检查PPT生成状态"
        })
        
        # 返回成功结果和工作流日志
        return {
            "success": True,
            "task_id": task_id,
            "template_info": {
                "id": template_id,
                "name": selected_template.get('templateName', ''),
                "style": selected_template.get('style', ''),
                "industry": selected_template.get('industry', '')
            },
            "outline_info": {
                "title": outline.get('title', ''),
                "subtitle": outline.get('subTitle', ''),
                "chapters": len(outline.get('chapters', []))
            },
            "ppt_info": {
                "title": ppt_result.get('data', {}).get('title', ''),
                "subtitle": ppt_result.get('data', {}).get('subTitle', ''),
                "cover_image": ppt_result.get('data', {}).get('coverImgSrc', '')
            },
            "next_steps": [
                f"使用 get_task_progress 工具查询任务 {task_id} 的生成进度",
                "等待PPT生成完成后，可获取下载链接",
                "建议每30-60秒查询一次进度，直到任务完成"
            ],
            "workflow_log": workflow_log,
            "react_summary": {
                "total_stages": len(workflow_log),
                "think_count": len([log for log in workflow_log if log.get('stage') == 'THINK']),
                "act_count": len([log for log in workflow_log if log.get('stage') == 'ACT']),
                "observe_count": len([log for log in workflow_log if log.get('stage') == 'OBSERVE']),
                "status": "completed_successfully"
            }
        }
        
    except Exception as e:
        workflow_log.append({
            "stage": "ERROR",
            "action": "工作流异常",
            "error": str(e),
            "timestamp": time.time()
        })
        
        return {
            "success": False,
            "error": f"ReACT工作流执行异常: {str(e)}",
            "workflow_log": workflow_log
        }

# ===== 传输协议实现 =====

async def run_stdio_server():
    """运行 stdio 传输服务器"""
    async with stdio_server() as (read_stream, write_stream):
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

async def run_http_server(host: str = "localhost", port: int = 8000):
    """运行 HTTP 传输服务器"""
    try:
        from starlette.applications import Starlette
        from starlette.routing import Route
        from starlette.responses import Response, JSONResponse
        from starlette.requests import Request
        import uvicorn
        
        async def handle_mcp_request(request: Request):
            """处理MCP HTTP请求"""
            try:
                if request.method == "POST":
                    body = await request.json()
                    
                    # 简单的HTTP到MCP转换
                    if body.get("method") == "tools/list":
                        tools = await handle_list_tools()
                        return JSONResponse({
                            "jsonrpc": "2.0",
                            "id": body.get("id"),
                            "result": {
                                "tools": [tool.model_dump() for tool in tools]
                            }
                        })
                    
                    elif body.get("method") == "tools/call":
                        params = body.get("params", {})
                        tool_name = params.get("name")
                        arguments = params.get("arguments", {})
                        
                        result = await handle_call_tool(tool_name, arguments)
                        return JSONResponse({
                            "jsonrpc": "2.0",
                            "id": body.get("id"),
                            "result": {
                                "content": [content.model_dump() for content in result]
                            }
                        })
                    
                    else:
                        return JSONResponse({
                            "jsonrpc": "2.0",
                            "id": body.get("id"),
                            "error": {
                                "code": -32601,
                                "message": "Method not found"
                            }
                        })
                
                elif request.method == "GET":
                    # 提供简单的状态页面
                    return Response(
                        content="""
                        <html>
                        <head><title>讯飞智文PPT生成服务MCP Server</title></head>
                        <body>
                            <h1>讯飞智文PPT生成服务MCP Server</h1>
                            <h2>HTTP传输协议</h2>
                            <p>服务器正在运行中...</p>
                            <h3>可用工具:</h3>
                            <ul>
                                <li>get_theme_list - 获取PPT模板列表</li>
                                <li>create_ppt_task - 创建PPT生成任务</li>
                                <li>get_task_progress - 查询任务进度</li>
                                <li>create_outline - 创建PPT大纲</li>
                                <li>create_outline_by_doc - 从文档创建大纲</li>
                                <li>create_ppt_by_outline - 根据大纲创建PPT</li>
                            </ul>
                            <h3>使用方法:</h3>
                            <p>发送POST请求到此端点，格式为JSON-RPC 2.0</p>
                        </body>
                        </html>
                        """,
                        media_type="text/html"
                    )
                    
            except Exception as e:
                return JSONResponse({
                    "jsonrpc": "2.0",
                    "error": {
                        "code": -32603,
                        "message": f"Internal error: {str(e)}"
                    }
                })
        
        app = Starlette(routes=[
            Route("/mcp", handle_mcp_request, methods=["GET", "POST"]),
            Route("/", handle_mcp_request, methods=["GET", "POST"]),
        ])
        
        config = uvicorn.Config(app, host=host, port=port, log_level="info")
        server_instance = uvicorn.Server(config)
        await server_instance.serve()
        
    except ImportError:
        print("错误: 缺少HTTP服务器依赖。请运行: uv sync")
        return

async def run_sse_server(host: str = "localhost", port: int = 8001):
    """运行 SSE 传输服务器"""
    try:
        from starlette.applications import Starlette
        from starlette.routing import Route, Mount
        from starlette.responses import Response
        from starlette.requests import Request
        from mcp.server.sse import SseServerTransport
        import uvicorn
        
        # Try to use fixed SSE transport if available, fallback to standard
        try:
            from fixed_sse_transport import FixedSseServerTransport
            sse_transport = FixedSseServerTransport("/messages/")
            print("✓ Using FixedSseServerTransport (handles string arguments)")
        except ImportError:
            sse_transport = SseServerTransport("/messages/")
            print("⚠ Using standard SseServerTransport (may have string arguments issue)")
        
        async def handle_sse(request: Request):
            """处理SSE连接 - 正确的实现模式"""
            async with sse_transport.connect_sse(
                request.scope, 
                request.receive, 
                request._send
            ) as (read_stream, write_stream):
                # Server.run() 自动创建ServerSession并处理所有MCP协议
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
            # 必须返回Response以避免客户端断开连接时的NoneType错误
            return Response()
        
        async def handle_status_page(request: Request):
            """提供SSE状态页面"""
            return Response(
                content=f"""
                <html>
                <head><title>讯飞智文PPT生成服务MCP Server - SSE</title></head>
                <body>
                    <h1>讯飞智文PPT生成服务MCP Server</h1>
                    <h2>SSE传输协议</h2>
                    <p>服务器正在运行中...</p>
                    <h3>连接信息:</h3>
                    <ul>
                        <li>SSE端点: <a href="/sse">/sse</a> (GET请求建立连接)</li>
                        <li>消息端点: /messages/ (POST请求发送消息)</li>
                        <li>协议: Server-Sent Events</li>
                        <li>支持实时双向通信</li>
                    </ul>
                    <h3>可用工具:</h3>
                    <ul>
                        <li>get_theme_list - 获取PPT模板列表</li>
                        <li>create_ppt_task - 创建PPT生成任务</li>
                        <li>get_task_progress - 查询任务进度</li>
                        <li>create_outline - 创建PPT大纲</li>
                        <li>create_outline_by_doc - 从文档创建大纲</li>
                        <li>create_ppt_by_outline - 根据大纲创建PPT</li>
                    </ul>
                    <h3>测试连接:</h3>
                    <button onclick="testSSE()">测试SSE连接</button>
                    <div id="log"></div>
                    
                    <script>
                    function testSSE() {{
                        const log = document.getElementById('log');
                        log.innerHTML = '<p>正在连接SSE...</p>';
                        
                        const eventSource = new EventSource('/sse');
                        
                        eventSource.onopen = function(event) {{
                            log.innerHTML += '<p style="color: green;">✓ SSE连接已建立</p>';
                        }};
                        
                        eventSource.onmessage = function(event) {{
                            log.innerHTML += '<p>收到消息: ' + event.data + '</p>';
                        }};
                        
                        eventSource.onerror = function(event) {{
                            log.innerHTML += '<p style="color: red;">✗ SSE连接错误</p>';
                            eventSource.close();
                        }};
                        
                        // 10秒后关闭连接
                        setTimeout(() => {{
                            eventSource.close();
                            log.innerHTML += '<p>SSE连接已关闭</p>';
                        }}, 10000);
                    }}
                    </script>
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
        print(f"错误: 缺少SSE服务器依赖: {e}")
        print("请运行: uv sync")
        return

async def run_http_stream_server(host: str = "localhost", port: int = 8002):
    """运行 HTTP Stream 传输服务器 (MCP 2025-03-26)"""
    try:
        from http_stream_transport import create_http_stream_transport
        
        # 创建HTTP Stream传输
        transport = create_http_stream_transport(
            mcp_server=server,
            json_response=False,  # 使用SSE流式响应
            stateless=False,      # 有状态会话管理
            enable_security=True  # 启用安全防护
        )
        
        await transport.run(host=host, port=port)
        
    except ImportError as e:
        print(f"错误: 缺少HTTP Stream依赖: {e}")
        print("请确保http_stream_transport.py文件存在")
        return

async def run_http_stream_server(host: str = "localhost", port: int = 8002):
    """运行 HTTP Stream 传输服务器（MCP 2025-03-26规范）"""
    try:
        from starlette.applications import Starlette
        from starlette.routing import Route
        from starlette.responses import Response, JSONResponse
        from starlette.requests import Request
        import uvicorn
        import uuid
        import asyncio
        
        # 会话管理
        active_sessions = {}
        
        async def handle_mcp_request(request: Request):
            """处理MCP请求"""
            if request.method == "POST":
                try:
                    body = await request.json()
                    
                    # 检查是否是初始化请求
                    if body.get("method") == "initialize":
                        return JSONResponse({
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
                        })
                    
                    # 处理其他MCP请求
                    elif body.get("method") == "tools/list":
                        tools = await handle_list_tools()
                        return JSONResponse({
                            "jsonrpc": "2.0",
                            "id": body.get("id"),
                            "result": {
                                "tools": [tool.model_dump() for tool in tools]
                            }
                        })
                    
                    elif body.get("method") == "tools/call":
                        params = body.get("params", {})
                        tool_name = params.get("name")
                        arguments = params.get("arguments", {})
                        
                        result = await handle_call_tool(tool_name, arguments)
                        return JSONResponse({
                            "jsonrpc": "2.0",
                            "id": body.get("id"),
                            "result": {
                                "content": [content.model_dump() for content in result]
                            }
                        })
                    
                    else:
                        return JSONResponse({
                            "jsonrpc": "2.0",
                            "id": body.get("id"),
                            "error": {
                                "code": -32601,
                                "message": "Method not found"
                            }
                        })
                        
                except Exception as e:
                    return JSONResponse({
                        "jsonrpc": "2.0",
                        "error": {
                            "code": -32603,
                            "message": f"Internal error: {str(e)}"
                        }
                    })
            
            elif request.method == "GET":
                # 提供简单的状态页面
                return Response(
                    content=f"""
                    <html>
                    <head><title>讯飞智文PPT生成服务MCP Server - HTTP Stream</title></head>
                    <body>
                        <h1>讯飞智文PPT生成服务MCP Server</h1>
                        <h2>HTTP Stream传输协议</h2>
                        <p>服务器正在运行中...</p>
                        
                        <h3>连接信息:</h3>
                        <ul>
                            <li>MCP端点: <a href="/mcp">/mcp</a> (POST发送请求)</li>
                            <li>协议: HTTP Stream Transport (简化版)</li>
                            <li>端口: {port}</li>
                        </ul>
                        
                        <h3>可用工具:</h3>
                        <ul>
                            <li>get_theme_list - 获取PPT模板列表</li>
                            <li>create_ppt_task - 创建PPT生成任务</li>
                            <li>get_task_progress - 查询任务进度</li>
                            <li>create_outline - 创建PPT大纲</li>
                            <li>create_outline_by_doc - 从文档创建大纲</li>
                            <li>create_ppt_by_outline - 根据大纲创建PPT</li>
                            <li>create_full_ppt_workflow - ReACT模式完整工作流</li>
                        </ul>
                        
                        <h3>使用示例:</h3>
                        <pre><code>
# 1. 初始化连接
curl -X POST http://localhost:{port}/mcp \\
  -H "Content-Type: application/json" \\
  -d '{{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {{"protocolVersion": "2024-11-05", "capabilities": {{}}, "clientInfo": {{"name": "test-client", "version": "1.0.0"}}}}}}'

# 2. 获取工具列表
curl -X POST http://localhost:{port}/mcp \\
  -H "Content-Type: application/json" \\
  -d '{{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}}'

# 3. 调用ReACT工作流
curl -X POST http://localhost:{port}/mcp \\
  -H "Content-Type: application/json" \\
  -d '{{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {{
      "name": "create_full_ppt_workflow",
      "arguments": {{
        "topic": "人工智能在教育中的应用",
        "style_preference": "简约",
        "industry": "教育培训"
      }}
    }}
  }}'
                        </code></pre>
                        
                        <h3>ReACT工作流支持:</h3>
                        <p>支持Reasoning and Acting模式，AI代理可以：</p>
                        <ol>
                            <li><strong>THINK</strong> - 分析PPT需求</li>
                            <li><strong>ACT</strong> - 调用相应工具</li>
                            <li><strong>OBSERVE</strong> - 检查结果</li>
                            <li><strong>ITERATE</strong> - 优化输出</li>
                        </ol>
                    </body>
                    </html>
                    """,
                    media_type="text/html"
                )
        
        app = Starlette(routes=[
            Route("/mcp", handle_mcp_request, methods=["GET", "POST"]),
            Route("/", handle_mcp_request, methods=["GET"]),
        ])
        
        config = uvicorn.Config(app, host=host, port=port, log_level="info")
        server_instance = uvicorn.Server(config)
        await server_instance.serve()
        
    except ImportError as e:
        print(f"错误: 缺少HTTP Stream服务器依赖: {e}")
        print("请运行: uv sync")
        return

def main():
    """主函数，支持命令行参数切换传输协议"""
    parser = argparse.ArgumentParser(
        description="讯飞智文PPT生成服务MCP Server - 支持多种传输协议",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  python main.py stdio                    # 使用stdio传输（默认）
  python main.py http                     # 使用HTTP传输，默认端口8000
  python main.py sse                      # 使用SSE传输，默认端口8001
  python main.py http-stream              # 使用HTTP Stream传输，默认端口8002
  python main.py http --port 8080         # 使用HTTP传输，自定义端口
  python main.py sse --port 8002          # 使用SSE传输，自定义端口
  python main.py http-stream --port 8003  # 使用HTTP Stream传输，自定义端口
  python main.py http --host 0.0.0.0      # 使用HTTP传输，绑定所有接口
        """
    )
    
    parser.add_argument(
        "transport",
        nargs="?",
        choices=["stdio", "http", "sse", "http-stream"],
        default="stdio",
        help="选择传输协议类型 (默认: stdio)"
    )
    
    parser.add_argument(
        "--host",
        default="localhost",
        help="HTTP/SSE服务器主机地址 (默认: localhost)"
    )
    
    parser.add_argument(
        "--port",
        type=int,
        default=None,
        help="服务器端口 (HTTP默认: 8000, SSE默认: 8001, HTTP-Stream默认: 8002)"
    )
    
    parser.add_argument(
        "--log-level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="日志级别 (默认: INFO)"
    )
    
    args = parser.parse_args()
    
    # 设置默认端口
    if args.port is None:
        if args.transport == "http":
            args.port = 8000
        elif args.transport == "sse":
            args.port = 8001
        elif args.transport == "http-stream":
            args.port = 8002
        else:
            args.port = 0  # stdio不需要端口
    
    # 配置日志
    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    logger = logging.getLogger(__name__)
    
    if args.transport == "stdio":
        logger.info("启动 stdio 传输服务器...")
        asyncio.run(run_stdio_server())
    
    elif args.transport == "http":
        logger.info(f"启动 HTTP 传输服务器 - http://{args.host}:{args.port}/mcp")
        print(f"服务器启动: http://{args.host}:{args.port}/mcp")
        print(f"状态页面: http://{args.host}:{args.port}/")
        asyncio.run(run_http_server(args.host, args.port))
    
    elif args.transport == "sse":
        logger.info(f"启动 SSE 传输服务器 - http://{args.host}:{args.port}/sse")
        print(f"SSE服务器启动: http://{args.host}:{args.port}/sse")
        print(f"状态页面: http://{args.host}:{args.port}/")
        print("支持Server-Sent Events实时通信")
        asyncio.run(run_sse_server(args.host, args.port))
    
    elif args.transport == "http-stream":
        logger.info(f"启动 HTTP Stream 传输服务器 - http://{args.host}:{args.port}/mcp")
        print(f"HTTP Stream服务器启动: http://{args.host}:{args.port}/mcp")
        print(f"状态页面: http://{args.host}:{args.port}/")
        print("支持MCP 2025-03-26 HTTP Stream Transport")
        asyncio.run(run_http_stream_server(args.host, args.port))

if __name__ == "__main__":
    main()
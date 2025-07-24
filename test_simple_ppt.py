#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试简化的PPT生成请求
"""
import requests
import time
import hashlib
import hmac
import base64
import json
from requests_toolbelt.multipart.encoder import MultipartEncoder

# API配置
AIPPT_APP_ID = "2dc9dc12"
AIPPT_API_SECRET = "YWVmZjQ0NTI4MjkxMTEzMTA5MWZiY2M4"
BASE_URL = "https://zwapi.xfyun.cn/api/ppt/v2"

def get_signature(app_id, api_secret, timestamp):
    """生成API签名"""
    auth = hashlib.md5((app_id + str(timestamp)).encode('utf-8')).hexdigest()
    return base64.b64encode(
        hmac.new(
            api_secret.encode('utf-8'),
            auth.encode('utf-8'),
            hashlib.sha1
        ).digest()
    ).decode('utf-8')

def get_headers(content_type="application/json; charset=utf-8"):
    """获取请求头"""
    timestamp = int(time.time())
    signature = get_signature(AIPPT_APP_ID, AIPPT_API_SECRET, timestamp)
    return {
        "appId": AIPPT_APP_ID,
        "timestamp": str(timestamp),
        "signature": signature,
        "Content-Type": content_type
    }

def test_simple_outline_ppt():
    """测试简化的大纲PPT生成"""
    print("测试简化版团日活动PPT生成...")
    
    # 使用最新的有效模板ID (从诊断结果获取)
    template_id = "202407179097C2D"
    
    # 简化的大纲结构
    simple_outline = {
        "title": "传承雷锋精神 绿化美丽家园",
        "subTitle": "2025年3月主题团日活动",
        "chapters": [
            {
                "chapterTitle": "活动背景",
                "contents": [
                    "雷锋精神传承",
                    "生态文明建设",
                    "团日活动意义"
                ]
            },
            {
                "chapterTitle": "核心活动",
                "contents": [
                    "志愿服务实践",
                    "植树环保行动", 
                    "心理健康教育"
                ]
            },
            {
                "chapterTitle": "实施方案",
                "contents": [
                    "时间安排",
                    "参与方式",
                    "成果展示"
                ]
            }
        ]
    }
    
    url = f"{BASE_URL}/createPptByOutline"
    headers = get_headers()
    
    body = {
        "query": "2025年3月主题团日活动部署",
        "outline": simple_outline,
        "templateId": template_id,
        "author": "学院团委",
        "isCardNote": True,
        "search": False,
        "isFigure": True,
        "aiImage": "normal"
    }
    
    print(f"使用模板ID: {template_id}")
    print(f"请求体大小: {len(json.dumps(body, ensure_ascii=False))} 字符")
    
    try:
        response = requests.post(url, json=body, headers=headers, timeout=30)
        print(f"状态码: {response.status_code}")
        result = response.json()
        print(f"响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
        
        if result.get('code') == 0:
            print("SUCCESS 简化版PPT创建成功！")
            sid = result.get('data', {}).get('sid')
            print(f"任务ID: {sid}")
            return sid
        else:
            print(f"FAILED PPT创建失败: {result.get('desc', 'Unknown error')}")
            print(f"错误代码: {result.get('code')}")
            
            # 如果还是99999错误，尝试更简单的结构
            if result.get('code') == 99999:
                print("\n尝试更简单的大纲结构...")
                return test_ultra_simple_outline()
    except Exception as e:
        print(f"ERROR 请求异常: {e}")
    
    return None

def test_ultra_simple_outline():
    """测试超简化大纲"""
    template_id = "202407179097C2D"
    
    # 超简化结构
    ultra_simple_outline = {
        "title": "团日活动部署",
        "subTitle": "2025年3月活动安排",
        "chapters": [
            {
                "chapterTitle": "活动主题",
                "contents": ["传承雷锋精神", "绿化美丽家园"]
            },
            {
                "chapterTitle": "活动安排", 
                "contents": ["志愿服务", "植树活动"]
            }
        ]
    }
    
    url = f"{BASE_URL}/createPptByOutline"
    headers = get_headers()
    
    body = {
        "query": "团日活动",
        "outline": ultra_simple_outline,
        "templateId": template_id,
        "author": "团委",
        "isCardNote": False,  # 简化参数
        "search": False,
        "isFigure": False,    # 关闭配图
        "aiImage": "normal"
    }
    
    print(f"超简化请求体大小: {len(json.dumps(body, ensure_ascii=False))} 字符")
    
    try:
        response = requests.post(url, json=body, headers=headers, timeout=30)
        result = response.json()
        print(f"超简化版响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
        
        if result.get('code') == 0:
            print("SUCCESS 超简化版PPT创建成功！")
            return result.get('data', {}).get('sid')
        else:
            print(f"FAILED 超简化版也失败: {result.get('desc')}")
    except Exception as e:
        print(f"ERROR 超简化版异常: {e}")
        
    return None

if __name__ == "__main__":
    print("简化版PPT生成测试")
    print("=" * 40)
    test_simple_outline_ppt()
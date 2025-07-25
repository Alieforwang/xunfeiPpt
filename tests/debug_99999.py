#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试不同的PPT生成方式以找出99999错误原因
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
    auth = hashlib.md5((app_id + str(timestamp)).encode('utf-8')).hexdigest()
    return base64.b64encode(
        hmac.new(
            api_secret.encode('utf-8'),
            auth.encode('utf-8'),
            hashlib.sha1
        ).digest()
    ).decode('utf-8')

def get_headers(content_type="application/json; charset=utf-8"):
    timestamp = int(time.time())
    signature = get_signature(AIPPT_APP_ID, AIPPT_API_SECRET, timestamp)
    return {
        "appId": AIPPT_APP_ID,
        "timestamp": str(timestamp),
        "signature": signature,
        "Content-Type": content_type
    }

def test_direct_ppt_creation():
    """测试直接创建PPT（绕过大纲步骤）"""
    print("测试1：直接创建PPT（不使用预生成大纲）")
    
    url = f"{BASE_URL}/create"
    timestamp = int(time.time())
    signature = get_signature(AIPPT_APP_ID, AIPPT_API_SECRET, timestamp)
    
    # 使用不同的模板
    template_id = "202407176CA9161"  # 原始使用的模板
    
    form_data = MultipartEncoder(fields={
        "query": "团委2025年3月主题团日活动部署通知",
        "templateId": template_id,
        "author": "学院团委",
        "isCardNote": "true",
        "search": "false",
        "isFigure": "true",
        "aiImage": "normal"
    })
    
    headers = {
        "appId": AIPPT_APP_ID,
        "timestamp": str(timestamp),
        "signature": signature,
        "Content-Type": form_data.content_type
    }
    
    try:
        response = requests.post(url, data=form_data, headers=headers, timeout=30)
        result = response.json()
        print(f"直接创建结果: {json.dumps(result, indent=2, ensure_ascii=False)}")
        
        if result.get('code') == 0:
            print("SUCCESS 直接创建PPT成功！")
            return result.get('data', {}).get('sid')
        else:
            print(f"FAILED 直接创建失败: {result.get('desc')}")
    except Exception as e:
        print(f"ERROR 直接创建异常: {e}")
    
    return None

def test_different_templates():
    """测试不同模板"""
    print("\n测试2：尝试不同的模板ID")
    
    # 从诊断中获取的几个模板ID
    template_ids = [
        "202407179097C2D",
        "2024071754A6ADE", 
        "20240718489569D",
        "20240718838CDA2"
    ]
    
    simple_outline = {
        "title": "团日活动",
        "subTitle": "活动安排",
        "chapters": [
            {
                "chapterTitle": "活动内容",
                "contents": ["主题活动", "实践活动"]
            }
        ]
    }
    
    for template_id in template_ids:
        print(f"\n尝试模板: {template_id}")
        
        url = f"{BASE_URL}/createPptByOutline"
        headers = get_headers()
        
        body = {
            "query": "简单测试",
            "outline": simple_outline,
            "templateId": template_id,
            "author": "测试",
            "isCardNote": False,
            "search": False,
            "isFigure": False,
            "aiImage": "normal"
        }
        
        try:
            response = requests.post(url, json=body, headers=headers, timeout=20)
            result = response.json()
            
            if result.get('code') == 0:
                print(f"SUCCESS 模板 {template_id} 成功！")
                return result.get('data', {}).get('sid')
            else:
                print(f"FAILED 模板 {template_id} 失败: {result.get('desc')} (代码: {result.get('code')})")
        except Exception as e:
            print(f"ERROR 模板 {template_id} 异常: {e}")
    
    return None

def test_minimal_request():
    """测试最小化请求"""
    print("\n测试3：最小化参数请求")
    
    url = f"{BASE_URL}/createPptByOutline"
    headers = get_headers()
    
    # 最简单的大纲
    minimal_outline = {
        "title": "测试",
        "chapters": [
            {
                "chapterTitle": "内容",
                "contents": ["测试内容"]
            }
        ]
    }
    
    body = {
        "query": "测试",
        "outline": minimal_outline,
        "templateId": "202407179097C2D"
        # 只包含必需参数
    }
    
    try:
        response = requests.post(url, json=body, headers=headers, timeout=20)
        result = response.json()
        print(f"最小化请求结果: {json.dumps(result, indent=2, ensure_ascii=False)}")
        
        if result.get('code') == 0:
            print("SUCCESS 最小化请求成功！")
            return result.get('data', {}).get('sid')
        else:
            print(f"FAILED 最小化请求失败: {result.get('desc')}")
    except Exception as e:
        print(f"ERROR 最小化请求异常: {e}")
    
    return None

def main():
    print("深度排查99999系统异常错误")
    print("=" * 50)
    
    # 测试1：直接创建
    sid1 = test_direct_ppt_creation()
    
    # 测试2：不同模板
    sid2 = test_different_templates()
    
    # 测试3：最小化请求
    sid3 = test_minimal_request()
    
    if any([sid1, sid2, sid3]):
        print(f"\n找到可行方案！任务ID: {sid1 or sid2 or sid3}")
    else:
        print("\n所有测试都失败，可能的原因：")
        print("1. API账户配额已用完")
        print("2. 讯飞服务器临时故障")
        print("3. createPptByOutline接口存在问题")
        print("4. 需要联系讯飞技术支持")

if __name__ == "__main__":
    main()
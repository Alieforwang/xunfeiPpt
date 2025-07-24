#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
讯飞智文API问题诊断脚本
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

def test_1_get_template_list():
    """测试1：获取模板列表"""
    print("测试1：获取PPT模板列表")
    url = f"{BASE_URL}/template/list"
    headers = get_headers()
    
    params = {
        "payType": "not_free",
        "pageNum": 1,
        "pageSize": 5
    }
    
    try:
        response = requests.get(url, headers=headers, params=params, timeout=10)
        print(f"状态码: {response.status_code}")
        result = response.json()
        print(f"响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
        
        if result.get('code') == 0:
            print("SUCCESS 模板列表获取成功")
            templates = result.get('data', {}).get('list', [])
            if templates:
                print(f"可用模板数量: {len(templates)}")
                print("前3个模板:")
                for i, template in enumerate(templates[:3]):
                    print(f"  {i+1}. ID: {template.get('templateId')}, 名称: {template.get('templateName')}")
                return templates[0].get('templateId')  # 返回第一个模板ID
            else:
                print("WARNING 没有可用模板")
        else:
            print(f"ERROR 获取模板失败: {result.get('desc', 'Unknown error')}")
    except Exception as e:
        print(f"ERROR 请求异常: {e}")
    
    return None

def test_2_create_simple_outline():
    """测试2：创建简单大纲"""
    print("\n测试2：创建简单PPT大纲")
    url = f"{BASE_URL}/createOutline"
    timestamp = int(time.time())
    signature = get_signature(AIPPT_APP_ID, AIPPT_API_SECRET, timestamp)
    
    form_data = MultipartEncoder(fields={
        "query": "人工智能简介",
        "language": "cn",
        "search": "false"
    })
    
    headers = {
        "appId": AIPPT_APP_ID,
        "timestamp": str(timestamp),
        "signature": signature,
        "Content-Type": form_data.content_type
    }
    
    try:
        response = requests.post(url, data=form_data, headers=headers, timeout=15)
        print(f"状态码: {response.status_code}")
        result = response.json()
        print(f"响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
        
        if result.get('code') == 0:
            print("SUCCESS 大纲创建成功")
            return result.get('data', {}).get('outline', {})
        else:
            print(f"ERROR 大纲创建失败: {result.get('desc', 'Unknown error')}")
    except Exception as e:
        print(f"ERROR 请求异常: {e}")
    
    return None

def main():
    print("讯飞智文API诊断开始")
    print("=" * 50)
    
    # 测试1：获取模板
    template_id = test_1_get_template_list()
    
    # 测试2：创建大纲
    outline = test_2_create_simple_outline()
    
    print("\n诊断建议:")
    print("1. 如果模板列表获取失败 -> 检查API密钥和网络连接")
    print("2. 如果大纲创建失败 -> 可能是服务暂时不可用")
    print("3. 如果PPT创建返回99999 -> 通常是服务端问题，建议稍后重试")
    print("4. 检查讯飞开放平台控制台的API调用统计和余额")

if __name__ == "__main__":
    main()
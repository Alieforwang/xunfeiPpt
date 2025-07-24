#!/usr/bin/env python3
"""
测试修复后的SSE传输是否正确处理arguments字符串
"""
import asyncio
import aiohttp
import json

async def test_sse_with_string_arguments():
    """测试SSE服务器处理字符串形式的arguments参数"""
    base_url = "http://localhost:8001"
    
    # 测试数据 - arguments作为字符串（模拟问题场景）
    test_request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "create_outline",
            "arguments": '{"text": "人工智能发展历程", "language": "cn", "search": false}'  # 字符串形式
        }
    }
    
    print("测试SSE服务器修复...")
    print(f"发送请求: {json.dumps(test_request, indent=2, ensure_ascii=False)}")
    
    try:
        async with aiohttp.ClientSession() as session:
            # 发送POST请求到SSE服务器
            async with session.post(
                f"{base_url}/messages/",
                json=test_request,
                headers={"Content-Type": "application/json"}
            ) as resp:
                print(f"响应状态: {resp.status}")
                print(f"响应头: {dict(resp.headers)}")
                
                if resp.status == 200:
                    response_text = await resp.text()
                    print(f"✓ 服务器成功处理请求")
                    print(f"响应内容: {response_text}")
                else:
                    error_text = await resp.text()
                    print(f"✗ 服务器返回错误")
                    print(f"错误内容: {error_text}")
                    
    except Exception as e:
        print(f"测试失败: {e}")

async def test_sse_with_dict_arguments():
    """测试SSE服务器处理字典形式的arguments参数（正常情况）"""
    base_url = "http://localhost:8001"
    
    # 测试数据 - arguments作为字典（正常情况）
    test_request = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": "get_theme_list",
            "arguments": {  # 字典形式
                "pay_type": "free",
                "page_size": 5
            }
        }
    }
    
    print("\n测试正常的字典arguments...")
    print(f"发送请求: {json.dumps(test_request, indent=2, ensure_ascii=False)}")
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{base_url}/messages/",
                json=test_request,
                headers={"Content-Type": "application/json"}
            ) as resp:
                print(f"响应状态: {resp.status}")
                
                if resp.status == 200:
                    response_text = await resp.text()
                    print(f"✓ 服务器成功处理正常请求")
                    print(f"响应内容: {response_text}")
                else:
                    error_text = await resp.text()
                    print(f"✗ 服务器返回错误")
                    print(f"错误内容: {error_text}")
                    
    except Exception as e:
        print(f"测试失败: {e}")

if __name__ == "__main__":
    print("SSE服务器修复测试")
    print("请先确保SSE服务器已启动: python main.py sse")
    print("=" * 50)
    
    asyncio.run(test_sse_with_string_arguments())
    asyncio.run(test_sse_with_dict_arguments())
#!/usr/bin/env python3
"""
SSE服务器测试脚本
"""
import asyncio
import aiohttp
import json

async def test_sse_server():
    """测试SSE服务器功能"""
    base_url = "http://localhost:8001"
    
    try:
        async with aiohttp.ClientSession() as session:
            # 测试状态页面
            print("测试状态页面...")
            async with session.get(f"{base_url}/") as resp:
                print(f"状态页面响应: {resp.status}")
                if resp.status == 200:
                    print("✓ 状态页面正常")
                else:
                    print("✗ 状态页面异常")
            
            # 测试SSE连接
            print("\n测试SSE连接...")
            try:
                async with session.get(f"{base_url}/sse") as resp:
                    print(f"SSE响应状态: {resp.status}")
                    print(f"响应头: {dict(resp.headers)}")
                    
                    if resp.status == 200:
                        print("✓ SSE连接建立成功")
                        
                        # 读取前几个事件
                        count = 0
                        async for line in resp.content:
                            if count >= 5:  # 只读取前5个事件
                                break
                            decoded_line = line.decode('utf-8').strip()
                            if decoded_line:
                                print(f"SSE数据: {decoded_line}")
                                count += 1
                    else:
                        print("✗ SSE连接失败")
                        
            except Exception as e:
                print(f"SSE连接错误: {e}")
    
    except Exception as e:
        print(f"测试错误: {e}")

if __name__ == "__main__":
    print("SSE服务器测试")
    print("请先启动SSE服务器: python main.py sse")
    print("=" * 50)
    asyncio.run(test_sse_server())
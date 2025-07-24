#!/usr/bin/env python3
"""
测试HTTP Stream传输协议
"""
import asyncio
import aiohttp
import json

async def test_http_stream():
    """测试HTTP Stream服务器连接"""
    base_url = "http://localhost:8002"
    
    print("测试HTTP Stream传输协议")
    print("=" * 40)
    
    async with aiohttp.ClientSession() as session:
        # 1. 测试状态页面
        print("1. 测试状态页面...")
        try:
            async with session.get(f"{base_url}/") as resp:
                print(f"状态页面响应: {resp.status}")
                if resp.status == 200:
                    print("✓ 状态页面正常")
                else:
                    print("✗ 状态页面异常")
        except Exception as e:
            print(f"✗ 状态页面错误: {e}")
        
        # 2. 测试工具列表请求
        print("\n2. 测试工具列表请求...")
        try:
            request_data = {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/list"
            }
            
            async with session.post(
                f"{base_url}/mcp",
                json=request_data,
                headers={"Content-Type": "application/json"}
            ) as resp:
                print(f"POST响应状态: {resp.status}")
                session_id = resp.headers.get("x-session-id")
                print(f"会话ID: {session_id}")
                
                if resp.status == 200:
                    result = await resp.json()
                    print(f"POST响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
                    
                    if session_id:
                        # 3. 测试SSE响应流
                        print("\n3. 测试SSE响应流...")
                        try:
                            async with session.get(
                                f"{base_url}/mcp",
                                headers={"x-session-id": session_id}
                            ) as sse_resp:
                                print(f"SSE响应状态: {sse_resp.status}")
                                
                                if sse_resp.status == 200:
                                    print("✓ SSE连接建立成功")
                                    
                                    # 读取前几个事件
                                    count = 0
                                    async for line in sse_resp.content:
                                        if count >= 5:  # 只读取前5个事件
                                            break
                                        decoded_line = line.decode('utf-8').strip()
                                        if decoded_line and decoded_line.startswith('data:'):
                                            print(f"SSE数据: {decoded_line}")
                                            count += 1
                                else:
                                    print("✗ SSE连接失败")
                                    
                        except Exception as e:
                            print(f"✗ SSE连接错误: {e}")
                    
        except Exception as e:
            print(f"✗ 工具列表请求错误: {e}")

async def test_react_workflow():
    """测试ReACT工作流"""
    base_url = "http://localhost:8002"
    
    print("\n" + "=" * 40)
    print("测试ReACT工作流")
    print("=" * 40)
    
    async with aiohttp.ClientSession() as session:
        # 测试ReACT工作流
        request_data = {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": "create_full_ppt_workflow",
                "arguments": {
                    "topic": "人工智能在教育中的应用",
                    "requirements": "面向大学生，需要包含实际案例",
                    "style_preference": "简约",
                    "industry": "教育培训",
                    "author": "AI助手",
                    "enable_figures": True,
                    "enable_notes": True,
                    "enable_search": False
                }
            }
        }
        
        try:
            async with session.post(
                f"{base_url}/mcp",
                json=request_data,
                headers={"Content-Type": "application/json"}
            ) as resp:
                print(f"ReACT工作流请求状态: {resp.status}")
                session_id = resp.headers.get("x-session-id")
                
                if resp.status == 200 and session_id:
                    # 获取响应流
                    async with session.get(
                        f"{base_url}/mcp",
                        headers={"x-session-id": session_id}
                    ) as sse_resp:
                        if sse_resp.status == 200:
                            print("✓ ReACT工作流开始执行...")
                            
                            async for line in sse_resp.content:
                                decoded_line = line.decode('utf-8').strip()
                                if decoded_line and decoded_line.startswith('data:'):
                                    try:
                                        # 解析SSE数据
                                        data_content = decoded_line[5:]  # 去掉 "data:" 前缀
                                        if data_content.strip():
                                            event_data = json.loads(data_content)
                                            
                                            # 如果是heartbeat，跳过
                                            if event_data.get('type') == 'heartbeat':
                                                continue
                                            
                                            # 打印工作流结果
                                            if 'result' in event_data:
                                                result = event_data['result']
                                                if 'content' in result:
                                                    for content in result['content']:
                                                        if content.get('type') == 'text':
                                                            workflow_result = json.loads(content['text'])
                                                            print("\n🎯 ReACT工作流执行结果:")
                                                            print(f"成功: {workflow_result.get('success')}")
                                                            
                                                            if workflow_result.get('success'):
                                                                print(f"任务ID: {workflow_result.get('task_id')}")
                                                                print(f"PPT标题: {workflow_result.get('ppt_info', {}).get('title')}")
                                                                
                                                                # 显示工作流日志
                                                                workflow_log = workflow_result.get('workflow_log', [])
                                                                print(f"\n📋 工作流执行步骤 ({len(workflow_log)} 步):")
                                                                for i, step in enumerate(workflow_log, 1):
                                                                    stage = step.get('stage', '')
                                                                    action = step.get('action', '')
                                                                    print(f"  {i}. [{stage}] {action}")
                                                                
                                                                # 显示下一步操作
                                                                next_steps = workflow_result.get('next_steps', [])
                                                                if next_steps:
                                                                    print(f"\n📌 下一步操作:")
                                                                    for step in next_steps:
                                                                        print(f"  • {step}")
                                                            else:
                                                                print(f"错误: {workflow_result.get('error')}")
                                                            
                                                            return  # 工作流完成，退出循环
                                    except json.JSONDecodeError:
                                        pass  # 忽略无法解析的数据
                        else:
                            print("✗ ReACT工作流SSE连接失败")
        except Exception as e:
            print(f"✗ ReACT工作流测试错误: {e}")

async def main():
    print("HTTP Stream + ReACT工作流测试")
    print("请先启动HTTP Stream服务器: python main.py http-stream")
    print("服务器地址: http://localhost:8002")
    
    await test_http_stream()
    await test_react_workflow()

if __name__ == "__main__":
    asyncio.run(main())
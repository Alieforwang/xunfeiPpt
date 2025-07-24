#!/usr/bin/env python3
"""
Proper SSE client implementation for testing MCP Server
"""
import asyncio
import json
import uuid
from urllib.parse import urlencode

try:
    import aiohttp
    AIOHTTP_AVAILABLE = True
except ImportError:
    AIOHTTP_AVAILABLE = False

async def test_sse_with_correct_format():
    """Test SSE server with correct message format"""
    if not AIOHTTP_AVAILABLE:
        print("aiohttp not available, install with: pip install aiohttp")
        return
        
    base_url = "http://localhost:8001"
    session_id = str(uuid.uuid4())
    
    print(f"Testing SSE with session ID: {session_id}")
    print("="*60)
    
    async with aiohttp.ClientSession() as session:
        # First establish SSE connection
        print("1. Establishing SSE connection...")
        
        sse_url = f"{base_url}/sse"
        sse_task = None
        
        try:
            # Start SSE connection in background
            async def sse_listener():
                async with session.get(sse_url) as resp:
                    print(f"SSE Status: {resp.status}")
                    if resp.status == 200:
                        print("✓ SSE connection established")
                        
                        # Read SSE events
                        async for line in resp.content:
                            decoded = line.decode('utf-8').strip()
                            if decoded:
                                print(f"SSE Event: {decoded}")
                            
                    else:
                        print(f"✗ Failed to establish SSE: {resp.status}")
            
            sse_task = asyncio.create_task(sse_listener())
            
            # Give SSE connection time to establish
            await asyncio.sleep(1)
            
            # Test correct message formats
            test_messages = [
                {
                    "name": "List Tools",
                    "message": {
                        "jsonrpc": "2.0",
                        "id": f"test-{uuid.uuid4()}",
                        "method": "tools/list"
                    }
                },
                {
                    "name": "Call Tool with Dict Arguments (CORRECT)",
                    "message": {
                        "jsonrpc": "2.0",
                        "id": f"test-{uuid.uuid4()}",
                        "method": "tools/call",
                        "params": {
                            "name": "get_theme_list",
                            "arguments": {
                                "pay_type": "not_free",
                                "page_size": 5
                            }
                        }
                    }
                },
                {
                    "name": "Call Tool with String Arguments (WRONG)",
                    "message": {
                        "jsonrpc": "2.0",
                        "id": f"test-{uuid.uuid4()}",
                        "method": "tools/call",
                        "params": {
                            "name": "get_theme_list",
                            "arguments": '{"pay_type": "not_free", "page_size": 5}'
                        }
                    }
                }
            ]
            
            for i, test_case in enumerate(test_messages, 1):
                print(f"\n{i}. Testing: {test_case['name']}")
                print("-" * 40)
                
                # Send message via POST with session_id
                post_url = f"{base_url}/messages/?{urlencode({'session_id': session_id})}"
                
                try:
                    async with session.post(
                        post_url,
                        json=test_case['message'],
                        headers={'Content-Type': 'application/json'}
                    ) as resp:
                        print(f"POST Status: {resp.status}")
                        response_text = await resp.text()
                        print(f"Response: {response_text}")
                        
                        if resp.status == 200:
                            print("✓ Message sent successfully")
                        else:
                            print("✗ Message failed")
                            
                except Exception as e:
                    print(f"POST Error: {e}")
                    
                # Wait a bit between messages
                await asyncio.sleep(1)
            
            # Wait for any remaining SSE events
            await asyncio.sleep(2)
            
        except Exception as e:
            print(f"Test error: {e}")
        finally:
            if sse_task:
                sse_task.cancel()
                try:
                    await sse_task
                except asyncio.CancelledError:
                    pass

def create_proper_sse_message_examples():
    """Show examples of proper SSE message formats"""
    print("Proper SSE Message Format Examples")
    print("="*50)
    
    examples = [
        {
            "name": "List Tools Request",
            "message": {
                "jsonrpc": "2.0",
                "id": "req-1",
                "method": "tools/list"
            }
        },
        {
            "name": "Call Tool Request (CORRECT FORMAT)",
            "message": {
                "jsonrpc": "2.0", 
                "id": "req-2",
                "method": "tools/call",
                "params": {
                    "name": "create_ppt_task",
                    "arguments": {  # ← This must be a dict/object, NOT a string
                        "text": "关于人工智能的PPT",
                        "template_id": "template123",
                        "author": "Test User",
                        "is_card_note": True,
                        "search": False,
                        "is_figure": True,
                        "ai_image": "normal"
                    }
                }
            }
        },
        {
            "name": "Call Tool Request (WRONG FORMAT - String Arguments)",
            "message": {
                "jsonrpc": "2.0",
                "id": "req-3", 
                "method": "tools/call",
                "params": {
                    "name": "create_ppt_task",
                    "arguments": '{"text": "关于人工智能的PPT", "template_id": "template123"}'  # ← This is WRONG
                }
            }
        }
    ]
    
    for example in examples:
        print(f"\n{example['name']}:")
        print(json.dumps(example['message'], indent=2, ensure_ascii=False))
        
        if "WRONG" in example['name']:
            print("❌ This format will cause validation errors!")
        elif "CORRECT" in example['name']:
            print("✅ This format will work correctly!")

if __name__ == "__main__":
    print("MCP SSE Transport Test Client")
    print("="*60)
    
    # Show proper format examples
    create_proper_sse_message_examples()
    
    if AIOHTTP_AVAILABLE:
        print("\n" + "="*60)
        print("Starting SSE server tests...")
        print("Make sure SSE server is running: python main.py sse")
        
        try:
            user_input = input("Press Enter to continue with server tests (or Ctrl+C to exit)...")
            asyncio.run(test_sse_with_correct_format())
        except KeyboardInterrupt:
            print("\nTest cancelled by user")
    else:
        print("\nTo run server tests, install aiohttp: pip install aiohttp")
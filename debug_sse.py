#!/usr/bin/env python3
"""
Debug script to test SSE transport and message format issues
"""
import asyncio
import aiohttp
import json

async def test_sse_message_format():
    """Test different message formats to identify the parsing issue"""
    base_url = "http://localhost:8001"
    
    # Test cases with different argument formats
    test_cases = [
        {
            "name": "String arguments (current issue)",
            "message": {
                "jsonrpc": "2.0",
                "id": "test-1",
                "method": "tools/call",
                "params": {
                    "name": "create_ppt_task",
                    "arguments": '{\n    "text": "关于人工智能的PPT",\n    "template_id": "123",\n    "ai_image": "normal"\n  }'
                }
            }
        },
        {
            "name": "Object arguments (correct format)",
            "message": {
                "jsonrpc": "2.0",
                "id": "test-2", 
                "method": "tools/call",
                "params": {
                    "name": "create_ppt_task",
                    "arguments": {
                        "text": "关于人工智能的PPT",
                        "template_id": "123",
                        "ai_image": "normal"
                    }
                }
            }
        },
        {
            "name": "List tools request",
            "message": {
                "jsonrpc": "2.0",
                "id": "test-3",
                "method": "tools/list"
            }
        }
    ]
    
    try:
        async with aiohttp.ClientSession() as session:
            for test_case in test_cases:
                print(f"\n{'='*50}")
                print(f"Testing: {test_case['name']}")
                print(f"Message: {json.dumps(test_case['message'], indent=2)}")
                
                try:
                    # Send POST message to SSE endpoint
                    async with session.post(
                        f"{base_url}/messages/",
                        json=test_case['message'],
                        headers={'Content-Type': 'application/json'}
                    ) as resp:
                        print(f"Status: {resp.status}")
                        response_text = await resp.text()
                        print(f"Response: {response_text}")
                        
                        if resp.status == 200:
                            print("✓ Message accepted")
                        else:
                            print("✗ Message rejected")
                            
                except Exception as e:
                    print(f"Request error: {e}")
                    
    except Exception as e:
        print(f"Test error: {e}")

async def test_raw_message_parsing():
    """Test raw message parsing to understand the format requirements"""
    from mcp.types import CallToolRequest, CallToolRequestParams
    import json
    
    print("\n" + "="*50)
    print("Testing MCP message parsing directly")
    
    # Test with string arguments (the problematic case)
    try:
        raw_message = {
            "jsonrpc": "2.0",
            "id": "test-1",
            "method": "tools/call",
            "params": {
                "name": "create_ppt_task",
                "arguments": '{\n    "text": "关于人工智能的PPT",\n    "template_id": "123",\n    "ai_image": "normal"\n  }'
            }
        }
        
        print("Attempting to parse message with string arguments:")
        print(json.dumps(raw_message, indent=2))
        
        # Try to create CallToolRequest directly
        request = CallToolRequest(**raw_message)
        print("✓ Successfully parsed as CallToolRequest")
        print(f"Arguments type: {type(request.params.arguments)}")
        print(f"Arguments value: {request.params.arguments}")
        
    except Exception as e:
        print(f"✗ Failed to parse: {e}")
    
    # Test with dict arguments (the correct case)  
    try:
        raw_message = {
            "jsonrpc": "2.0",
            "id": "test-2",
            "method": "tools/call",
            "params": {
                "name": "create_ppt_task",
                "arguments": {
                    "text": "关于人工智能的PPT",
                    "template_id": "123",
                    "ai_image": "normal"
                }
            }
        }
        
        print("\nAttempting to parse message with dict arguments:")
        print(json.dumps(raw_message, indent=2))
        
        # Try to create CallToolRequest directly
        request = CallToolRequest(**raw_message)
        print("✓ Successfully parsed as CallToolRequest")
        print(f"Arguments type: {type(request.params.arguments)}")
        print(f"Arguments value: {request.params.arguments}")
        
    except Exception as e:
        print(f"✗ Failed to parse: {e}")

if __name__ == "__main__":
    print("MCP SSE Message Format Debug Tool")
    print("=" * 50)
    
    # First test message parsing without server
    asyncio.run(test_raw_message_parsing())
    
    print("\n" + "="*60)
    print("Starting server tests...")
    print("Make sure SSE server is running: python main.py sse")
    input("Press Enter to continue with server tests...")
    
    # Then test with server
    asyncio.run(test_sse_message_format())
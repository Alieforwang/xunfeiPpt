#!/usr/bin/env python3
"""
测试API密钥池功能
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)) + '/..')

from main import AIPPTClient, API_KEY_POOL
import asyncio
import json

def test_key_pool_basic():
    """测试基本密钥池功能"""
    print("🧪 测试1：基本密钥池功能")
    print("=" * 40)
    
    # 创建客户端
    client = AIPPTClient()
    
    # 获取统计信息
    stats = client.get_pool_stats()
    print(f"✅ 密钥池统计:\n{json.dumps(stats, indent=2, ensure_ascii=False)}")
    
    return client

def test_template_list_with_pool(client):
    """测试使用密钥池获取模板列表"""
    print("\n🧪 测试2：使用密钥池获取模板列表")
    print("=" * 40)
    
    try:
        result = client.get_theme_list(page_size=3)
        print(f"✅ 模板列表请求成功")
        print(f"响应代码: {result.get('code')}")
        print(f"返回模板数: {len(result.get('data', {}).get('list', []))}")
        
        # 显示更新后的统计
        stats = client.get_pool_stats()
        print(f"\n📊 请求后统计:")
        for i, key_info in enumerate(stats['key_info']):
            print(f"  密钥{i+1}: {key_info['name']} - 并发:{key_info['concurrent']}/{key_info['max_concurrent']}")
        
        return True
    except Exception as e:
        print(f"❌ 模板列表请求失败: {e}")
        return False

def test_concurrent_requests(client):
    """测试并发请求和密钥轮换"""
    print("\n🧪 测试3：并发请求测试")
    print("=" * 40)
    
    import threading
    import time
    
    results = []
    errors = []
    
    def make_request(thread_id):
        try:
            print(f"线程{thread_id}: 开始请求...")
            result = client.get_theme_list(page_size=2)
            results.append((thread_id, result.get('code')))
            print(f"线程{thread_id}: 请求完成，代码:{result.get('code')}")
        except Exception as e:
            errors.append((thread_id, str(e)))
            print(f"线程{thread_id}: 请求失败:{e}")
    
    # 创建多个线程同时请求
    threads = []
    for i in range(5):
        thread = threading.Thread(target=make_request, args=(i+1,))
        threads.append(thread)
        thread.start()
        time.sleep(0.1)  # 稍微错开启动时间
    
    # 等待所有线程完成
    for thread in threads:
        thread.join()
    
    print(f"\n📊 并发测试结果:")
    print(f"  成功请求: {len(results)}")
    print(f"  失败请求: {len(errors)}")
    
    # 显示最终统计
    stats = client.get_pool_stats()
    print(f"\n📊 最终统计:")
    for stat in stats['usage_stats'].values():
        print(f"  总请求: {stat['requests']}, 错误: {stat['errors']}, 错误率: {stat['errors']/max(stat['requests'], 1)*100:.1f}%")

def test_with_multiple_keys():
    """测试多密钥配置"""
    print("\n🧪 测试4：多密钥配置测试")
    print("=" * 40)
    
    # 创建多密钥配置（模拟）
    multi_key_pool = [
        {
            "app_id": "2dc9dc12",
            "api_secret": "YWVmZjQ0NTI4MjkxMTEzMTA5MWZiY2M4",
            "name": "主密钥",
            "max_concurrent": 3,
            "enabled": True
        },
        # 添加模拟的第二个密钥（相同配置用于测试）
        {
            "app_id": "2dc9dc12", 
            "api_secret": "YWVmZjQ0NTI4MjkxMTEzMTA5MWZiY2M4",
            "name": "备用密钥1",
            "max_concurrent": 2,
            "enabled": True
        }
    ]
    
    client = AIPPTClient(key_pool=multi_key_pool)
    stats = client.get_pool_stats()
    
    print(f"✅ 多密钥配置:")
    print(f"  总密钥数: {stats['total_keys']}")
    print(f"  活跃密钥数: {stats['active_keys']}")
    
    for key_info in stats['key_info']:
        print(f"  - {key_info['name']}: 最大并发{key_info['max_concurrent']}")

def test_error_handling():
    """测试错误处理和重试机制"""
    print("\n🧪 测试5：错误处理测试")
    print("=" * 40)
    
    # 创建一个包含无效密钥的配置
    error_key_pool = [
        {
            "app_id": "invalid_id",
            "api_secret": "invalid_secret", 
            "name": "无效密钥",
            "max_concurrent": 1,
            "enabled": True
        },
        {
            "app_id": "2dc9dc12",
            "api_secret": "YWVmZjQ0NTI4MjkxMTEzMTA5MWZiY2M4",
            "name": "有效密钥",
            "max_concurrent": 5,
            "enabled": True
        }
    ]
    
    client = AIPPTClient(key_pool=error_key_pool)
    
    try:
        print("尝试请求（应该会重试并成功）...")
        result = client.get_theme_list(page_size=1)
        print(f"✅ 请求最终成功，代码: {result.get('code')}")
        
        # 显示统计，应该能看到错误统计
        stats = client.get_pool_stats()
        print(f"\n📊 错误统计:")
        for i, (key_index, stat) in enumerate(stats['usage_stats'].items()):
            key_name = stats['key_info'][i]['name']
            error_rate = stat['errors'] / max(stat['requests'], 1) * 100
            print(f"  {key_name}: 请求{stat['requests']}次, 错误{stat['errors']}次, 错误率{error_rate:.1f}%")
            
    except Exception as e:
        print(f"❌ 请求失败: {e}")

def main():
    """主测试函数"""
    print("🚀 API密钥池功能测试")
    print("=" * 50)
    
    try:
        # 基本功能测试
        client = test_key_pool_basic()
        
        # 模板列表测试
        if test_template_list_with_pool(client):
            # 并发测试
            test_concurrent_requests(client)
        
        # 多密钥配置测试
        test_with_multiple_keys()
        
        # 错误处理测试
        test_error_handling()
        
        print("\n🎉 密钥池测试完成!")
        print("\n💡 密钥池配置说明:")
        print("1. 在main.py中的API_KEY_POOL列表添加更多密钥")
        print("2. 每个密钥可以设置max_concurrent限制并发数")
        print("3. 可以通过enabled字段启用/禁用密钥")
        print("4. 系统会自动选择最优密钥并处理故障转移")
        
    except Exception as e:
        print(f"❌ 测试过程中出现异常: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
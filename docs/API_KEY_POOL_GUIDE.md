# API密钥池配置指南

为了提高API调用的并发能力和稳定性，本项目支持配置多个讯飞智文API密钥形成密钥池。

## 🎯 功能特性

### 🔄 智能轮换
- **最优选择**：根据错误率和并发负载自动选择最佳密钥
- **负载均衡**：避免单个密钥过载
- **故障转移**：密钥达到限制时自动切换

### 📊 并发控制
- **独立限制**：每个密钥可设置不同的并发限制
- **实时监控**：跟踪每个密钥的使用情况
- **动态调整**：根据实际情况优化分配

### 🛡️ 容错机制
- **自动重试**：失败时自动尝试其他密钥
- **错误统计**：记录每个密钥的成功率
- **智能降级**：优先使用成功率高的密钥

## ⚙️ 配置方法

### 1. 基础配置

在 `main.py` 中找到 `API_KEY_POOL` 配置：

```python
API_KEY_POOL = [
    {
        "app_id": "2dc9dc12",
        "api_secret": "YWVmZjQ0NTI4MjkxMTEzMTA5MWZiY2M4",
        "name": "主密钥",
        "max_concurrent": 10,  # 最大并发数
        "enabled": True
    },
    # 添加更多密钥
    {
        "app_id": "your_app_id_2",
        "api_secret": "your_api_secret_2", 
        "name": "备用密钥1",
        "max_concurrent": 5,
        "enabled": True
    },
    {
        "app_id": "your_app_id_3",
        "api_secret": "your_api_secret_3",
        "name": "备用密钥2", 
        "max_concurrent": 8,
        "enabled": True
    }
]
```

### 2. 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `app_id` | string | ✅ | 讯飞智文应用ID |
| `api_secret` | string | ✅ | 讯飞智文API密钥 |
| `name` | string | ⭐ | 密钥名称，便于管理和调试 |
| `max_concurrent` | int | ⭐ | 最大并发请求数，默认10 |
| `enabled` | bool | ⭐ | 是否启用此密钥，默认true |

### 3. 高级配置示例

```python
# 针对不同场景的密钥配置
API_KEY_POOL = [
    {
        "app_id": "main_key",
        "api_secret": "main_secret",
        "name": "高性能主密钥", 
        "max_concurrent": 20,  # 高并发
        "enabled": True
    },
    {
        "app_id": "backup_key1", 
        "api_secret": "backup_secret1",
        "name": "标准备份密钥",
        "max_concurrent": 10,  # 中等并发
        "enabled": True
    },
    {
        "app_id": "test_key",
        "api_secret": "test_secret", 
        "name": "测试专用密钥",
        "max_concurrent": 3,   # 低并发，测试用
        "enabled": False       # 生产环境禁用
    }
]
```

## 📊 监控和调试

### 1. 使用MCP工具监控

```bash
# 通过MCP调用查看密钥池状态
curl -X POST http://localhost:8002/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "get_api_pool_stats",
      "arguments": {}
    }
  }'
```

### 2. 状态信息说明

返回的统计信息包含：

```json
{
  "total_keys": 3,           // 总密钥数
  "active_keys": 2,          // 活跃密钥数
  "usage_stats": {
    "0": {
      "requests": 25,        // 总请求数
      "errors": 1,           // 错误次数
      "concurrent": 3        // 当前并发数
    }
  },
  "key_info": [
    {
      "name": "主密钥",
      "concurrent": 3,       // 当前并发
      "max_concurrent": 10   // 最大并发
    }
  ]
}
```

### 3. 运行测试

```bash
# 运行密钥池功能测试
cd tests
python test_api_pool.py
```

## 🚀 性能优化建议

### 1. 并发配置

- **主密钥**：设置较高的 `max_concurrent`（15-20）
- **备用密钥**：设置中等的 `max_concurrent`（5-10）
- **测试密钥**：设置较低的 `max_concurrent`（1-3）

### 2. 密钥分层

```python
# 推荐的分层配置
API_KEY_POOL = [
    # 第一层：高性能密钥
    {"app_id": "premium1", "max_concurrent": 20, "name": "高级密钥1"},
    {"app_id": "premium2", "max_concurrent": 20, "name": "高级密钥2"},
    
    # 第二层：标准密钥
    {"app_id": "standard1", "max_concurrent": 10, "name": "标准密钥1"},
    {"app_id": "standard2", "max_concurrent": 10, "name": "标准密钥2"},
    
    # 第三层：备用密钥
    {"app_id": "backup1", "max_concurrent": 5, "name": "备用密钥1"},
]
```

### 3. 监控指标

关注以下关键指标：
- **错误率**：应保持在5%以下
- **并发利用率**：避免长期达到100%
- **响应时间**：监控API响应延迟

## 🔧 故障排除

### 1. 常见问题

**密钥无效**
```
错误: 签名验证失败
解决: 检查app_id和api_secret是否正确
```

**并发超限**
```
错误: 所有密钥都达到并发限制
解决: 增加max_concurrent或添加更多密钥
```

**网络错误**
```
错误: 连接超时
解决: 检查网络连接，考虑增加重试次数
```

### 2. 调试技巧

**启用详细日志**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**单独测试密钥**
```python
# 临时使用单个密钥测试
test_pool = [{"app_id": "test_id", "api_secret": "test_secret", "enabled": True}]
client = AIPPTClient(key_pool=test_pool)
```

**监控并发情况**
```python
# 定期检查状态
stats = client.get_pool_stats()
for key in stats['key_info']:
    print(f"{key['name']}: {key['concurrent']}/{key['max_concurrent']}")
```

## 📋 最佳实践

### 1. 密钥管理
- ✅ 使用描述性的密钥名称
- ✅ 定期检查密钥有效性
- ✅ 为不同环境配置不同密钥池
- ❌ 不要在生产环境使用测试密钥

### 2. 并发设置
- ✅ 根据实际需求设置并发限制
- ✅ 为高优先级任务预留容量
- ✅ 监控并发使用情况
- ❌ 不要设置过高的并发导致API限制

### 3. 容错设计
- ✅ 配置多个备用密钥
- ✅ 设置适当的重试次数
- ✅ 监控错误率和成功率
- ❌ 不要依赖单个密钥

## 🔄 从单密钥迁移

### 1. 渐进式迁移

```python
# 第一步：保持原有配置
API_KEY_POOL = [
    {
        "app_id": "original_id",
        "api_secret": "original_secret", 
        "name": "原始密钥",
        "max_concurrent": 10,
        "enabled": True
    }
]

# 第二步：添加备用密钥
API_KEY_POOL.append({
    "app_id": "backup_id",
    "api_secret": "backup_secret",
    "name": "备用密钥",
    "max_concurrent": 5,
    "enabled": True
})

# 第三步：优化配置
# 根据监控数据调整并发限制
```

### 2. 兼容性保证

- 现有代码无需修改
- API调用接口保持不变
- 向后完全兼容
- 可随时回退到单密钥模式

通过合理的密钥池配置，可以显著提高PPT生成服务的并发能力和稳定性！
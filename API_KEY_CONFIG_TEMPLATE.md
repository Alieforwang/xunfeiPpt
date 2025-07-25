# 讯飞智文API密钥配置模板

本文件提供API密钥配置说明，请根据需要配置您的讯飞智文API密钥。

## 📋 配置方法

### 方法1：直接修改main.py（推荐）

在 `main.py` 文件中找到 `API_KEY_POOL` 配置节，将占位符替换为您的真实密钥：

```python
API_KEY_POOL = [
    {
        "app_id": "your_app_id_here",        # 替换为您的APP ID
        "api_secret": "your_api_secret_here", # 替换为您的API Secret
        "name": "主密钥",
        "max_concurrent": 10,  # 最大并发数
        "enabled": True
    },
    # 可以添加更多密钥实现负载均衡
    {
        "app_id": "your_app_id_2",
        "api_secret": "your_api_secret_2",
        "name": "备用密钥1",
        "max_concurrent": 5,
        "enabled": True
    }
]
```

### 方法2：使用环境变量（推荐生产环境）

创建 `.env` 文件（已在.gitignore中），设置环境变量：

```bash
# .env 文件示例
AIPPT_APP_ID_1=your_app_id_here
AIPPT_API_SECRET_1=your_api_secret_here
AIPPT_APP_ID_2=your_app_id_2
AIPPT_API_SECRET_2=your_api_secret_2
```

然后修改main.py读取环境变量：

```python
import os
from dotenv import load_dotenv

load_dotenv()

API_KEY_POOL = [
    {
        "app_id": os.getenv("AIPPT_APP_ID_1", "your_app_id_here"),
        "api_secret": os.getenv("AIPPT_API_SECRET_1", "your_api_secret_here"),
        "name": "主密钥",
        "max_concurrent": 10,
        "enabled": True
    }
]
```

## 🔑 获取API密钥

1. 访问 [讯飞智文开放平台](https://zwapi.xfyun.cn/)
2. 注册并登录账号
3. 创建应用获取 APP ID 和 API Secret
4. 将密钥信息填入配置中

## 🛡️ 安全注意事项

1. **不要将真实密钥提交到代码仓库**
2. 使用环境变量或配置文件存储敏感信息
3. 确保 `.env` 文件已添加到 `.gitignore`
4. 定期轮换API密钥
5. 设置合理的并发限制

## 🔧 多密钥配置优势

- **负载均衡**: 自动分配请求到不同密钥
- **故障转移**: 某个密钥失效时自动切换
- **并发控制**: 每个密钥独立的并发限制
- **统计监控**: 实时监控各密钥使用情况

## 📊 监控密钥状态

使用 `get_api_pool_stats` 工具查看密钥池状态：

```bash
curl -X POST http://localhost:60/mcp \
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

---

**⚠️ 重要提醒**: 请妥善保管您的API密钥，不要在公开场合分享或提交到代码仓库。
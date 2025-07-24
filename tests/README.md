# 测试说明

本目录包含项目的所有测试文件，按功能分类：

## 🧪 主要测试

### HTTP Stream 测试
- [`test_http_stream.py`](./test_http_stream.py) - HTTP Stream传输协议和ReACT工作流测试

### 基础功能测试
- [`test_simple_ppt.py`](./test_simple_ppt.py) - 基础PPT生成功能测试
- [`test_fixed_tool.py`](./test_fixed_tool.py) - 修复后的工具功能测试

### SSE 相关测试
- [`test_sse.py`](./test_sse.py) - SSE传输协议测试
- [`test_sse_fix.py`](./test_sse_fix.py) - SSE修复功能测试
- [`proper_sse_client.py`](./proper_sse_client.py) - 正确的SSE客户端实现示例

## 🔍 调试工具

### API 调试
- [`diagnose_api.py`](./diagnose_api.py) - API诊断工具，检查讯飞智文API状态
- [`debug_99999.py`](./debug_99999.py) - 99999错误调试工具
- [`debug_sse.py`](./debug_sse.py) - SSE传输调试工具

### 问题分析
- [`sse_issue_analysis.py`](./sse_issue_analysis.py) - SSE参数问题分析脚本

## 🚀 快速运行

### 运行主要测试
```bash
# 测试HTTP Stream + ReACT工作流（推荐）
cd tests
python test_http_stream.py

# 测试基础PPT功能
python test_simple_ppt.py

# 诊断API状态
python diagnose_api.py
```

### 运行SSE测试（兼容性）
```bash
# 测试SSE传输
python test_sse.py

# 测试SSE修复
python test_sse_fix.py
```

### 调试99999错误
```bash
# 调试PPT生成99999错误
python debug_99999.py
```

## 📋 测试要求

### 环境准备
1. 确保服务器正在运行：
   ```bash
   # HTTP Stream模式（推荐）
   python ../main.py http-stream
   
   # 或其他模式
   python ../main.py sse
   python ../main.py http
   ```

2. 安装依赖：
   ```bash
   cd ..
   uv sync
   ```

### 测试覆盖
- ✅ 所有传输协议（stdio, http, sse, http-stream）
- ✅ ReACT工作流完整流程
- ✅ 7个PPT生成工具
- ✅ API错误处理和重试
- ✅ 并发连接测试
- ✅ 兼容性验证

## 📖 相关文档

测试相关的详细文档请参考：
- [使用说明](../docs/USAGE.md) - 详细使用指南
- [HTTP Stream指南](../docs/HTTP_STREAM_GUIDE.md) - HTTP Stream传输详解
- [SSE问题分析](../docs/SSE_ISSUE_ANALYSIS.md) - SSE传输问题修复报告

## 🔧 自定义测试

### 添加新测试
1. 创建新的测试文件：`test_your_feature.py`
2. 参考现有测试结构
3. 确保包含错误处理
4. 更新本README

### 测试模板
```python
#!/usr/bin/env python3
"""
测试模板
"""
import asyncio
import aiohttp
import json

async def test_your_feature():
    """测试你的功能"""
    base_url = "http://localhost:8002"  # 或其他端口
    
    async with aiohttp.ClientSession() as session:
        # 你的测试代码
        pass

if __name__ == "__main__":
    asyncio.run(test_your_feature())
```

## ⚠️ 注意事项

1. **端口冲突**：确保测试端口未被占用
2. **API密钥**：已内置，无需配置
3. **网络连接**：部分测试需要访问讯飞API
4. **并发限制**：避免同时运行多个API密集型测试
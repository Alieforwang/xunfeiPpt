# 项目文档

本目录包含项目的所有技术文档，为开发者和用户提供详细指导。

## 📚 文档目录

### 🚀 使用指南
- [`USAGE.md`](./USAGE.md) - **完整使用说明** 
  - 功能特性详解
  - 4种传输协议对比
  - ReACT工作流使用
  - 集成配置示例
  - 故障排除指南

### 🌐 HTTP Stream 传输
- [`HTTP_STREAM_GUIDE.md`](./HTTP_STREAM_GUIDE.md) - **HTTP Stream传输指南**
  - MCP 2025-03-26规范实现
  - 单端点架构详解
  - 会话管理和断线重连
  - 客户端集成示例
  - 迁移指南

- [`HTTP_STREAM_IMPLEMENTATION_REPORT.md`](./HTTP_STREAM_IMPLEMENTATION_REPORT.md) - **实现报告**
  - 技术实现总结
  - 协议对比分析
  - 性能优势说明
  - 集成建议

### 🔧 问题修复
- [`SSE_ISSUE_ANALYSIS.md`](./SSE_ISSUE_ANALYSIS.md) - **SSE问题分析**
  - string arguments问题诊断
  - 修复方案实现
  - 客户端兼容性指南
  - 测试验证报告

## 🎯 快速导航

### 新用户入门
1. [使用说明](./USAGE.md#快速开始) - 了解基本功能
2. [协议选择](./USAGE.md#协议对比) - 选择合适的传输协议
3. [集成配置](./USAGE.md#集成指南) - 配置你的应用

### ReACT工作流
1. [ReACT模式详解](./USAGE.md#react工作流详解) - 理解工作流原理
2. [使用示例](./USAGE.md#react工作流使用示例) - 实际调用示例
3. [测试工具](../tests/README.md#测试http-stream--react工作流推荐) - 验证功能

### HTTP Stream集成
1. [HTTP Stream指南](./HTTP_STREAM_GUIDE.md#使用方法) - 启动和配置
2. [客户端连接](./HTTP_STREAM_GUIDE.md#客户端连接) - 实现客户端
3. [迁移指南](./HTTP_STREAM_GUIDE.md#迁移指南) - 从SSE迁移

### 问题解决
1. [常见问题](./USAGE.md#注意事项) - 基础问题排查
2. [SSE问题](./SSE_ISSUE_ANALYSIS.md#solutions-implemented) - SSE相关问题
3. [故障排除](./HTTP_STREAM_GUIDE.md#故障排除) - HTTP Stream问题

## 🔗 文档关联

### 按功能分类

#### 协议支持
- **stdio** → [USAGE.md - stdio模式](./USAGE.md#stdio模式默认)
- **http** → [USAGE.md - HTTP模式](./USAGE.md#http模式)  
- **sse** → [SSE_ISSUE_ANALYSIS.md](./SSE_ISSUE_ANALYSIS.md)
- **http-stream** → [HTTP_STREAM_GUIDE.md](./HTTP_STREAM_GUIDE.md)

#### 工作流模式
- **ReACT工作流** → [USAGE.md - ReACT模式](./USAGE.md#react模式工作流)
- **基础工具** → [USAGE.md - 工具说明](./USAGE.md#工具说明)

#### 集成配置
- **Claude Desktop** → [USAGE.md - Claude Desktop集成](./USAGE.md#与claude-desktop集成)
- **Cherry Studio** → [USAGE.md - Cherry Studio集成](./USAGE.md#与cherry-studio集成)
- **Web应用** → [HTTP_STREAM_GUIDE.md - 客户端连接](./HTTP_STREAM_GUIDE.md#客户端连接)

## 📖 文档规范

### 更新文档
1. 功能变更时同时更新相关文档
2. 保持代码示例的准确性
3. 及时补充新的使用场景
4. 维护文档间的交叉引用

### 文档结构
```
docs/
├── USAGE.md                              # 主要使用指南
├── HTTP_STREAM_GUIDE.md                  # HTTP Stream专题
├── HTTP_STREAM_IMPLEMENTATION_REPORT.md  # 技术实现报告  
├── SSE_ISSUE_ANALYSIS.md                 # 问题分析报告
└── README.md                             # 本文档目录
```

## 🔍 搜索指南

### 按问题类型搜索
- **安装配置** → [USAGE.md](./USAGE.md#快速开始)
- **协议选择** → [USAGE.md](./USAGE.md#协议对比)
- **API错误** → [SSE_ISSUE_ANALYSIS.md](./SSE_ISSUE_ANALYSIS.md)
- **连接问题** → [HTTP_STREAM_GUIDE.md](./HTTP_STREAM_GUIDE.md#故障排除)
- **性能优化** → [HTTP_STREAM_GUIDE.md](./HTTP_STREAM_GUIDE.md#性能建议)

### 按使用场景搜索
- **AI代理集成** → [USAGE.md - ReACT模式](./USAGE.md#react模式推荐ai代理使用)
- **本地开发** → [USAGE.md - stdio模式](./USAGE.md#claude-desktop集成)
- **Web应用** → [HTTP_STREAM_GUIDE.md](./HTTP_STREAM_GUIDE.md#直接http请求)
- **故障排查** → [测试工具](../tests/README.md)

## 📝 贡献文档

欢迎提交文档改进：
1. Fork项目仓库
2. 在`docs/`目录下修改或添加文档
3. 确保Markdown格式正确
4. 更新相关的交叉引用
5. 提交Pull Request

## 📞 支持

如果文档不能解决你的问题：
1. 查看[测试示例](../tests/)了解实际用法
2. 运行[诊断工具](../tests/diagnose_api.py)检查环境
3. 在GitHub Issues中提问
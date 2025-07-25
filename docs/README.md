# 项目文档

本目录包含项目的所有技术文档，为开发者和用户提供详细指导。

## 📚 文档目录

### 🚀 使用指南
- [`USAGE.md`](./USAGE.md) - **完整使用指南** 
  - 三协议同时启动功能详解
  - ReACT工作流完整指南
  - API密钥池管理
  - 集成配置示例
  - 故障排除指南

### 📦 部署指南
- [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md) - **部署指南**
  - UV专用自动部署脚本
  - 三协议服务管理器
  - 多种部署方案对比
  - 详细故障排除指南

### 🛠️ 服务管理
- [`SERVICE_GUIDE.md`](./SERVICE_GUIDE.md) - **服务管理指南**
  - 三协议同时启动管理
  - service_manager.sh脚本使用
  - PID和日志文件管理
  - 环境变量配置
  - 监控和自动重启

### 🔑 API密钥池
- [`API_KEY_POOL_GUIDE.md`](./API_KEY_POOL_GUIDE.md) - **API密钥池配置指南**
  - 多密钥配置方法（含安全最佳实践）
  - 并发控制和负载均衡
  - 故障转移机制
  - 环境变量配置
  - 性能监控和调试

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

### 🌟 新用户入门（推荐路径）
1. **[快速开始](./DEPLOYMENT_GUIDE.md#快速开始)** - 一键部署三协议服务
2. **[服务访问](./USAGE.md#服务访问地址)** - 了解三个访问端点
3. **[协议选择](./USAGE.md#协议选择指南)** - 选择合适的传输协议
4. **[ReACT工作流](./USAGE.md#react模式工作流详解)** - 智能PPT生成

### 🚀 三协议同时启动
1. **[部署服务管理器](./DEPLOYMENT_GUIDE.md#方案1uv专用自动部署推荐新用户)** - 生成service_manager.sh
2. **[启动三协议服务](./SERVICE_GUIDE.md#基本命令)** - HTTP(60) + SSE(61) + HTTP-STREAM(62)
3. **[服务状态监控](./SERVICE_GUIDE.md#服务状态说明)** - 详细状态检查
4. **[日志管理](./SERVICE_GUIDE.md#日志管理)** - 分离式日志查看

### 🤖 ReACT工作流
1. **[ReACT模式详解](./USAGE.md#react模式工作流详解)** - 理解THINK→ACT→OBSERVE→ITERATE
2. **[使用示例](./USAGE.md#react工作流使用示例)** - 完整API调用示例
3. **[测试工具](../tests/README.md#测试http-stream--react工作流推荐)** - 验证功能

### 🔐 API密钥安全配置
1. **[安全配置](./API_KEY_POOL_GUIDE.md#安全注意事项)** - 保护敏感信息
2. **[环境变量配置](./API_KEY_POOL_GUIDE.md#方法2使用环境变量推荐生产环境)** - 生产环境最佳实践
3. **[密钥池监控](./API_KEY_POOL_GUIDE.md#使用mcp工具监控)** - 实时状态查看

### 🔧 问题解决
1. **[部署问题](./DEPLOYMENT_GUIDE.md#故障排除)** - 三协议服务部署问题
2. **[服务管理](./SERVICE_GUIDE.md#故障排除)** - 进程和端口问题
3. **[API调用问题](./USAGE.md#故障排除)** - 密钥和网络问题
4. **[协议特定问题](./HTTP_STREAM_GUIDE.md#故障排除)** - 各协议专门问题

## 🔗 文档关联

### 按功能分类

#### 🌐 协议支持（新架构）
- **三协议同启** → [SERVICE_GUIDE.md - 三协议服务管理器](./SERVICE_GUIDE.md#三协议服务管理器)
- **HTTP (端口60)** → [USAGE.md - HTTP协议](./USAGE.md#方案2单协议启动调试用)
- **SSE (端口61)** → [SSE_ISSUE_ANALYSIS.md](./SSE_ISSUE_ANALYSIS.md)
- **HTTP-STREAM (端口62)** → [HTTP_STREAM_GUIDE.md](./HTTP_STREAM_GUIDE.md)
- **stdio** → [USAGE.md - Claude Desktop集成](./USAGE.md#claude-desktop集成)

#### 🤖 工作流模式
- **ReACT工作流** → [USAGE.md - ReACT模式](./USAGE.md#react模式工作流详解)
- **基础工具** → [USAGE.md - 可用工具](./USAGE.md#可用工具)
- **API密钥池** → [API_KEY_POOL_GUIDE.md](./API_KEY_POOL_GUIDE.md)

#### 🔧 集成配置
- **Claude Desktop** → [USAGE.md - Claude Desktop集成](./USAGE.md#claude-desktop集成)
- **Cherry Studio** → [USAGE.md - Cherry Studio配置](./USAGE.md#cherry-studio配置)
- **Web应用** → [HTTP_STREAM_GUIDE.md - 客户端连接](./HTTP_STREAM_GUIDE.md#客户端连接)

## 📁 文档结构

```
docs/
├── README.md                             # 文档目录（本文件）
├── USAGE.md                              # 主要使用指南
├── DEPLOYMENT_GUIDE.md                   # 部署指南
├── SERVICE_GUIDE.md                      # 服务管理指南
├── API_KEY_POOL_GUIDE.md                 # API密钥池指南（含安全配置）
├── HTTP_STREAM_GUIDE.md                  # HTTP Stream专题
├── HTTP_STREAM_IMPLEMENTATION_REPORT.md  # 技术实现报告  
└── SSE_ISSUE_ANALYSIS.md                 # 问题分析报告
```

## 🌟 新特性文档

### 三协议同时启动
- **部署**: [DEPLOYMENT_GUIDE.md#三协议同时启动](./DEPLOYMENT_GUIDE.md#三协议同时启动)
- **管理**: [SERVICE_GUIDE.md#三协议服务管理器](./SERVICE_GUIDE.md#三协议服务管理器)
- **访问**: [USAGE.md#三协议并发访问](./USAGE.md#三协议并发访问)

### 开箱即用服务管理
- **独立脚本**: [SERVICE_GUIDE.md#方案1三协议服务管理器推荐](./SERVICE_GUIDE.md#方案1三协议服务管理器推荐)
- **无配置依赖**: [DEPLOYMENT_GUIDE.md#方案2开箱即用部署推荐服务器](./DEPLOYMENT_GUIDE.md#方案2开箱即用部署推荐服务器)
- **环境变量配置**: [SERVICE_GUIDE.md#环境变量配置](./SERVICE_GUIDE.md#环境变量配置)

### API密钥安全增强
- **安全最佳实践**: [API_KEY_POOL_GUIDE.md#安全注意事项](./API_KEY_POOL_GUIDE.md#安全注意事项)
- **环境变量保护**: [API_KEY_POOL_GUIDE.md#方法2使用环境变量](./API_KEY_POOL_GUIDE.md#方法2使用环境变量推荐生产环境)
- **多种配置方法**: [API_KEY_POOL_GUIDE.md#配置方法](./API_KEY_POOL_GUIDE.md#配置方法)

## 🔍 搜索指南

### 按问题类型搜索
- **三协议服务问题** → [SERVICE_GUIDE.md#故障排除](./SERVICE_GUIDE.md#故障排除)
- **端口占用问题** → [DEPLOYMENT_GUIDE.md#常见问题与解决方案](./DEPLOYMENT_GUIDE.md#常见问题与解决方案)
- **API密钥配置** → [API_KEY_POOL_GUIDE.md#配置方法](./API_KEY_POOL_GUIDE.md#配置方法)
- **安全配置** → [API_KEY_POOL_GUIDE.md#安全注意事项](./API_KEY_POOL_GUIDE.md#安全注意事项)
- **性能优化** → [API_KEY_POOL_GUIDE.md#性能优化建议](./API_KEY_POOL_GUIDE.md#性能优化建议)

### 按使用场景搜索
- **AI代理集成** → [USAGE.md - ReACT模式](./USAGE.md#react模式工作流详解)
- **服务器部署** → [DEPLOYMENT_GUIDE.md#方案2开箱即用部署](./DEPLOYMENT_GUIDE.md#方案2开箱即用部署推荐服务器)
- **本地开发** → [USAGE.md#方案2单协议启动调试用](./USAGE.md#方案2单协议启动调试用)
- **生产环境** → [SERVICE_GUIDE.md#最佳实践](./SERVICE_GUIDE.md#最佳实践)

## 📖 文档规范

### 更新文档原则
1. 功能变更时同时更新相关文档
2. 保持代码示例的准确性
3. 及时补充新的使用场景
4. 维护文档间的交叉引用
5. 定期清理过时信息

### 安全敏感信息
- ❌ 不要在文档中包含真实API密钥
- ✅ 使用占位符 `your_app_id_here`
- ✅ 提供安全配置指导
- ✅ 说明环境变量保护方法

## 📝 贡献文档

欢迎提交文档改进：
1. Fork项目仓库
2. 在`docs/`目录下修改或添加文档
3. 确保Markdown格式正确
4. 检查是否包含敏感信息
5. 更新相关的交叉引用
6. 提交Pull Request

## 📞 支持

如果文档不能解决你的问题：
1. 查看[测试示例](../tests/)了解实际用法
2. 运行[诊断工具](../tests/diagnose_api.py)检查环境
3. 使用[服务状态检查](./SERVICE_GUIDE.md#服务状态检查)排查问题
4. 在GitHub Issues中提问并提供详细环境信息

---

**🌟 最新特性**: 现已支持三协议同时启动，一次部署即可同时提供HTTP、SSE和HTTP-STREAM三种访问方式！
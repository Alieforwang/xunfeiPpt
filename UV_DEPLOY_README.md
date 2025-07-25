# uv环境自动化部署脚本

专门针对uv环境的讯飞智文PPT服务自动化部署脚本，按照MCP官网和uv官网标准配置。

## 🚀 快速使用

### 基本部署
```bash
# 使用默认配置 (http-stream://0.0.0.0:60)
bash uv_deploy.sh
```

### 自定义配置
```bash
# 自定义端口和主机
bash uv_deploy.sh --port 8080 --host 127.0.0.1

# 使用不同协议
bash uv_deploy.sh --protocol sse --port 60

# 指定工作目录
bash uv_deploy.sh --work-dir /opt/ppt-service
```

## 📋 支持的参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--host` | `0.0.0.0` | 绑定的主机地址 |
| `--port` | `60` | 服务端口 |
| `--protocol` | `http-stream` | 传输协议 (stdio/http/sse/http-stream) |
| `--work-dir` | 当前目录 | 工作目录 |
| `-h, --help` | - | 显示帮助信息 |

## 🛠️ 服务管理

部署完成后，使用生成的服务管理脚本：

```bash
# 启动服务
./service_manager.sh start

# 停止服务
./service_manager.sh stop

# 重启服务
./service_manager.sh restart

# 查看状态
./service_manager.sh status

# 查看日志
./service_manager.sh logs

# 实时查看日志
./service_manager.sh logs -f
```

## ✅ 功能特性

### uv环境管理
- ✅ 自动安装uv (如果未安装)
- ✅ 自动安装Python 3.13+
- ✅ 按照uv官网标准配置项目
- ✅ 使用`uv sync`管理依赖
- ✅ 创建标准的`pyproject.toml`

### MCP标准配置
- ✅ 按照MCP官网标准安装依赖
- ✅ 支持所有MCP传输协议
- ✅ 兼容MCP 2025-03-26规范
- ✅ 自动依赖验证

### 服务管理
- ✅ 完整的服务生命周期管理
- ✅ PID文件管理
- ✅ 日志文件记录
- ✅ 服务状态监控
- ✅ 进程监控和管理

### 参数化配置
- ✅ 支持自定义host和port
- ✅ 支持所有传输协议
- ✅ 配置持久化保存
- ✅ 命令行参数解析

## 🔧 工作原理

1. **环境检查**: 检查并安装uv环境
2. **Python安装**: 自动安装Python 3.13+
3. **项目初始化**: 创建/更新`pyproject.toml`，使用`uv sync`
4. **依赖管理**: 安装并验证MCP相关依赖
5. **服务脚本**: 生成完整的服务管理脚本
6. **配置保存**: 保存服务配置供后续使用

## 📁 生成的文件

部署后会生成以下文件：

```
工作目录/
├── pyproject.toml          # uv项目配置
├── uv.lock                # 依赖锁定文件
├── .python-version         # Python版本固定
├── .venv/                  # 虚拟环境目录
├── service_manager.sh      # 服务管理脚本
├── .service_config         # 服务配置文件
├── service.pid             # 服务PID文件 (运行时)
└── service.log             # 服务日志文件 (运行时)
```

## 🌍 系统支持

- ✅ Linux (所有发行版)
- ✅ macOS
- ✅ Windows (WSL/Git Bash/MSYS2)

## 📝 使用示例

### 开发环境
```bash
# 开发环境，使用localhost
bash uv_deploy.sh --host 127.0.0.1 --port 8080 --protocol http-stream
./service_manager.sh start
```

### 生产环境
```bash
# 生产环境，绑定所有接口
bash uv_deploy.sh --host 0.0.0.0 --port 60 --protocol http-stream
./service_manager.sh start
```

### 测试环境
```bash
# 测试环境，使用SSE协议
bash uv_deploy.sh --protocol sse --port 8001
./service_manager.sh start
./service_manager.sh logs -f  # 实时查看日志
```

## 🔍 故障排除

### 常见问题

1. **uv安装失败**
   ```bash
   # 手动安装uv
   curl -LsSf https://astral.sh/uv/install.sh | sh
   export PATH="$HOME/.cargo/bin:$PATH"
   ```

2. **Python 3.13安装失败**
   ```bash
   # 检查uv python支持
   uv python list
   uv python install 3.13
   ```

3. **服务启动失败**
   ```bash
   # 查看详细日志
   ./service_manager.sh logs
   
   # 手动测试启动
   uv run python main.py http-stream --host 0.0.0.0 --port 60
   ```

4. **端口被占用**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep 60
   
   # 使用其他端口
   bash uv_deploy.sh --port 8080
   ```

### 调试模式

```bash
# 启用详细输出
bash -x uv_deploy.sh --port 8080

# 查看uv环境
uv python list
uv tree
```

## 📞 技术支持

如果遇到问题：
1. 查看服务日志：`./service_manager.sh logs`
2. 检查uv环境：`uv --version` 和 `uv python list`
3. 手动测试启动：`uv run python main.py http-stream`
4. 提交GitHub Issue
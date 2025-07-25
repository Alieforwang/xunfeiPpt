#!/bin/bash

# 讯飞智文PPT服务 - uv环境自动化部署脚本
# 基于MCP官网和uv官网标准配置

set -e

echo "=== 讯飞智文PPT服务 - uv环境自动部署 ==="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 默认配置
DEFAULT_HOST="0.0.0.0"
DEFAULT_PORT="60"
DEFAULT_PROTOCOL="http-stream"
WORK_DIR="$(pwd)"
SERVICE_NAME="ppt-mcp-server"

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --host)
                HOST="$2"
                shift 2
                ;;
            --port)
                PORT="$2"
                shift 2
                ;;
            --protocol)
                PROTOCOL="$2"
                shift 2
                ;;
            --work-dir)
                WORK_DIR="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 设置默认值
    HOST=${HOST:-$DEFAULT_HOST}
    PORT=${PORT:-$DEFAULT_PORT}
    PROTOCOL=${PROTOCOL:-$DEFAULT_PROTOCOL}
}

# 显示帮助信息
show_help() {
    cat << EOF
讯飞智文PPT服务 - uv环境自动部署脚本

用法: $0 [选项]

选项:
    --host HOST         绑定的主机地址 (默认: $DEFAULT_HOST)
    --port PORT         服务端口 (默认: $DEFAULT_PORT)
    --protocol PROTOCOL 传输协议 (默认: $DEFAULT_PROTOCOL)
                       可选: stdio, http, sse, http-stream
    --work-dir DIR      工作目录 (默认: 当前目录)
    -h, --help         显示此帮助信息

示例:
    $0                                    # 使用默认配置
    $0 --port 8080 --host 127.0.0.1     # 自定义端口和主机
    $0 --protocol sse --port 60          # 使用SSE协议

EOF
}

# 检查uv是否安装
check_uv_installation() {
    log_info "检查uv安装状态..."
    
    if ! command -v uv >/dev/null 2>&1; then
        log_warning "uv未安装，开始安装uv..."
        install_uv
    else
        UV_VERSION=$(uv --version 2>/dev/null || echo "unknown")
        log_success "uv已安装: $UV_VERSION"
    fi
}

# 安装uv (按照uv官网标准)
install_uv() {
    log_info "按照uv官网标准安装uv..."
    
    if command -v curl >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://astral.sh/uv/install.sh | sh
    else
        log_error "需要curl或wget来安装uv"
        exit 1
    fi
    
    # 重新加载PATH
    export PATH="$HOME/.cargo/bin:$PATH"
    
    if command -v uv >/dev/null 2>&1; then
        log_success "uv安装成功: $(uv --version)"
    else
        log_error "uv安装失败"
        exit 1
    fi
}

# 检查Python 3.13+环境
check_python_environment() {
    log_info "检查Python 3.13+环境..."
    
    # 检查是否已有Python 3.13+
    if uv python list | grep -q "3\.1[3-9]"; then
        log_success "检测到Python 3.13+环境"
        return 0
    fi
    
    log_info "安装Python 3.13..."
    if uv python install 3.13; then
        log_success "Python 3.13安装成功"
    else
        log_error "Python 3.13安装失败"
        exit 1
    fi
}

# 初始化项目环境 (按照MCP官网标准)
initialize_project() {
    log_info "初始化uv项目环境..."
    
    cd "$WORK_DIR"
    
    # 检查pyproject.toml是否存在
    if [ ! -f "pyproject.toml" ]; then
        log_warning "未找到pyproject.toml，创建基本配置..."
        create_pyproject_toml
    fi
    
    # 设置Python版本
    log_info "设置Python版本为3.13..."
    uv python pin 3.13
    
    # 同步依赖
    log_info "同步项目依赖..."
    uv sync
    
    log_success "项目环境初始化完成"
}

# 创建pyproject.toml配置
create_pyproject_toml() {
    cat > pyproject.toml << EOF
[project]
name = "pptmcpserver"
version = "0.1.0"
description = "讯飞智文PPT生成服务MCP Server"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    "mcp[cli]>=1.12.1",
    "requests>=2.31.0",
    "requests-toolbelt>=1.0.0",
    "starlette>=0.27.0",
    "uvicorn>=0.23.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = []
EOF
    log_success "已创建pyproject.toml配置文件"
}

# 验证依赖安装
verify_dependencies() {
    log_info "验证依赖安装..."
    
    local dependencies=("mcp" "requests" "starlette" "uvicorn")
    local failed_deps=()
    
    for dep in "${dependencies[@]}"; do
        if uv run python -c "import $dep" 2>/dev/null; then
            log_info "  ✓ $dep"
        else
            log_warning "  ✗ $dep"
            failed_deps+=("$dep")
        fi
    done
    
    if [ ${#failed_deps[@]} -eq 0 ]; then
        log_success "所有依赖验证通过"
    else
        log_warning "部分依赖验证失败: ${failed_deps[*]}"
        log_info "依赖可能需要时间生效，继续部署..."
    fi
}

# 创建服务管理脚本
create_service_manager() {
    log_info "创建服务管理脚本..."
    
    cat > service_manager.sh << 'EOF'
#!/bin/bash

# 讯飞智文PPT服务管理脚本

SERVICE_NAME="ppt-mcp-server"
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$WORK_DIR/service.pid"
LOG_FILE="$WORK_DIR/service.log"

# 读取配置
if [ -f "$WORK_DIR/.service_config" ]; then
    source "$WORK_DIR/.service_config"
else
    HOST="0.0.0.0"
    PORT="60"
    PROTOCOL="http-stream"
fi

# 启动服务
start_service() {
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
        echo "服务已在运行 (PID: $(cat "$PID_FILE"))"
        return 0
    fi
    
    echo "启动PPT MCP服务..."
    echo "配置: $PROTOCOL://$HOST:$PORT"
    
    cd "$WORK_DIR"
    nohup uv run python main.py "$PROTOCOL" --host "$HOST" --port "$PORT" > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    
    sleep 2
    if ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
        echo "✅ 服务启动成功"
        echo "PID: $(cat "$PID_FILE")"
        echo "日志: $LOG_FILE"
        echo "访问: http://$HOST:$PORT"
    else
        echo "❌ 服务启动失败"
        rm -f "$PID_FILE"
        return 1
    fi
}

# 停止服务
stop_service() {
    if [ ! -f "$PID_FILE" ]; then
        echo "服务未运行"
        return 0
    fi
    
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "停止服务 (PID: $PID)..."
        kill "$PID"
        
        # 等待进程结束
        for i in {1..10}; do
            if ! ps -p "$PID" > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        
        # 强制杀死进程
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "强制停止服务..."
            kill -9 "$PID"
        fi
        
        echo "✅ 服务已停止"
    else
        echo "服务进程不存在"
    fi
    
    rm -f "$PID_FILE"
}

# 重启服务
restart_service() {
    echo "重启服务..."
    stop_service
    sleep 2
    start_service
}

# 查看服务状态
status_service() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ 服务正在运行"
            echo "PID: $PID"
            echo "配置: $PROTOCOL://$HOST:$PORT"
            echo "日志: $LOG_FILE"
            echo "访问: http://$HOST:$PORT"
            
            # 显示进程信息
            echo ""
            echo "进程信息:"
            ps -p "$PID" -o pid,ppid,start,time,cmd
        else
            echo "❌ 服务已停止 (PID文件存在但进程不存在)"
            rm -f "$PID_FILE"
        fi
    else
        echo "❌ 服务未运行"
    fi
}

# 查看日志
logs_service() {
    if [ -f "$LOG_FILE" ]; then
        echo "=== 服务日志 ==="
        if [ "$1" = "-f" ]; then
            tail -f "$LOG_FILE"
        else
            tail -n 50 "$LOG_FILE"
        fi
    else
        echo "日志文件不存在: $LOG_FILE"
    fi
}

# 主命令处理
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        status_service
        ;;
    logs)
        logs_service "$2"
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs [-f]}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动服务"
        echo "  stop    - 停止服务"
        echo "  restart - 重启服务"
        echo "  status  - 查看状态"
        echo "  logs    - 查看日志"
        echo "  logs -f - 实时查看日志"
        exit 1
        ;;
esac
EOF

    chmod +x service_manager.sh
    log_success "服务管理脚本创建完成"
}

# 保存服务配置
save_service_config() {
    log_info "保存服务配置..."
    
    cat > .service_config << EOF
# 服务配置文件
HOST="$HOST"
PORT="$PORT"
PROTOCOL="$PROTOCOL"
WORK_DIR="$WORK_DIR"
EOF
    
    log_success "服务配置已保存"
}

# 测试服务
test_service() {
    log_info "测试服务启动..."
    
    # 启动服务进行测试
    cd "$WORK_DIR"
    timeout 10 uv run python main.py "$PROTOCOL" --host "$HOST" --port "$PORT" &
    TEST_PID=$!
    
    sleep 3
    
    # 检查服务是否响应
    if kill -0 "$TEST_PID" 2>/dev/null; then
        log_success "服务测试通过"
        kill "$TEST_PID" 2>/dev/null || true
    else
        log_warning "服务测试失败，请检查配置"
    fi
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo "=== 部署完成 ==="
    echo ""
    log_success "工作目录: $WORK_DIR"
    log_success "服务协议: $PROTOCOL"
    log_success "绑定地址: $HOST:$PORT"
    echo ""
    echo "=== 服务管理 ==="
    echo "启动服务: ./service_manager.sh start"
    echo "停止服务: ./service_manager.sh stop"
    echo "重启服务: ./service_manager.sh restart"
    echo "查看状态: ./service_manager.sh status"
    echo "查看日志: ./service_manager.sh logs"
    echo "实时日志: ./service_manager.sh logs -f"
    echo ""
    echo "=== 访问地址 ==="
    if [ "$HOST" = "0.0.0.0" ]; then
        echo "本地访问: http://localhost:$PORT"
        echo "局域网访问: http://$(hostname -I | awk '{print $1}'):$PORT"
    else
        echo "访问地址: http://$HOST:$PORT"
    fi
    echo ""
    log_success "部署完成！运行 './service_manager.sh start' 启动服务"
}

# 主函数
main() {
    # 解析参数
    parse_arguments "$@"
    
    log_info "开始部署讯飞智文PPT服务..."
    log_info "配置: $PROTOCOL://$HOST:$PORT"
    log_info "工作目录: $WORK_DIR"
    
    # 执行部署步骤
    check_uv_installation
    check_python_environment
    initialize_project
    verify_dependencies
    create_service_manager
    save_service_config
    test_service
    show_deployment_result
}

# 错误处理
trap 'log_error "部署过程中发生错误，退出码: $?"' ERR

# 执行主函数
main "$@"
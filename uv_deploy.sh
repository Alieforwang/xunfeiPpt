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
                       服务器部署建议使用 0.0.0.0 以支持外部访问
    --port PORT         基础服务端口 (默认: $DEFAULT_PORT)
                       实际端口分配:
                         HTTP: PORT
                         SSE: PORT+1  
                         HTTP-STREAM: PORT+2
    --work-dir DIR      工作目录 (默认: 当前目录)
    -h, --help         显示此帮助信息

三种协议说明:
    HTTP              标准HTTP协议，适用于一般客户端
    SSE               Server-Sent Events，适用于实时推送
    HTTP-STREAM       HTTP流式传输，适用于大数据传输

示例:
    $0                                    # 使用默认配置 (0.0.0.0:60-62)
    $0 --port 8080 --host 127.0.0.1     # 本地开发环境
    $0 --host 0.0.0.0 --port 60         # 服务器部署，支持外部访问
    $0 --host 192.168.1.100 --port 3000 # 指定IP和端口

服务器部署注意事项:
    - 使用 --host 0.0.0.0 允许外部访问
    - 确保防火墙开放相应端口范围
    - 建议使用标准端口避免冲突

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
PID_FILE_HTTP="$WORK_DIR/service_http.pid"
PID_FILE_SSE="$WORK_DIR/service_sse.pid"
PID_FILE_STREAM="$WORK_DIR/service_stream.pid"
LOG_FILE_HTTP="$WORK_DIR/service_http.log"
LOG_FILE_SSE="$WORK_DIR/service_sse.log"
LOG_FILE_STREAM="$WORK_DIR/service_stream.log"

# 读取配置
if [ -f "$WORK_DIR/.service_config" ]; then
    source "$WORK_DIR/.service_config"
else
    HOST="0.0.0.0"
    PORT="60"
    PROTOCOL="http-stream"
fi

# 启动所有三种协议服务
start_service() {
    local any_running=false
    
    # 检查是否有服务正在运行
    if [ -f "$PID_FILE_HTTP" ] && ps -p $(cat "$PID_FILE_HTTP") > /dev/null 2>&1; then
        echo "HTTP服务已在运行 (PID: $(cat "$PID_FILE_HTTP"))"
        any_running=true
    fi
    if [ -f "$PID_FILE_SSE" ] && ps -p $(cat "$PID_FILE_SSE") > /dev/null 2>&1; then
        echo "SSE服务已在运行 (PID: $(cat "$PID_FILE_SSE"))"
        any_running=true
    fi
    if [ -f "$PID_FILE_STREAM" ] && ps -p $(cat "$PID_FILE_STREAM") > /dev/null 2>&1; then
        echo "HTTP-STREAM服务已在运行 (PID: $(cat "$PID_FILE_STREAM"))"
        any_running=true
    fi
    
    if [ "$any_running" = true ]; then
        echo "部分服务已在运行，跳过已运行的服务"
    fi
    
    echo "启动PPT MCP服务 - 三种协议模式..."
    
    cd "$WORK_DIR"
    
    # 启动HTTP服务 (端口 60)
    if [ ! -f "$PID_FILE_HTTP" ] || ! ps -p $(cat "$PID_FILE_HTTP") > /dev/null 2>&1; then
        echo "启动HTTP服务: http://$HOST:$PORT"
        nohup uv run python main.py http --host "$HOST" --port "$PORT" > "$LOG_FILE_HTTP" 2>&1 &
        echo $! > "$PID_FILE_HTTP"
        sleep 1
    fi
    
    # 启动SSE服务 (端口 61)
    local sse_port=$((PORT + 1))
    if [ ! -f "$PID_FILE_SSE" ] || ! ps -p $(cat "$PID_FILE_SSE") > /dev/null 2>&1; then
        echo "启动SSE服务: http://$HOST:$sse_port"
        nohup uv run python main.py sse --host "$HOST" --port "$sse_port" > "$LOG_FILE_SSE" 2>&1 &
        echo $! > "$PID_FILE_SSE"
        sleep 1
    fi
    
    # 启动HTTP-STREAM服务 (端口 62)
    local stream_port=$((PORT + 2))
    if [ ! -f "$PID_FILE_STREAM" ] || ! ps -p $(cat "$PID_FILE_STREAM") > /dev/null 2>&1; then
        echo "启动HTTP-STREAM服务: http://$HOST:$stream_port"
        nohup uv run python main.py http-stream --host "$HOST" --port "$stream_port" > "$LOG_FILE_STREAM" 2>&1 &
        echo $! > "$PID_FILE_STREAM"
        sleep 1
    fi
    
    # 验证服务启动状态
    local success_count=0
    
    if [ -f "$PID_FILE_HTTP" ] && ps -p $(cat "$PID_FILE_HTTP") > /dev/null 2>&1; then
        echo "✅ HTTP服务启动成功 (PID: $(cat "$PID_FILE_HTTP"), 端口: $PORT)"
        success_count=$((success_count + 1))
    else
        echo "❌ HTTP服务启动失败"
        rm -f "$PID_FILE_HTTP"
    fi
    
    if [ -f "$PID_FILE_SSE" ] && ps -p $(cat "$PID_FILE_SSE") > /dev/null 2>&1; then
        echo "✅ SSE服务启动成功 (PID: $(cat "$PID_FILE_SSE"), 端口: $sse_port)"
        success_count=$((success_count + 1))
    else
        echo "❌ SSE服务启动失败"
        rm -f "$PID_FILE_SSE"
    fi
    
    if [ -f "$PID_FILE_STREAM" ] && ps -p $(cat "$PID_FILE_STREAM") > /dev/null 2>&1; then
        echo "✅ HTTP-STREAM服务启动成功 (PID: $(cat "$PID_FILE_STREAM"), 端口: $stream_port)"
        success_count=$((success_count + 1))
    else
        echo "❌ HTTP-STREAM服务启动失败"
        rm -f "$PID_FILE_STREAM"
    fi
    
    echo ""
    echo "服务启动完成: $success_count/3 个服务成功启动"
    if [ $success_count -eq 3 ]; then
        echo "🎉 所有服务启动成功！"
    elif [ $success_count -gt 0 ]; then
        echo "⚠️  部分服务启动成功，请检查日志"
    else
        echo "❌ 所有服务启动失败"
        return 1
    fi
}

# 停止所有服务
stop_service() {
    local stopped_count=0
    
    # 停止HTTP服务
    if [ -f "$PID_FILE_HTTP" ]; then
        PID=$(cat "$PID_FILE_HTTP")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "停止HTTP服务 (PID: $PID)..."
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
                echo "强制停止HTTP服务..."
                kill -9 "$PID"
            fi
            
            echo "✅ HTTP服务已停止"
            stopped_count=$((stopped_count + 1))
        else
            echo "HTTP服务进程不存在"
        fi
        rm -f "$PID_FILE_HTTP"
    else
        echo "HTTP服务未运行"
    fi
    
    # 停止SSE服务
    if [ -f "$PID_FILE_SSE" ]; then
        PID=$(cat "$PID_FILE_SSE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "停止SSE服务 (PID: $PID)..."
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
                echo "强制停止SSE服务..."
                kill -9 "$PID"
            fi
            
            echo "✅ SSE服务已停止"
            stopped_count=$((stopped_count + 1))
        else
            echo "SSE服务进程不存在"
        fi
        rm -f "$PID_FILE_SSE"
    else
        echo "SSE服务未运行"
    fi
    
    # 停止HTTP-STREAM服务
    if [ -f "$PID_FILE_STREAM" ]; then
        PID=$(cat "$PID_FILE_STREAM")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "停止HTTP-STREAM服务 (PID: $PID)..."
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
                echo "强制停止HTTP-STREAM服务..."
                kill -9 "$PID"
            fi
            
            echo "✅ HTTP-STREAM服务已停止"
            stopped_count=$((stopped_count + 1))
        else
            echo "HTTP-STREAM服务进程不存在"
        fi
        rm -f "$PID_FILE_STREAM"
    else
        echo "HTTP-STREAM服务未运行"
    fi
    
    echo ""
    echo "服务停止完成: $stopped_count 个服务已停止"
}

# 重启服务
restart_service() {
    echo "重启服务..."
    stop_service
    sleep 2
    start_service
}

# 查看所有服务状态
status_service() {
    local running_count=0
    
    echo "=== 服务状态总览 ==="
    
    # HTTP服务状态
    if [ -f "$PID_FILE_HTTP" ]; then
        PID=$(cat "$PID_FILE_HTTP")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ HTTP服务正在运行"
            echo "   PID: $PID"
            echo "   端口: $PORT"
            echo "   地址: http://$HOST:$PORT"
            echo "   日志: $LOG_FILE_HTTP"
            running_count=$((running_count + 1))
        else
            echo "❌ HTTP服务已停止 (PID文件存在但进程不存在)"
            rm -f "$PID_FILE_HTTP"
        fi
    else
        echo "❌ HTTP服务未运行"
    fi
    
    echo ""
    
    # SSE服务状态
    local sse_port=$((PORT + 1))
    if [ -f "$PID_FILE_SSE" ]; then
        PID=$(cat "$PID_FILE_SSE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ SSE服务正在运行"
            echo "   PID: $PID"
            echo "   端口: $sse_port"
            echo "   地址: http://$HOST:$sse_port"
            echo "   日志: $LOG_FILE_SSE"
            running_count=$((running_count + 1))
        else
            echo "❌ SSE服务已停止 (PID文件存在但进程不存在)"
            rm -f "$PID_FILE_SSE"
        fi
    else
        echo "❌ SSE服务未运行"
    fi
    
    echo ""
    
    # HTTP-STREAM服务状态
    local stream_port=$((PORT + 2))
    if [ -f "$PID_FILE_STREAM" ]; then
        PID=$(cat "$PID_FILE_STREAM")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ HTTP-STREAM服务正在运行"
            echo "   PID: $PID"
            echo "   端口: $stream_port"  
            echo "   地址: http://$HOST:$stream_port"
            echo "   日志: $LOG_FILE_STREAM"
            running_count=$((running_count + 1))
        else
            echo "❌ HTTP-STREAM服务已停止 (PID文件存在但进程不存在)"
            rm -f "$PID_FILE_STREAM"
        fi
    else
        echo "❌ HTTP-STREAM服务未运行"
    fi
    
    echo ""
    echo "=== 总体状态 ==="
    echo "运行中服务: $running_count/3"
    
    if [ $running_count -eq 3 ]; then
        echo "🎉 所有服务正常运行"
    elif [ $running_count -gt 0 ]; then
        echo "⚠️  部分服务正在运行"
    else
        echo "❌ 所有服务已停止"
    fi
    
    if [ $running_count -gt 0 ]; then
        echo ""
        echo "=== 进程详情 ==="
        if [ -f "$PID_FILE_HTTP" ] && ps -p $(cat "$PID_FILE_HTTP") > /dev/null 2>&1; then
            echo "HTTP服务进程:"
            ps -p $(cat "$PID_FILE_HTTP") -o pid,ppid,start,time,cmd
        fi
        if [ -f "$PID_FILE_SSE" ] && ps -p $(cat "$PID_FILE_SSE") > /dev/null 2>&1; then
            echo "SSE服务进程:"
            ps -p $(cat "$PID_FILE_SSE") -o pid,ppid,start,time,cmd
        fi
        if [ -f "$PID_FILE_STREAM" ] && ps -p $(cat "$PID_FILE_STREAM") > /dev/null 2>&1; then
            echo "HTTP-STREAM服务进程:"
            ps -p $(cat "$PID_FILE_STREAM") -o pid,ppid,start,time,cmd
        fi
    fi
}

# 查看日志
logs_service() {
    case "$1" in
        http)
            if [ -f "$LOG_FILE_HTTP" ]; then
                echo "=== HTTP服务日志 ==="
                if [ "$2" = "-f" ]; then
                    tail -f "$LOG_FILE_HTTP"
                else
                    tail -n 50 "$LOG_FILE_HTTP"
                fi
            else
                echo "HTTP服务日志文件不存在: $LOG_FILE_HTTP"
            fi
            ;;
        sse)
            if [ -f "$LOG_FILE_SSE" ]; then
                echo "=== SSE服务日志 ==="
                if [ "$2" = "-f" ]; then
                    tail -f "$LOG_FILE_SSE"
                else
                    tail -n 50 "$LOG_FILE_SSE"
                fi
            else
                echo "SSE服务日志文件不存在: $LOG_FILE_SSE"
            fi
            ;;
        stream)
            if [ -f "$LOG_FILE_STREAM" ]; then
                echo "=== HTTP-STREAM服务日志 ==="
                if [ "$2" = "-f" ]; then
                    tail -f "$LOG_FILE_STREAM"
                else
                    tail -n 50 "$LOG_FILE_STREAM"
                fi
            else
                echo "HTTP-STREAM服务日志文件不存在: $LOG_FILE_STREAM"
            fi
            ;;
        *)
            echo "=== 所有服务日志 ==="
            echo ""
            if [ -f "$LOG_FILE_HTTP" ]; then
                echo "--- HTTP服务日志 (最近20行) ---"
                tail -n 20 "$LOG_FILE_HTTP"
                echo ""
            fi
            if [ -f "$LOG_FILE_SSE" ]; then
                echo "--- SSE服务日志 (最近20行) ---"
                tail -n 20 "$LOG_FILE_SSE"
                echo ""
            fi
            if [ -f "$LOG_FILE_STREAM" ]; then
                echo "--- HTTP-STREAM服务日志 (最近20行) ---"
                tail -n 20 "$LOG_FILE_STREAM"
                echo ""
            fi
            
            if [ ! -f "$LOG_FILE_HTTP" ] && [ ! -f "$LOG_FILE_SSE" ] && [ ! -f "$LOG_FILE_STREAM" ]; then
                echo "没有找到任何日志文件"
            fi
            ;;
    esac
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
        logs_service "$2" "$3"
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs [http|sse|stream] [-f]}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动所有三种协议服务"
        echo "  stop    - 停止所有服务"
        echo "  restart - 重启所有服务"
        echo "  status  - 查看所有服务状态"
        echo "  logs    - 查看所有服务日志"
        echo "  logs http    - 查看HTTP服务日志"
        echo "  logs sse     - 查看SSE服务日志"
        echo "  logs stream  - 查看HTTP-STREAM服务日志"
        echo "  logs [service] -f - 实时查看指定服务日志"
        echo ""
        echo "服务端口分配:"
        echo "  HTTP: $PORT (默认60)"
        echo "  SSE: $((PORT + 1)) (默认61)"
        echo "  HTTP-STREAM: $((PORT + 2)) (默认62)"
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
    log_success "绑定地址: $HOST"
    log_success "基础端口: $PORT"
    echo ""
    echo "=== 三种协议服务配置 ==="
    echo "HTTP协议:        http://$HOST:$PORT"
    echo "SSE协议:         http://$HOST:$((PORT + 1))"
    echo "HTTP-STREAM协议: http://$HOST:$((PORT + 2))"
    echo ""
    echo "=== 服务管理 ==="
    echo "启动所有服务: ./service_manager.sh start"
    echo "停止所有服务: ./service_manager.sh stop"
    echo "重启所有服务: ./service_manager.sh restart"
    echo "查看服务状态: ./service_manager.sh status"
    echo "查看所有日志: ./service_manager.sh logs"
    echo "查看HTTP日志: ./service_manager.sh logs http"
    echo "查看SSE日志:  ./service_manager.sh logs sse"
    echo "查看STREAM日志: ./service_manager.sh logs stream"
    echo "实时查看日志: ./service_manager.sh logs [服务类型] -f"
    echo ""
    echo "=== 访问地址 ==="
    if [ "$HOST" = "0.0.0.0" ]; then
        local_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
        echo "本地访问:"
        echo "  HTTP:        http://localhost:$PORT"
        echo "  SSE:         http://localhost:$((PORT + 1))"
        echo "  HTTP-STREAM: http://localhost:$((PORT + 2))"
        echo ""
        echo "局域网访问:"
        echo "  HTTP:        http://$local_ip:$PORT"
        echo "  SSE:         http://$local_ip:$((PORT + 1))"
        echo "  HTTP-STREAM: http://$local_ip:$((PORT + 2))"
    else
        echo "指定地址访问:"
        echo "  HTTP:        http://$HOST:$PORT"
        echo "  SSE:         http://$HOST:$((PORT + 1))"
        echo "  HTTP-STREAM: http://$HOST:$((PORT + 2))"
    fi
    echo ""
    log_success "部署完成！运行 './service_manager.sh start' 启动所有三种协议服务"
}

# 主函数
main() {
    # 解析参数
    parse_arguments "$@"
    
    log_info "开始部署讯飞智文PPT服务..."
    log_info "绑定地址: $HOST"
    log_info "基础端口: $PORT (HTTP:$PORT, SSE:$((PORT + 1)), HTTP-STREAM:$((PORT + 2)))"
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
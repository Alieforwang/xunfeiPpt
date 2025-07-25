#!/bin/bash

# 讯飞智文PPT服务管理脚本 - 三协议版本

SERVICE_NAME="ppt-mcp-server"
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 默认配置（可以通过环境变量覆盖）
HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-"60"}

# PID和日志文件路径
PID_FILE_HTTP="$WORK_DIR/service_http.pid"
PID_FILE_SSE="$WORK_DIR/service_sse.pid"
PID_FILE_STREAM="$WORK_DIR/service_stream.pid"
LOG_FILE_HTTP="$WORK_DIR/service_http.log"
LOG_FILE_SSE="$WORK_DIR/service_sse.log"
LOG_FILE_STREAM="$WORK_DIR/service_stream.log"

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
    echo "绑定地址: $HOST"
    echo "基础端口: $PORT"
    echo ""
    
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
    echo ""
    echo "验证服务启动状态..."
    
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
        echo ""
        echo "访问地址:"
        echo "  HTTP:        http://$HOST:$PORT"
        echo "  SSE:         http://$HOST:$sse_port"
        echo "  HTTP-STREAM: http://$HOST:$stream_port"
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
    echo "停止所有PPT MCP服务..."
    
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
    echo "重启所有服务..."
    stop_service
    sleep 2
    start_service
}

# 查看所有服务状态
status_service() {
    local running_count=0
    local sse_port=$((PORT + 1))
    local stream_port=$((PORT + 2))
    
    echo "=== PPT MCP服务状态总览 ==="
    echo "绑定地址: $HOST"
    echo "基础端口: $PORT"
    echo ""
    
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
        echo ""
        echo "完整访问地址:"
        echo "  HTTP:        http://$HOST:$PORT"
        echo "  SSE:         http://$HOST:$sse_port"
        echo "  HTTP-STREAM: http://$HOST:$stream_port"
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
            echo ""
        fi
        if [ -f "$PID_FILE_SSE" ] && ps -p $(cat "$PID_FILE_SSE") > /dev/null 2>&1; then
            echo "SSE服务进程:"
            ps -p $(cat "$PID_FILE_SSE") -o pid,ppid,start,time,cmd
            echo ""
        fi
        if [ -f "$PID_FILE_STREAM" ] && ps -p $(cat "$PID_FILE_STREAM") > /dev/null 2>&1; then
            echo "HTTP-STREAM服务进程:"
            ps -p $(cat "$PID_FILE_STREAM") -o pid,ppid,start,time,cmd
            echo ""
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
        echo "讯飞智文PPT服务管理脚本 - 三协议版本"
        echo ""
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
        echo "  HTTP: $PORT (基础端口)"
        echo "  SSE: $((PORT + 1)) (基础端口+1)"
        echo "  HTTP-STREAM: $((PORT + 2)) (基础端口+2)"
        echo ""
        echo "环境变量配置:"
        echo "  HOST=$HOST (绑定地址)"
        echo "  PORT=$PORT (基础端口)"
        echo ""
        echo "示例:"
        echo "  $0 start              # 启动所有服务"
        echo "  $0 status             # 查看状态"
        echo "  HOST=127.0.0.1 $0 start  # 指定绑定地址"
        echo "  PORT=8080 $0 start    # 指定基础端口"
        exit 1
        ;;
esac
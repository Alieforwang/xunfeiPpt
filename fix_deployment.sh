#!/bin/bash

# 临时修复脚本 - 直接修复服务器上的部署问题
# 这个脚本可以直接在服务器上运行来应用修复

echo "=== 修复部署脚本问题 ==="

WORK_DIR="/www/wwwroot/xunfeiPpt"

echo "1. 停止并清理旧的systemd服务..."
systemctl stop ppt-mcp-sse 2>/dev/null || true
systemctl disable ppt-mcp-sse 2>/dev/null || true
rm -f /etc/systemd/system/ppt-mcp-sse.service
systemctl daemon-reload

echo "2. 检查Python环境配置..."
if [ -f "$WORK_DIR/.python_env" ]; then
    source "$WORK_DIR/.python_env"
    echo "找到Python环境配置: $PYTHON_CMD (来源: $PYTHON_SOURCE)"
else
    echo "未找到.python_env文件，使用检测到的环境"
    # 检测Python 3.13
    if command -v python3.13 >/dev/null 2>&1; then
        PYTHON_CMD="python3.13"
        PYTHON_SOURCE="system"
        echo "检测到: python3.13 (系统环境)"
    else
        echo "错误: 未找到Python 3.13"
        exit 1
    fi
fi

echo "3. 验证依赖安装..."
# 使用uv验证依赖
if command -v uv >/dev/null 2>&1; then
    echo "使用uv验证依赖..."
    cd "$WORK_DIR"
    
    # 创建虚拟环境并安装依赖
    uv venv --python "$PYTHON_CMD" || true
    source .venv/bin/activate || true
    uv pip install mcp requests requests-toolbelt starlette uvicorn
    
    echo "依赖安装完成"
else
    echo "未找到uv，使用pip安装依赖"
    $PYTHON_CMD -m pip install mcp requests requests-toolbelt starlette uvicorn
fi

echo "4. 创建正确的systemd服务..."
SERVICE_FILE="/etc/systemd/system/ppt-mcp-sse.service"

# 根据Python环境设置启动命令
if [ "$PYTHON_SOURCE" = "uv" ]; then
    EXEC_START_CMD="uv run python main.py sse --host 0.0.0.0 --port 60"
    ENVIRONMENT_PATH="Environment=PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
else
    EXEC_START_CMD="$PYTHON_CMD main.py sse --host 0.0.0.0 --port 60"
    ENVIRONMENT_PATH="Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
fi

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=讯飞智文PPT生成服务MCP Server - SSE传输
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$WORK_DIR
$ENVIRONMENT_PATH
ExecStart=$EXEC_START_CMD
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ppt-mcp-sse

[Install]
WantedBy=multi-user.target
EOF

echo "5. 启动服务..."
chmod 644 "$SERVICE_FILE"
systemctl daemon-reload
systemctl enable ppt-mcp-sse
systemctl start ppt-mcp-sse

echo "6. 等待服务启动..."
sleep 3

echo "7. 检查服务状态..."
if systemctl is-active --quiet ppt-mcp-sse; then
    echo "✅ 服务修复成功！"
    echo ""
    echo "服务状态:"
    systemctl status ppt-mcp-sse --no-pager -l
    echo ""
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):60"
else
    echo "❌ 服务仍然启动失败"
    echo "详细日志:"
    journalctl -u ppt-mcp-sse -n 10 --no-pager
    echo ""
    echo "检查Python命令是否可用:"
    echo "测试命令: $EXEC_START_CMD"
    cd "$WORK_DIR"
    $PYTHON_CMD --version
fi

echo "=== 修复完成 ==="
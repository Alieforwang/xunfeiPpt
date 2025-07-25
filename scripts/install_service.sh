#!/bin/bash

# 讯飞智文PPT生成服务系统服务安装脚本

set -e

echo "=== 讯飞智文PPT生成服务系统服务安装脚本 ==="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用root权限运行此脚本"
    echo "使用方法: sudo bash install_service.sh"
    exit 1
fi

# 配置变量
SERVICE_NAME="ppt-mcp-sse"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
WORK_DIR="/www/wwwroot/xunfeiPpt"

# 读取Python环境配置
if [ -f "$WORK_DIR/.python_env" ]; then
    source "$WORK_DIR/.python_env"
    echo "使用检测到的Python环境: $PYTHON_CMD (来源: $PYTHON_SOURCE)"
else
    echo "警告: 未找到Python环境配置，使用默认配置"
    PYTHON_CMD="python3"
    PYTHON_SOURCE="system"
fi

echo "检查工作目录..."
if [ ! -d "$WORK_DIR" ]; then
    echo "错误: 工作目录 $WORK_DIR 不存在"
    exit 1
fi

echo "检查main.py文件..."
if [ ! -f "$WORK_DIR/main.py" ]; then
    echo "错误: $WORK_DIR/main.py 文件不存在"
    exit 1
fi

echo "检查Python环境..."
# 验证Python命令是否可用
case "$PYTHON_SOURCE" in
    "uv")
        if ! command -v uv >/dev/null 2>&1; then
            echo "错误: uv命令不可用"
            exit 1
        fi
        ;;
    *)
        if ! command -v "$PYTHON_CMD" >/dev/null 2>&1; then
            echo "错误: Python命令 $PYTHON_CMD 不可用"
            exit 1
        fi
        ;;
esac

echo "创建systemd服务文件..."

# 根据Python环境设置启动命令和环境变量
case "$PYTHON_SOURCE" in
    "uv")
        EXEC_START_CMD="uv run python main.py sse --host 0.0.0.0 --port 60"
        ENVIRONMENT_PATH="Environment=PATH=$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        ;;
    "conda")
        EXEC_START_CMD="$PYTHON_CMD main.py sse --host 0.0.0.0 --port 60"
        if [ -n "$CONDA_PREFIX" ]; then
            ENVIRONMENT_PATH="Environment=PATH=$CONDA_PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        else
            ENVIRONMENT_PATH="Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        fi
        ;;
    *)
        EXEC_START_CMD="$PYTHON_CMD main.py sse --host 0.0.0.0 --port 60"
        ENVIRONMENT_PATH="Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        ;;
esac

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

# 安全设置
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$WORK_DIR
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo "设置服务文件权限..."
chmod 644 "$SERVICE_FILE"

echo "重新加载systemd配置..."
systemctl daemon-reload

echo "启用服务（开机自启动）..."
systemctl enable "$SERVICE_NAME"

echo "启动服务..."
systemctl start "$SERVICE_NAME"

echo "等待服务启动..."
sleep 3

echo "检查服务状态..."
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ 服务安装并启动成功！"
    echo ""
    echo "=== 服务信息 ==="
    echo "服务名称: $SERVICE_NAME"
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):60"
    echo "状态页面: http://$(hostname -I | awk '{print $1}'):60/"
    echo "SSE端点: http://$(hostname -I | awk '{print $1}'):60/sse"
    echo ""
    echo "=== 常用命令 ==="
    echo "查看状态: systemctl status $SERVICE_NAME"
    echo "查看日志: journalctl -u $SERVICE_NAME -f"
    echo "重启服务: systemctl restart $SERVICE_NAME"
    echo "停止服务: systemctl stop $SERVICE_NAME"
    echo "禁用服务: systemctl disable $SERVICE_NAME"
    echo ""
    echo "=== 防火墙设置 ==="
    echo "开放端口: firewall-cmd --permanent --add-port=60/tcp && firewall-cmd --reload"
else
    echo "❌ 服务启动失败！"
    echo "查看错误日志: journalctl -u $SERVICE_NAME -n 20"
    systemctl status "$SERVICE_NAME"
    exit 1
fi
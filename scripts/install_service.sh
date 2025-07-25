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
PYTHON_PATH="/root/miniconda3/bin/python"

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
if [ ! -f "$PYTHON_PATH" ]; then
    echo "错误: Python路径 $PYTHON_PATH 不存在"
    echo "请修改脚本中的PYTHON_PATH变量"
    exit 1
fi

echo "创建systemd服务文件..."
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
Environment=PATH=/root/miniconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=$PYTHON_PATH main.py sse --host 0.0.0.0 --port 60
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
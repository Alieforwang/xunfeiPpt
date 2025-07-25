#!/bin/bash

# 讯飞智文PPT生成服务卸载脚本

set -e

echo "=== 讯飞智文PPT生成服务卸载脚本 ==="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用root权限运行此脚本"
    echo "使用方法: sudo bash uninstall_service.sh"
    exit 1
fi

SERVICE_NAME="ppt-mcp-sse"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "停止服务..."
if systemctl is-active --quiet "$SERVICE_NAME"; then
    systemctl stop "$SERVICE_NAME"
    echo "✅ 服务已停止"
else
    echo "ℹ️  服务未运行"
fi

echo "禁用服务（取消开机自启动）..."
if systemctl is-enabled --quiet "$SERVICE_NAME"; then
    systemctl disable "$SERVICE_NAME"
    echo "✅ 服务已禁用"
else
    echo "ℹ️  服务未启用"
fi

echo "删除服务文件..."
if [ -f "$SERVICE_FILE" ]; then
    rm -f "$SERVICE_FILE"
    echo "✅ 服务文件已删除"
else
    echo "ℹ️  服务文件不存在"
fi

echo "重新加载systemd配置..."
systemctl daemon-reload

echo "清理systemd缓存..."
systemctl reset-failed

echo "✅ 服务卸载完成！"
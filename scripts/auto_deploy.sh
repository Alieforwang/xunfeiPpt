#!/bin/bash

# 讯飞智文PPT服务跨平台自动部署脚本
# 自动适配不同系统环境

set -e

echo "=== 讯飞智文PPT服务跨平台自动部署脚本 ==="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 系统检测函数
detect_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$NAME
            VERSION=$VERSION_ID
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="MacOS"
        DISTRO="macOS"
        VERSION=$(sw_vers -productVersion)
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="Windows"
        DISTRO="Windows"
    else
        OS="Unknown"
        DISTRO="Unknown"
    fi
    
    log_info "检测到系统: $OS - $DISTRO $VERSION"
}

# 检查并转换文件编码
fix_file_encoding() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        return 0
    fi
    
    log_info "检查文件编码: $file_path"
    
    # 检查文件是否包含Windows换行符
    if file "$file_path" | grep -q "CRLF"; then
        log_warning "发现Windows换行符，正在转换..."
        
        # 尝试多种转换方法
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix "$file_path"
            log_success "使用dos2unix转换完成"
        elif command -v sed >/dev/null 2>&1; then
            sed -i 's/\r$//' "$file_path"
            log_success "使用sed转换完成"
        elif command -v tr >/dev/null 2>&1; then
            tr -d '\r' < "$file_path" > "${file_path}.tmp" && mv "${file_path}.tmp" "$file_path"
            log_success "使用tr转换完成"
        else
            log_error "无法找到文件格式转换工具"
            return 1
        fi
    else
        log_info "文件编码格式正确"
    fi
}

# Python环境检测和配置
setup_python_environment() {
    log_info "检测Python环境..."
    
    # 检测conda环境
    detect_conda_environment
    
    # 检测现有Python环境
    detect_existing_python
    
    # 如果没有合适的Python环境，尝试安装
    if [ -z "$PYTHON_CMD" ] || [ "$PYTHON_VERSION_OK" != "true" ]; then
        install_python_with_uv
    fi
    
    # 最终验证Python环境
    validate_python_environment
    
    # 选择最佳包管理器
    select_package_manager
}

# 检测conda环境
detect_conda_environment() {
    if command -v conda >/dev/null 2>&1; then
        log_info "检测到conda环境"
        CONDA_AVAILABLE="true"
        
        # 检查当前激活的conda环境
        if [ -n "$CONDA_DEFAULT_ENV" ]; then
            log_info "当前conda环境: $CONDA_DEFAULT_ENV"
            CURRENT_CONDA_ENV="$CONDA_DEFAULT_ENV"
        fi
        
        # 检查conda中的Python版本
        if command -v python >/dev/null 2>&1; then
            CONDA_PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2)
            log_info "conda Python版本: $CONDA_PYTHON_VERSION"
            
            # 检查是否为Python 3.13+
            CONDA_PYTHON_MAJOR=$(echo $CONDA_PYTHON_VERSION | cut -d'.' -f1)
            CONDA_PYTHON_MINOR=$(echo $CONDA_PYTHON_VERSION | cut -d'.' -f2)
            
            if [ "$CONDA_PYTHON_MAJOR" -eq 3 ] && [ "$CONDA_PYTHON_MINOR" -ge 13 ]; then
                log_success "conda Python版本满足要求(3.13+)"
                PYTHON_CMD="python"
                PIP_CMD="pip"
                PYTHON_VERSION="$CONDA_PYTHON_VERSION"
                PYTHON_VERSION_OK="true"
                PYTHON_SOURCE="conda"
                return 0
            else
                log_warning "conda Python版本($CONDA_PYTHON_VERSION)低于3.13"
            fi
        fi
    else
        CONDA_AVAILABLE="false"
    fi
}

# 检测现有Python环境
detect_existing_python() {
    log_info "检测系统Python环境..."
    
    # 按优先级检测Python命令
    for python_cmd in python3.13 python3.12 python3.11 python3.10 python3.9 python3.8 python3 python; do
        if command -v "$python_cmd" >/dev/null 2>&1; then
            DETECTED_PYTHON_VERSION=$("$python_cmd" --version 2>&1 | cut -d' ' -f2)
            DETECTED_PYTHON_MAJOR=$(echo $DETECTED_PYTHON_VERSION | cut -d'.' -f1)
            DETECTED_PYTHON_MINOR=$(echo $DETECTED_PYTHON_VERSION | cut -d'.' -f2)
            
            log_info "检测到: $python_cmd (版本: $DETECTED_PYTHON_VERSION)"
            
            # 检查是否为Python 3.x
            if [ "$DETECTED_PYTHON_MAJOR" -eq 3 ]; then
                if [ "$DETECTED_PYTHON_MINOR" -ge 13 ]; then
                    log_success "找到合适的Python版本: $DETECTED_PYTHON_VERSION"
                    PYTHON_CMD="$python_cmd"
                    PYTHON_VERSION="$DETECTED_PYTHON_VERSION"
                    PYTHON_VERSION_OK="true"
                    PYTHON_SOURCE="system"
                    
                    # 设置对应的pip命令
                    if [[ "$python_cmd" == "python3"* ]]; then
                        PIP_CMD="pip3"
                    else
                        PIP_CMD="pip"
                    fi
                    return 0
                else
                    log_warning "Python版本($DETECTED_PYTHON_VERSION)低于3.13"
                fi
            else
                log_warning "发现Python 2.x版本，跳过"
            fi
        fi
    done
    
    log_warning "未找到合适的Python 3.13+环境"
    PYTHON_VERSION_OK="false"
}

# 使用uv安装Python
install_python_with_uv() {
    if ! command -v uv >/dev/null 2>&1; then
        log_info "uv未安装，尝试安装uv..."
        install_uv
    fi
    
    if command -v uv >/dev/null 2>&1; then
        log_info "使用uv安装Python 3.13..."
        
        # 尝试安装Python 3.13
        if uv python install 3.13; then
            log_success "Python 3.13安装成功"
            
            # 验证安装的Python
            if uv python pin 3.13; then
                log_success "Python 3.13已设置为项目默认版本"
                PYTHON_CMD="uv run python"
                PIP_CMD="uv pip"
                PYTHON_VERSION="3.13"
                PYTHON_VERSION_OK="true"
                PYTHON_SOURCE="uv"
                return 0
            fi
        else
            log_warning "uv安装Python失败，将尝试其他方法"
        fi
    fi
    
    # 如果uv安装失败，提供安装建议
    if [ "$PYTHON_VERSION_OK" != "true" ]; then
        log_error "无法自动安装合适的Python环境"
        log_info "请手动安装Python 3.13+，或者："
        echo "  - 使用conda: conda install python=3.13"
        echo "  - 使用系统包管理器: yum install python3 或 apt install python3"
        echo "  - 从源码编译: https://www.python.org/downloads/"
        exit 1
    fi
}

# 安装uv
install_uv() {
    log_info "正在安装uv包管理器..."
    
    if command -v curl >/dev/null 2>&1; then
        if curl -LsSf https://astral.sh/uv/install.sh | sh; then
            log_success "uv安装成功"
            # 重新加载PATH
            export PATH="$HOME/.cargo/bin:$PATH"
            return 0
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -qO- https://astral.sh/uv/install.sh | sh; then
            log_success "uv安装成功"
            export PATH="$HOME/.cargo/bin:$PATH"
            return 0
        fi
    fi
    
    log_warning "uv自动安装失败"
    return 1
}

# 验证Python环境
validate_python_environment() {
    if [ -z "$PYTHON_CMD" ]; then
        log_error "Python环境配置失败"
        exit 1
    fi
    
    # 验证Python命令可用
    if ! command -v "$PYTHON_CMD" >/dev/null 2>&1 && [ "$PYTHON_SOURCE" != "uv" ]; then
        log_error "Python命令不可用: $PYTHON_CMD"
        exit 1
    fi
    
    # 显示最终选择的Python环境
    log_success "选择的Python环境:"
    log_info "  命令: $PYTHON_CMD"
    log_info "  版本: $PYTHON_VERSION"
    log_info "  来源: $PYTHON_SOURCE"
    
    # 测试Python环境
    if [ "$PYTHON_SOURCE" = "uv" ]; then
        log_info "测试uv Python环境..."
        if uv run python --version >/dev/null 2>&1; then
            log_success "uv Python环境测试通过"
        else
            log_error "uv Python环境测试失败"
            exit 1
        fi
    else
        log_info "测试Python环境..."
        if "$PYTHON_CMD" --version >/dev/null 2>&1; then
            log_success "Python环境测试通过"
        else
            log_error "Python环境测试失败"
            exit 1
        fi
    fi
}

# 选择包管理器
select_package_manager() {
    log_info "选择包管理器..."
    
    # 根据Python来源和版本选择包管理器
    if [ "$PYTHON_SOURCE" = "uv" ]; then
        PACKAGE_MANAGER="uv"
        log_success "使用uv作为包管理器"
    elif command -v uv >/dev/null 2>&1; then
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
        
        if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
            PACKAGE_MANAGER="uv"
            log_success "检测到uv，Python版本支持，使用uv"
        else
            PACKAGE_MANAGER="pip"
            log_warning "Python版本($PYTHON_VERSION)低于3.8，使用pip"
        fi
    else
        PACKAGE_MANAGER="pip"
        log_info "使用pip包管理器"
    fi
}

# 安装Python依赖
install_dependencies() {
    log_info "安装Python依赖..."
    
    local dependencies="mcp requests requests-toolbelt starlette uvicorn"
    
    case "$PACKAGE_MANAGER" in
        "uv")
            if [ "$PYTHON_SOURCE" = "uv" ]; then
                log_info "使用uv在项目环境中安装依赖..."
                uv add $dependencies
            else
                log_info "使用uv pip安装依赖..."
                uv pip install $dependencies
            fi
            ;;
        "pip")
            log_info "使用pip安装依赖..."
            if [ "$PYTHON_SOURCE" = "conda" ]; then
                # 在conda环境中使用pip
                pip install $dependencies
            else
                $PIP_CMD install $dependencies
            fi
            ;;
        *)
            log_error "未知的包管理器: $PACKAGE_MANAGER"
            exit 1
            ;;
    esac
    
    log_success "依赖安装完成"
    
    # 验证关键依赖是否安装成功
    verify_dependencies
}

# 验证依赖安装
verify_dependencies() {
    log_info "验证依赖安装..."
    
    local test_cmd
    if [ "$PYTHON_SOURCE" = "uv" ]; then
        test_cmd="uv run python -c"
    elif [ "$PACKAGE_MANAGER" = "uv" ]; then
        # 使用uv包管理器但非uv Python环境
        test_cmd="uv run --python $PYTHON_CMD python -c"
    else
        test_cmd="$PYTHON_CMD -c"
    fi
    
    # 检查关键依赖
    local dependencies=("mcp" "requests" "starlette" "uvicorn")
    local failed_deps=()
    
    for dep in "${dependencies[@]}"; do
        if $test_cmd "import $dep" 2>/dev/null; then
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

# 创建工作目录
setup_work_directory() {
    # 根据系统设置工作目录
    case "$OS" in
        "Linux")
            WORK_DIR="/www/wwwroot/xunfeiPpt"
            ;;
        "MacOS")
            WORK_DIR="$HOME/xunfeiPpt"
            ;;
        "Windows")
            WORK_DIR="/c/xunfeiPpt"
            ;;
        *)
            WORK_DIR="$HOME/xunfeiPpt"
            ;;
    esac
    
    log_info "创建工作目录: $WORK_DIR"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    
    log_success "工作目录创建完成"
}

# 修复main.py中的f-string兼容性问题
fix_python_compatibility() {
    local main_file="$WORK_DIR/main.py"
    
    if [ -f "$main_file" ]; then
        log_info "检查Python代码兼容性..."
        
        # Python 3.13+支持所有现代语法，只需验证语法正确性
        if $PYTHON_CMD -m py_compile "$main_file"; then
            log_success "Python代码语法检查通过"
        else
            log_error "Python代码语法检查失败"
            return 1
        fi
    fi
}

# 创建服务管理脚本
create_service_management() {
    log_info "创建服务管理脚本..."
    
    # 保存Python环境信息供服务管理脚本使用
    cat > "$WORK_DIR/.python_env" << EOF
PYTHON_CMD="$PYTHON_CMD"
PYTHON_VERSION="$PYTHON_VERSION"
PYTHON_SOURCE="$PYTHON_SOURCE"
PACKAGE_MANAGER="$PACKAGE_MANAGER"
EOF

    # 通用服务管理脚本
    cat > "$WORK_DIR/service_manager.sh" << 'SERVICE_MANAGER_EOF'
#!/bin/bash

# 服务管理脚本 - 跨平台
# 自动检测Python环境信息

SERVICE_NAME="ppt-mcp-sse"
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检测Python环境（简化版本，继承部署时的选择）
if [ -f "$WORK_DIR/.python_env" ]; then
    source "$WORK_DIR/.python_env"
else
    # 默认检测
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python"
    else
        echo "错误: 未找到Python环境"
        exit 1
    fi
    PYTHON_SOURCE="system"
fi

start_service() {
    echo "启动PPT MCP服务..."
    cd "$WORK_DIR"
    
    # 根据Python环境选择启动命令
    case "$PYTHON_SOURCE" in
        "uv")
            nohup uv run python main.py sse --host 0.0.0.0 --port 60 > service.log 2>&1 &
            ;;
        "conda")
            nohup python main.py sse --host 0.0.0.0 --port 60 > service.log 2>&1 &
            ;;
        *)
            nohup $PYTHON_CMD main.py sse --host 0.0.0.0 --port 60 > service.log 2>&1 &
            ;;
    esac
    
    echo $! > service.pid
    echo "服务已启动，PID: $(cat service.pid)"
    echo "日志文件: $WORK_DIR/service.log"
    echo "访问地址: http://localhost:60"
}

stop_service() {
    if [ -f "$WORK_DIR/service.pid" ]; then
        PID=$(cat "$WORK_DIR/service.pid")
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID
            echo "服务已停止 (PID: $PID)"
        else
            echo "服务进程不存在"
        fi
        rm -f "$WORK_DIR/service.pid"
    else
        echo "未找到服务PID文件"
    fi
}

status_service() {
    if [ -f "$WORK_DIR/service.pid" ]; then
        PID=$(cat "$WORK_DIR/service.pid")
        if ps -p $PID > /dev/null 2>&1; then
            echo "服务正在运行 (PID: $PID)"
            echo "访问地址: http://localhost:60"
        else
            echo "服务已停止"
        fi
    else
        echo "服务未启动"
    fi
}

restart_service() {
    echo "重启服务..."
    stop_service
    sleep 2
    start_service
}

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
    *)
        echo "使用方法: $0 {start|stop|restart|status}"
        echo ""
        echo "示例:"
        echo "  $0 start   - 启动服务"
        echo "  $0 stop    - 停止服务"
        echo "  $0 restart - 重启服务"
        echo "  $0 status  - 查看状态"
        exit 1
        ;;
esac
SERVICE_MANAGER_EOF

    chmod +x "$WORK_DIR/service_manager.sh"
    log_success "服务管理脚本创建完成"
}

# 系统服务配置（仅限Linux）
setup_system_service() {
    if [ "$OS" != "Linux" ]; then
        log_info "非Linux系统，跳过systemd服务配置"
        return 0
    fi
    
    if [ "$EUID" -ne 0 ]; then
        log_warning "需要root权限才能配置系统服务"
        log_info "可以稍后使用以下命令手动配置:"
        echo "sudo bash '$WORK_DIR/install_service.sh'"
        return 0
    fi
    
    log_info "配置systemd服务..."
    
    # 获取脚本所在目录的父目录（项目根目录）
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    
    # 修复安装脚本的编码问题
    if [ -f "$PROJECT_ROOT/scripts/install_service.sh" ]; then
        fix_file_encoding "$PROJECT_ROOT/scripts/install_service.sh"
        cp "$PROJECT_ROOT/scripts/install_service.sh" "$WORK_DIR/"
        chmod +x "$WORK_DIR/install_service.sh"
        
        # 运行安装脚本
        bash "$WORK_DIR/install_service.sh"
    else
        log_warning "未找到scripts/install_service.sh，将创建基本的systemd服务"
        create_basic_systemd_service
    fi
}

# 创建基本的systemd服务
create_basic_systemd_service() {
    local service_file="/etc/systemd/system/ppt-mcp-sse.service"
    
    # 根据Python环境设置ExecStart命令
    local exec_start_cmd
    local environment_vars="Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    
    case "$PYTHON_SOURCE" in
        "uv")
            exec_start_cmd="uv run python main.py sse --host 0.0.0.0 --port 60"
            # 添加uv路径到环境变量
            environment_vars="Environment=PATH=$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            ;;
        "conda")
            exec_start_cmd="$PYTHON_CMD main.py sse --host 0.0.0.0 --port 60"
            # 添加conda路径
            if [ -n "$CONDA_PREFIX" ]; then
                environment_vars="Environment=PATH=$CONDA_PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            fi
            ;;
        *)
            exec_start_cmd="$PYTHON_CMD main.py sse --host 0.0.0.0 --port 60"
            ;;
    esac
    
    cat > "$service_file" << EOF
[Unit]
Description=讯飞智文PPT生成服务MCP Server - SSE传输
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$WORK_DIR
$environment_vars
ExecStart=$exec_start_cmd
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ppt-mcp-sse
    systemctl start ppt-mcp-sse
    
    log_success "systemd服务配置完成"
}

# 测试服务
test_service() {
    log_info "测试服务..."
    
    # 等待服务启动
    sleep 3
    
    # 测试端口连接
    if command -v curl >/dev/null 2>&1; then
        if curl -s "http://localhost:60" > /dev/null; then
            log_success "服务测试通过 - http://localhost:60"
        else
            log_warning "服务可能未完全启动，请稍后手动测试"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --spider "http://localhost:60"; then
            log_success "服务测试通过 - http://localhost:60"
        else
            log_warning "服务可能未完全启动，请稍后手动测试"
        fi
    else
        log_info "无法测试服务连接，请手动访问 http://localhost:60"
    fi
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo "=== 部署完成 ==="
    echo ""
    log_success "系统信息: $OS - $DISTRO $VERSION"
    log_success "工作目录: $WORK_DIR"
    log_success "Python环境: $PYTHON_CMD"
    log_success "包管理器: $PACKAGE_MANAGER"
    echo ""
    echo "=== 访问信息 ==="
    echo "状态页面: http://localhost:60/"
    echo "SSE端点: http://localhost:60/sse"
    echo ""
    echo "=== 服务管理 ==="
    echo "通用管理: bash $WORK_DIR/service_manager.sh {start|stop|restart|status}"
    
    if [ "$OS" = "Linux" ] && [ -f "/etc/systemd/system/ppt-mcp-sse.service" ]; then
        echo "系统服务: systemctl {start|stop|restart|status} ppt-mcp-sse"
        echo "查看日志: journalctl -u ppt-mcp-sse -f"
    fi
    
    echo ""
    echo "=== 防火墙设置 ==="
    case "$OS" in
        "Linux")
            echo "开放端口: firewall-cmd --permanent --add-port=60/tcp && firewall-cmd --reload"
            echo "或者使用: ufw allow 60"
            ;;
        "MacOS")
            echo "macOS防火墙一般不需要额外配置"
            ;;
        *)
            echo "请根据系统配置防火墙开放60端口"
            ;;
    esac
    
    echo ""
    log_success "部署完成！请访问 http://localhost:60 测试服务"
}

# 主函数
main() {
    # 检测系统
    detect_system
    
    # 设置Python环境
    setup_python_environment
    
    # 创建工作目录
    setup_work_directory
    
    # 修复当前脚本的编码问题
    if [ -f "$0" ]; then
        fix_file_encoding "$0"
    fi
    
    # 安装依赖
    install_dependencies
    
    # 检查并复制main.py文件
    if [ ! -f "$WORK_DIR/main.py" ]; then
        log_info "main.py不存在，正在从项目根目录复制..."
        
        # 获取脚本所在目录的父目录（项目根目录）
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
        
        if [ -f "$PROJECT_ROOT/main.py" ]; then
            cp "$PROJECT_ROOT/main.py" "$WORK_DIR/"
            log_success "已从项目根目录复制main.py"
        else
            log_error "未找到main.py文件，请确保项目根目录包含main.py"
            exit 1
        fi
    fi
    
    # 修复Python兼容性
    fix_python_compatibility
    
    # 创建服务管理脚本
    create_service_management
    
    # 配置系统服务（Linux）
    setup_system_service
    
    # 测试服务
    test_service
    
    # 显示部署结果
    show_deployment_result
}

# 错误处理
trap 'log_error "部署过程中发生错误，退出码: $?"' ERR

# 执行主函数
main "$@"

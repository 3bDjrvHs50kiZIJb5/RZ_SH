
# 解析数据根目录 SCRIPT_DIR：优先 R_SH_HOME，其次 r.sh 所在目录，管道安装时用 pwd
# 所有 Compose / 备份 / 配置均建在 SCRIPT_DIR 下
resolve_script_dir() {
  local src="${BASH_SOURCE[0]}"
  local dir=""

  if [ -n "${R_SH_HOME:-}" ] && [ -d "$R_SH_HOME" ]; then
    dir="$(cd "$R_SH_HOME" && pwd)" 2>/dev/null || dir="$R_SH_HOME"
  fi

  if [ -n "$dir" ]; then
    printf '%s' "$dir"
    return 0
  fi

  if [ -n "${R_SH_SCRIPT:-}" ] && [ -f "$R_SH_SCRIPT" ]; then
    src="$R_SH_SCRIPT"
  fi

  case "$src" in
    /dev/fd/*|/dev/fd|/proc/self/fd|/proc/self/fd/*|/proc/*/fd/*)
      if command -v readlink >/dev/null 2>&1; then
        src="$(readlink -f "$src" 2>/dev/null || readlink "$src" 2>/dev/null || echo "$src")"
      fi
      ;;
  esac

  if command -v realpath >/dev/null 2>&1 && [ -e "$src" ]; then
    src="$(realpath "$src" 2>/dev/null || echo "$src")"
  elif command -v python3 >/dev/null 2>&1 && [ -e "$src" ]; then
    src="$(python3 -c 'import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))' "$src" 2>/dev/null || echo "$src")"
  fi

  if [ -n "$src" ] && [ -f "$src" ]; then
    dir="$(cd "$(dirname "$src")" && pwd)" 2>/dev/null || true
  fi

  case "$dir" in
    ""|/dev/fd|/dev/fd/*|/proc/self/fd|/proc/self/fd/*)
      if [ -n "${R_SH_SCRIPT:-}" ] && [ -f "${R_SH_SCRIPT}" ]; then
        dir="$(cd "$(dirname "$R_SH_SCRIPT")" && pwd)" 2>/dev/null || true
      fi
      if [ -z "$dir" ]; then
        dir="$(r_sh_default_home)"
      fi
      if [ ! -d "$dir" ] || [ ! -w "$dir" ]; then
        echo "错误: 无法定位 r.sh 所在目录（来源: ${BASH_SOURCE[0]}）" >&2
        echo "请 cd 到目标目录后运行，或使用: bash /path/to/r.sh" >&2
        echo "或设置: export R_SH_HOME=\$(pwd)" >&2
        echo "一键安装: bash <(curl -fsSL $R_SH_RAW_URL)" >&2
        exit 1
      fi
      ;;
  esac

  if ! mkdir -p "$dir" 2>/dev/null || [ ! -w "$dir" ]; then
    echo "错误: 脚本目录不可写: $dir" >&2
    exit 1
  fi

  printf '%s' "$dir"
}

SCRIPT_DIR="$(resolve_script_dir)"
export R_SH_HOME="$SCRIPT_DIR"

# 进入数据根目录，后续安装与相对路径均以此为准
if ! cd "$SCRIPT_DIR"; then
  echo "错误: 无法进入数据目录: $SCRIPT_DIR" >&2
  exit 1
fi
mkdir -p "$SCRIPT_DIR/tmp" "$SCRIPT_DIR/backups" 2>/dev/null || true

# 将相对路径解析到 SCRIPT_DIR 下
path_under_script_dir() {
  local p="$1"
  if [ -z "$p" ]; then
    printf '%s' "$SCRIPT_DIR"
    return 0
  fi
  case "$p" in
    /*) printf '%s' "$p" ;;
    *) printf '%s/%s' "$SCRIPT_DIR" "${p#./}" ;;
  esac
}

# 创建目录（Compose / 持久化数据用）
ensure_dir() {
  if ! mkdir -p "$@" 2>/dev/null; then
    echo "无法创建目录: $*" >&2
    echo "脚本目录: $SCRIPT_DIR" >&2
    return 1
  fi
}

# 转为绝对路径，供 docker-compose volumes 绑定
abs_path() {
  local p="$1"
  local parent="${p%/*}"
  local base="${p##*/}"

  if [ -z "$base" ] || [ "$parent" = "$p" ]; then
    ensure_dir "$p" || return 1
    (cd "$p" && pwd)
    return 0
  fi

  ensure_dir "$parent" || return 1
  printf '%s/%s' "$(cd "$parent" && pwd)" "$base"
}
NPM_DATA_DIR="${NPM_DATA_DIR:-$SCRIPT_DIR/npm-data}"
NPM_PORT="${NPM_PORT:-81}"
NPM_APP_PORT="${NPM_APP_PORT:-80}"
NPM_SSL_PORT="${NPM_SSL_PORT:-443}"
NPM_CONTAINER_NAME="${NPM_CONTAINER_NAME:-npm}"
CLI_PROXY_DIR="${CLI_PROXY_DIR:-$SCRIPT_DIR/cli-proxy-api}"
CLI_PROXY_IMAGE="${CLI_PROXY_IMAGE:-eceasy/cli-proxy-api:latest}"
CLI_PROXY_CONTAINER_NAME="${CLI_PROXY_CONTAINER_NAME:-cli-proxy-api}"
CLI_PROXY_CONFIG_PATH="${CLI_PROXY_CONFIG_PATH:-$CLI_PROXY_DIR/config.yaml}"
CLI_PROXY_AUTH_PATH="${CLI_PROXY_AUTH_PATH:-$CLI_PROXY_DIR/auths}"
CLI_PROXY_LOG_PATH="${CLI_PROXY_LOG_PATH:-$CLI_PROXY_DIR/logs}"
CLI_PROXY_PORTS="${CLI_PROXY_PORTS:-8317 8085 1455 54545 51121 11451}"
CLI_PROXY_PORT="${CLI_PROXY_PORT:-8317}"
CLI_PROXY_API_KEY="${CLI_PROXY_API_KEY:-change-me-to-your-api-key}"
CLI_PROXY_DEBUG="${CLI_PROXY_DEBUG:-false}"
CLI_PROXY_PROXY_URL="${CLI_PROXY_PROXY_URL:-}"
CLI_PROXY_COMPOSE_URL="${CLI_PROXY_COMPOSE_URL:-https://raw.githubusercontent.com/3bDjrvHs50kiZIJb5/RZ_SH/main/cli-proxy-api/docker-compose.yml}"
V2RAYA_DIR="${V2RAYA_DIR:-$SCRIPT_DIR/v2raya}"
V2RAYA_IMAGE="${V2RAYA_IMAGE:-mzz2017/v2raya:v2.2.6.4}"
V2RAYA_CONTAINER_NAME="${V2RAYA_CONTAINER_NAME:-v2raya}"
V2RAYA_PORT="${V2RAYA_PORT:-2017}"
V2RAYA_CONFIG_PATH="${V2RAYA_CONFIG_PATH:-$V2RAYA_DIR/config}"
V2RAY_AGENT_INSTALL_URL="${V2RAY_AGENT_INSTALL_URL:-https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh}"
SQLSERVER_DIR="${SQLSERVER_DIR:-$SCRIPT_DIR/sqlserver}"
SQLSERVER_IMAGE="${SQLSERVER_IMAGE:-mcr.microsoft.com/mssql/server:2022-latest}"
SQLSERVER_CONTAINER_NAME="${SQLSERVER_CONTAINER_NAME:-sqlserver}"
SQLSERVER_PORT="${SQLSERVER_PORT:-1433}"
SQLSERVER_DATA_PATH="${SQLSERVER_DATA_PATH:-$SQLSERVER_DIR/data}"
SQLSERVER_BACKUP_PATH="${SQLSERVER_BACKUP_PATH:-$SQLSERVER_DIR/backup}"
NGINX_STATIC_DIR="${NGINX_STATIC_DIR:-$SCRIPT_DIR/nginx-static}"
NGINX_STATIC_IMAGE="${NGINX_STATIC_IMAGE:-nginx:alpine}"
NGINX_STATIC_PORT="${NGINX_STATIC_PORT:-80}"
UPTIMENODE_DIR="${UPTIMENODE_DIR:-$SCRIPT_DIR/UptimeNode}"
UPTIMENODE_REPO="${UPTIMENODE_REPO:-https://github.com/3bDjrvHs50kiZIJb5/UptimeNode.git}"
UPTIMENODE_BRANCH="${UPTIMENODE_BRANCH:-main}"
UPTIMENODE_PORT="${UPTIMENODE_PORT:-6038}"
UPTIMENODE_PAGE_PASSWORD="${UPTIMENODE_PAGE_PASSWORD:-123456}"
UPTIMENODE_EMAIL_API_URL="${UPTIMENODE_EMAIL_API_URL:-http://localhost:3000/api/send-email}"
UPTIMENODE_EMAIL_API_KEY="${UPTIMENODE_EMAIL_API_KEY:-your-api-key}"
UPTIMENODE_EMAIL_TO="${UPTIMENODE_EMAIL_TO:-your-mail@example.com}"
UPTIMENODE_TELEGRAM_ENABLED="${UPTIMENODE_TELEGRAM_ENABLED:-false}"
UPTIMENODE_TELEGRAM_BOT_TOKEN="${UPTIMENODE_TELEGRAM_BOT_TOKEN:-}"
UPTIMENODE_TELEGRAM_CHAT_ID="${UPTIMENODE_TELEGRAM_CHAT_ID:-}"
SEND_EMAIL_DIR="${SEND_EMAIL_DIR:-$SCRIPT_DIR/SendEmail}"
SEND_EMAIL_REPO="${SEND_EMAIL_REPO:-https://github.com/3bDjrvHs50kiZIJb5/SendEmail.git}"
SEND_EMAIL_BRANCH="${SEND_EMAIL_BRANCH:-main}"
SEND_EMAIL_PORT="${SEND_EMAIL_PORT:-3000}"
SEND_EMAIL_API_KEY="${SEND_EMAIL_API_KEY:-change-me}"
SEND_EMAIL_FROM="${SEND_EMAIL_FROM:-noreply@example.com}"
SEND_EMAIL_TO="${SEND_EMAIL_TO:-your-mail@example.com}"
SEND_EMAIL_SMTP_HOST="${SEND_EMAIL_SMTP_HOST:-smtp.example.com}"
SEND_EMAIL_SMTP_PORT="${SEND_EMAIL_SMTP_PORT:-587}"
SEND_EMAIL_SMTP_USER="${SEND_EMAIL_SMTP_USER:-user@example.com}"
SEND_EMAIL_SMTP_PASS="${SEND_EMAIL_SMTP_PASS:-password}"

CODEX_MODEL_PROVIDER="${CODEX_MODEL_PROVIDER:-token}"
CODEX_BASE_URL="${CODEX_BASE_URL:-https://token.renzhe.org/v1}"
CODEX_MODEL="${CODEX_MODEL:-gpt-5.4-mini}"
CODEX_REASONING="${CODEX_REASONING:-medium}"
CODEX_DIR="${CODEX_DIR:-$SCRIPT_DIR/.codex}"
CODEX_CONFIG_FILE="${CODEX_CONFIG_FILE:-$CODEX_DIR/config.toml}"
CODEX_AUTH_FILE="${CODEX_AUTH_FILE:-$CODEX_DIR/auth.json}"

pause() {
  printf "\n按回车继续..."
  read -r _
}

print_header() {
  clear
  cat <<HEADER
==============================
  R_SH - 服务器运维脚本
==============================
数据目录: ${SCRIPT_DIR}
HEADER
}

run_privileged() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
    return $?
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
    return $?
  fi

  echo "需要 root 权限或 sudo 才能执行该操作。"
  return 1
}

start_docker_service() {
  if command -v systemctl >/dev/null 2>&1; then
    run_privileged systemctl enable --now docker >/dev/null 2>&1 || true
    run_privileged systemctl start docker >/dev/null 2>&1 || true
  elif command -v service >/dev/null 2>&1; then
    run_privileged service docker start >/dev/null 2>&1 || true
  fi
}

install_docker_by_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    run_privileged apt-get update
    run_privileged apt-get install -y ca-certificates curl gnupg
    if [ ! -f /etc/apt/keyrings/docker.gpg ] && command -v install >/dev/null 2>&1; then
      run_privileged install -m 0755 -d /etc/apt/keyrings
      run_privileged sh -c 'curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg'
      run_privileged chmod a+r /etc/apt/keyrings/docker.gpg
    fi
    run_privileged apt-get install -y docker.io docker-compose-plugin || run_privileged apt-get install -y docker.io
    return 0
  fi

  if command -v dnf >/dev/null 2>&1; then
    run_privileged dnf install -y dnf-plugins-core
    run_privileged dnf install -y docker docker-compose-plugin || run_privileged dnf install -y docker
    return 0
  fi

  if command -v yum >/dev/null 2>&1; then
    run_privileged yum install -y docker docker-compose-plugin || run_privileged yum install -y docker
    return 0
  fi

  if command -v pacman >/dev/null 2>&1; then
    run_privileged pacman -Sy --noconfirm docker docker-compose
    return 0
  fi

  if command -v apk >/dev/null 2>&1; then
    run_privileged apk add docker docker-cli-compose
    return 0
  fi

  if command -v zypper >/dev/null 2>&1; then
    run_privileged zypper --non-interactive install docker docker-compose
    return 0
  fi

  return 1
}

install_docker() {
  echo "未检测到 Docker，开始自动安装..."

  if command -v curl >/dev/null 2>&1; then
    if run_privileged sh -c 'curl -fsSL https://get.docker.com | sh'; then
      start_docker_service
      return 0
    fi
    echo "官方安装脚本执行失败，尝试使用系统包管理器安装。"
  elif command -v wget >/dev/null 2>&1; then
    if run_privileged sh -c 'wget -qO- https://get.docker.com | sh'; then
      start_docker_service
      return 0
    fi
    echo "官方安装脚本执行失败，尝试使用系统包管理器安装。"
  fi

  if install_docker_by_package_manager; then
    start_docker_service
    return 0
  fi

  echo "自动安装 Docker 失败，请手动安装后重试。"
  return 1
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    install_docker || return 1
  fi

  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker 安装后仍未找到命令，请检查环境。"
    return 1
  fi

  if ! docker info >/dev/null 2>&1; then
    start_docker_service
  fi

  if ! docker info >/dev/null 2>&1; then
    echo "Docker 服务不可用，请先启动 Docker 服务。"
    return 1
  fi
}

# Docker 基础管理：查看和操作容器。
docker_list_containers() {
  if ! require_docker; then
    return 0
  fi

  docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
}

docker_list_images() {
  if ! require_docker; then
    return 0
  fi

  docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}'
}

docker_prompt_container_name() {
  local container_name
  read -rp "请输入容器名: " container_name
  if [ -z "$container_name" ]; then
    echo "容器名不能为空。"
    return 1
  fi

  printf '%s' "$container_name"
}

docker_start_container() {
  if ! require_docker; then
    return 0
  fi

  local container_name
  container_name="$(docker_prompt_container_name)"
  docker start "$container_name"
}

docker_stop_container() {
  if ! require_docker; then
    return 0
  fi

  local container_name
  container_name="$(docker_prompt_container_name)"
  docker stop "$container_name"
}

docker_restart_container() {
  if ! require_docker; then
    return 0
  fi

  local container_name
  container_name="$(docker_prompt_container_name)"
  docker restart "$container_name"
}

docker_remove_container() {
  if ! require_docker; then
    return 0
  fi

  local container_name
  container_name="$(docker_prompt_container_name)"
  docker rm -f "$container_name"
}

docker_create_container() {
  if ! require_docker; then
    return 0
  fi

  local image_name container_name port_map volume_map
  read -rp "镜像名，例如 nginx:latest: " image_name
  read -rp "容器名: " container_name
  read -rp "端口映射，例如 8080:80（可留空）: " port_map
  read -rp "数据卷映射，例如 /data:/data（可留空）: " volume_map

  if [ -z "$image_name" ]; then
    echo "镜像名不能为空。"
    return 1
  fi

  if [ -z "$container_name" ]; then
    echo "容器名不能为空。"
    return 1
  fi

  if [ -n "$volume_map" ]; then
    mkdir -p "${volume_map%%:*}" 2>/dev/null || true
  fi

  local docker_args
  docker_args=(docker run -d --name "$container_name")

  if [ -n "$port_map" ]; then
    docker_args+=(-p "$port_map")
  fi

  if [ -n "$volume_map" ]; then
    docker_args+=(-v "$volume_map")
  fi

  docker_args+=("$image_name")
  "${docker_args[@]}"
}

docker_menu() {
  while true; do
    print_header
    echo "【Docker 概览：全部容器】"
    docker_list_containers
    printf "\n【Docker 概览：全部镜像】\n"
    docker_list_images
    printf "\n"
    cat <<'MENU'
【Docker 基础管理】
1. 查看容器列表
2. 启动容器
3. 停止容器
4. 重启容器
5. 删除容器
--------------------
6. CLIProxyAPI（Docker Compose）
7. V2RayA代理管理面板（Docker Compose）
8. SQL Server数据库服务（Docker Compose）
9. Nginx静态应用站（Docker Compose）
10. UptimeNode监控面板（Docker Compose）
11. SendEmail邮件服务（Docker Compose）
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        docker_list_containers
        pause
        ;;
      2)
        docker_start_container
        pause
        ;;
      3)
        docker_stop_container
        pause
        ;;
      4)
        docker_restart_container
        pause
        ;;
      5)
        docker_remove_container
        pause
        ;;
      6)
        cli_proxy_menu
        ;;
      7)
        v2raya_menu
        ;;
      8)
        sqlserver_menu
        ;;
      9)
        nginx_static_menu
        ;;
      10)
        uptimenode_menu
        ;;
      11)
        sendemail_menu
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

docker_compose_menu() {
  while true; do
    print_header
    cat <<'MENU'
【Docker Compose 服务】
--------------------
1. CLIProxyAPI（Docker Compose）
2. V2RayA代理管理面板（Docker Compose）
3. SQL Server数据库服务（Docker Compose）
4. Nginx静态应用站（Docker Compose）
5. UptimeNode监控面板（Docker Compose）
6. SendEmail邮件服务（Docker Compose）
0. 返回上级菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        cli_proxy_menu
        ;;
      2)
        v2raya_menu
        ;;
      3)
        sqlserver_menu
        ;;
      4)
        nginx_static_menu
        ;;
      5)
        uptimenode_menu
        ;;
      6)
        sendemail_menu
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

# Nginx Proxy Manager：安装和运行参数说明。
npm_install_hint() {
  cat <<EOF_HINT
Nginx Proxy Manager 说明：
1. 默认面板端口：$NPM_PORT
2. 默认 HTTP 端口：$NPM_APP_PORT
3. 默认 HTTPS 端口：$NPM_SSL_PORT
4. 默认数据目录：$NPM_DATA_DIR
EOF_HINT
}

detect_host_ip() {
  local ip_addr
  ip_addr="$(hostname -I 2>/dev/null | awk '{print $1}')"

  if [ -z "$ip_addr" ]; then
    ip_addr="服务器IP"
  fi

  printf '%s' "$ip_addr"
}

npm_show_address() {
  local ip_addr
  ip_addr="$(detect_host_ip)"

  echo "NPM 面板地址：http://$ip_addr:$NPM_PORT"
  echo "默认登录后请及时修改管理员账号和密码。"
}

npm_install() {
  if ! require_docker; then
    return 0
  fi

  ensure_dir "$NPM_DATA_DIR/data" "$NPM_DATA_DIR/letsencrypt" || return 1

  if docker ps -a --format '{{.Names}}' | grep -qx "$NPM_CONTAINER_NAME"; then
    echo "容器 $NPM_CONTAINER_NAME 已存在，跳过创建。"
    npm_show_address
    return 0
  fi

  docker run -d \
    --name "$NPM_CONTAINER_NAME" \
    -p "$NPM_PORT:81" \
    -p "$NPM_APP_PORT:80" \
    -p "$NPM_SSL_PORT:443" \
    -v "$NPM_DATA_DIR/data:/data" \
    -v "$NPM_DATA_DIR/letsencrypt:/etc/letsencrypt" \
    jc21/nginx-proxy-manager:latest

  npm_show_address
}

npm_start() {
  if ! require_docker; then
    return 0
  fi

  if ! docker ps -a --format '{{.Names}}' | grep -qx "$NPM_CONTAINER_NAME"; then
    echo "未发现容器 $NPM_CONTAINER_NAME，请先执行安装。"
    return 1
  fi

  docker start "$NPM_CONTAINER_NAME"
}

npm_stop() {
  if ! require_docker; then
    return 0
  fi

  docker stop "$NPM_CONTAINER_NAME"
}

# CLIProxyAPI：Docker Compose 安装与管理。
cli_proxy_port_list() {
  printf '%s' "$CLI_PROXY_PORTS"
}

# 首次安装时写入默认 config.yaml（已存在且非空则保留用户配置）。
cli_proxy_write_config() {
  ensure_dir "$CLI_PROXY_DIR" || return 1
  if [ -f "$CLI_PROXY_CONFIG_PATH" ] && [ -s "$CLI_PROXY_CONFIG_PATH" ]; then
    return 0
  fi

  cat > "$CLI_PROXY_CONFIG_PATH" <<EOF
port: ${CLI_PROXY_PORT}
auth-dir: "~/.cli-proxy-api"
debug: ${CLI_PROXY_DEBUG}
proxy-url: "${CLI_PROXY_PROXY_URL}"
api-keys:
  - "${CLI_PROXY_API_KEY}"
EOF
}

cli_proxy_download_compose() {
  local output_file="$1"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$CLI_PROXY_COMPOSE_URL" -o "$output_file"
    return $?
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$output_file" "$CLI_PROXY_COMPOSE_URL"
    return $?
  fi

  return 1
}

cli_proxy_write_compose_local() {
  local config_path auth_path log_path

  ensure_dir "$CLI_PROXY_DIR" "$CLI_PROXY_AUTH_PATH" "$CLI_PROXY_LOG_PATH" || return 1
  cli_proxy_write_config || return 1

  config_path="$(abs_path "$CLI_PROXY_CONFIG_PATH")" || return 1
  auth_path="$(abs_path "$CLI_PROXY_AUTH_PATH")" || return 1
  log_path="$(abs_path "$CLI_PROXY_LOG_PATH")" || return 1

  cat > "$CLI_PROXY_DIR/docker-compose.yml" <<EOF
services:
  cli-proxy-api:
    image: ${CLI_PROXY_IMAGE}
    pull_policy: always
    container_name: ${CLI_PROXY_CONTAINER_NAME}
    environment:
      DEPLOY: ${DEPLOY:-}
    ports:
      - "8317:8317"
      - "8085:8085"
      - "1455:1455"
      - "54545:54545"
      - "51121:51121"
      - "11451:11451"
    volumes:
      - ${config_path}:/CLIProxyAPI/config.yaml
      - ${auth_path}:/root/.cli-proxy-api
      - ${log_path}:/CLIProxyAPI/logs
    restart: unless-stopped
EOF
}

cli_proxy_write_compose() {
  local remote_compose="$CLI_PROXY_DIR/docker-compose.remote.yml"

  ensure_dir "$CLI_PROXY_DIR" "$CLI_PROXY_AUTH_PATH" "$CLI_PROXY_LOG_PATH" || return 1
  cli_proxy_write_config || return 1

  if cli_proxy_download_compose "$remote_compose"; then
    mv -f "$remote_compose" "$CLI_PROXY_DIR/docker-compose.yml"
  else
    rm -f "$remote_compose" 2>/dev/null || true
    cli_proxy_write_compose_local
  fi
}

cli_proxy_show_address() {
  local ip_addr
  ip_addr="$(detect_host_ip)"
  echo "CLIProxyAPI 默认访问地址："
  echo "- http://$ip_addr:8317"
  echo "- http://$ip_addr:8085"
  echo "- http://$ip_addr:1455"
  echo "- http://$ip_addr:54545"
  echo "- http://$ip_addr:51121"
  echo "- http://$ip_addr:11451"
}

cli_proxy_install() {
  if ! require_docker; then
    return 0
  fi

  echo "正在获取 CLIProxyAPI compose 文件..."
  cli_proxy_write_compose || return 1
  (cd "$CLI_PROXY_DIR" && docker compose up -d)
  cli_proxy_show_address
}

cli_proxy_start() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -f "$CLI_PROXY_DIR/docker-compose.yml" ]; then
    echo "未找到 CLIProxyAPI 的 compose 文件，请先安装。"
    return 1
  fi

  (cd "$CLI_PROXY_DIR" && docker compose up -d)
}

cli_proxy_stop() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -f "$CLI_PROXY_DIR/docker-compose.yml" ]; then
    echo "未找到 CLIProxyAPI 的 compose 文件，请先安装。"
    return 1
  fi

  (cd "$CLI_PROXY_DIR" && docker compose down)
}

cli_proxy_menu() {
  while true; do
    print_header
    cat <<'MENU'
【CLIProxyAPI】
1. 安装 / 更新 CLIProxyAPI（Docker Compose）
2. 启动 CLIProxyAPI
3. 停止 CLIProxyAPI
4. 查看访问地址
5. 查看安装参数
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        cli_proxy_install
        pause
        ;;
      2)
        cli_proxy_start
        pause
        ;;
      3)
        cli_proxy_stop
        pause
        ;;
      4)
        cli_proxy_show_address
        pause
        ;;
      5)
        echo "镜像：$CLI_PROXY_IMAGE"
        echo "容器名：$CLI_PROXY_CONTAINER_NAME"
        echo "配置目录：$CLI_PROXY_DIR"
        echo "配置文件：$CLI_PROXY_CONFIG_PATH"
        echo "认证目录：$CLI_PROXY_AUTH_PATH"
        echo "日志目录：$CLI_PROXY_LOG_PATH"
        echo "Compose 地址：$CLI_PROXY_COMPOSE_URL"
        echo "端口：$(cli_proxy_port_list)"
        echo "API 端口：$CLI_PROXY_PORT"
        echo "API Key：$CLI_PROXY_API_KEY"
        echo "Debug：$CLI_PROXY_DEBUG"
        echo "代理 URL：${CLI_PROXY_PROXY_URL:-（未设置）}"
        echo "API 端口：$CLI_PROXY_PORT"
        echo "API Key：$CLI_PROXY_API_KEY"
        echo "Debug：$CLI_PROXY_DEBUG"
        echo "代理 URL：${CLI_PROXY_PROXY_URL:-（未设置）}"
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}


# V2RayA：生成 compose 并提供面板入口。
v2raya_write_compose() {
  local config_path

  ensure_dir "$V2RAYA_DIR" "$V2RAYA_CONFIG_PATH" || return 1
  config_path="$(abs_path "$V2RAYA_CONFIG_PATH")" || return 1

  cat > "$V2RAYA_DIR/docker-compose.yml" <<EOF
services:
  v2raya:
    image: ${V2RAYA_IMAGE}
    container_name: ${V2RAYA_CONTAINER_NAME}
    restart: always
    privileged: true
    network_mode: host
    environment:
      V2RAYA_LOG_FILE: /tmp/v2raya.log
      V2RAYA_V2RAY_BIN: /usr/local/bin/v2ray
      V2RAYA_NFTABLES_SUPPORT: off
      IPTABLES_MODE: legacy
      V2RAYA_ADDRESS: 0.0.0.0:${V2RAYA_PORT}
    volumes:
      - /lib/modules:/lib/modules:ro
      - /etc/resolv.conf:/etc/resolv.conf
      - ${config_path}:/etc/v2raya
EOF
}

v2raya_show_address() {
  local ip_addr
  ip_addr="$(detect_host_ip)"
  echo "V2RayA 面板地址：http://$ip_addr:$V2RAYA_PORT"
}

v2raya_install() {
  if ! require_docker; then
    return 0
  fi

  v2raya_write_compose
  (cd "$V2RAYA_DIR" && docker compose up -d)
  v2raya_show_address
}

v2raya_start() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -f "$V2RAYA_DIR/docker-compose.yml" ]; then
    echo "未找到 V2RayA 的 compose 文件，请先安装。"
    return 1
  fi

  (cd "$V2RAYA_DIR" && docker compose up -d)
}

v2raya_stop() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -f "$V2RAYA_DIR/docker-compose.yml" ]; then
    echo "未找到 V2RayA 的 compose 文件，请先安装。"
    return 1
  fi

  (cd "$V2RAYA_DIR" && docker compose down)
}

v2raya_menu() {
  while true; do
    print_header
    cat <<'MENU'
【V2RayA 代理管理面板】
1. 安装 / 更新 V2RayA（Docker Compose）
2. 启动 V2RayA
3. 停止 V2RayA
4. 查看面板地址
5. 查看安装参数
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        v2raya_install
        pause
        ;;
      2)
        v2raya_start
        pause
        ;;
      3)
        v2raya_stop
        pause
        ;;
      4)
        v2raya_show_address
        pause
        ;;
      5)
        echo "镜像：$V2RAYA_IMAGE"
        echo "容器名：$V2RAYA_CONTAINER_NAME"
        echo "目录：$V2RAYA_DIR"
        echo "配置目录：$V2RAYA_CONFIG_PATH"
        echo "端口：$V2RAYA_PORT"
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

# SQL Server：生成 compose 并写入 SA 密码。
sqlserver_write_compose() {
  local sa_password data_path backup_path

  ensure_dir "$SQLSERVER_DIR" "$SQLSERVER_DATA_PATH" "$SQLSERVER_BACKUP_PATH" || return 1
  data_path="$(abs_path "$SQLSERVER_DATA_PATH")" || return 1
  backup_path="$(abs_path "$SQLSERVER_BACKUP_PATH")" || return 1
  if [ -n "${MSSQL_SA_PASSWORD:-}" ]; then
    sa_password="$MSSQL_SA_PASSWORD"
  else
    read -rsp "请输入 SQL Server SA 密码（至少 8 位，含大小写字母、数字和符号）: " sa_password
    echo
  fi

  if [ -z "$sa_password" ]; then
    echo "SA 密码不能为空。"
    return 1
  fi

  cat > "$SQLSERVER_DIR/.env" <<EOF_ENV
MSSQL_SA_PASSWORD=$sa_password
SQLSERVER_PORT=$SQLSERVER_PORT
EOF_ENV

  cat > "$SQLSERVER_DIR/docker-compose.yml" <<EOF
services:
  sqlserver:
    image: ${SQLSERVER_IMAGE}
    container_name: ${SQLSERVER_CONTAINER_NAME}
    restart: always
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: \\${MSSQL_SA_PASSWORD}
    ports:
      - "\\${SQLSERVER_PORT}:1433"
    volumes:
      - ${data_path}:/var/opt/mssql
      - ${backup_path}:/var/opt/mssql/backup
EOF
}

sqlserver_show_address() {
  local ip_addr
  ip_addr="$(detect_host_ip)"
  echo "SQL Server 地址：$ip_addr:$SQLSERVER_PORT"
}

sqlserver_install() {
  if ! require_docker; then
    return 0
  fi

  sqlserver_write_compose
  (cd "$SQLSERVER_DIR" && docker compose up -d)
  sqlserver_show_address
}

sqlserver_start() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -f "$SQLSERVER_DIR/docker-compose.yml" ]; then
    echo "未找到 SQL Server 的 compose 文件，请先安装。"
    return 1
  fi

  (cd "$SQLSERVER_DIR" && docker compose up -d)
}

sqlserver_stop() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -f "$SQLSERVER_DIR/docker-compose.yml" ]; then
    echo "未找到 SQL Server 的 compose 文件，请先安装。"
    return 1
  fi

  (cd "$SQLSERVER_DIR" && docker compose down)
}

sqlserver_menu() {
  while true; do
    print_header
    cat <<'MENU'
【SQL Server 数据库服务】
1. 安装 / 更新 SQL Server（Docker Compose）
2. 启动 SQL Server
3. 停止 SQL Server
4. 查看连接地址
5. 查看安装参数
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        sqlserver_install
        pause
        ;;
      2)
        sqlserver_start
        pause
        ;;
      3)
        sqlserver_stop
        pause
        ;;
      4)
        sqlserver_show_address
        pause
        ;;
      5)
        echo "镜像：$SQLSERVER_IMAGE"
        echo "容器名：$SQLSERVER_CONTAINER_NAME"
        echo "目录：$SQLSERVER_DIR"
        echo "数据目录：$SQLSERVER_DATA_PATH"
        echo "备份目录：$SQLSERVER_BACKUP_PATH"
        echo "端口：$SQLSERVER_PORT"
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

# Nginx 静态站点：按域名生成独立目录和 compose，容器名与域名保持一致。
nginx_static_prepare_site() {
  local domain_name container_name safe_name site_dir index_file host_port
  read -rp "请输入域名（同时作为容器名）: " domain_name
  if [ -z "$domain_name" ]; then
    echo "域名不能为空。"
    return 1
  fi

  container_name="$domain_name"

  read -rp "请输入对外端口（默认 80）: " host_port
  host_port="${host_port:-80}"

  safe_name="$domain_name"
  ensure_dir "$NGINX_STATIC_DIR" || return 1
  site_dir="$NGINX_STATIC_DIR/$safe_name"
  index_file="$site_dir/html/index.html"

  ensure_dir "$site_dir/html" || return 1
  if [ ! -f "$index_file" ]; then
    cat > "$index_file" <<EOF_INDEX
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$domain_name</title>
</head>
<body>
  <h1>$domain_name</h1>
  <p>这是由 R_SH 自动创建的 Nginx 静态站点。</p>
</body>
</html>
EOF_INDEX
  fi

  cat > "$site_dir/docker-compose.yml" <<EOF
services:
  nginx-static:
    image: ${NGINX_STATIC_IMAGE}
    container_name: ${container_name}
    restart: unless-stopped
    ports:
      - "${host_port}:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
EOF

  cat > "$site_dir/.env" <<EOF_ENV
HOST_PORT=$host_port
DOMAIN_NAME=$domain_name
EOF_ENV

  printf '%s\n' "$site_dir"
}

nginx_static_show_address() {
  local host_port ip_addr
  host_port="$1"
  ip_addr="$(detect_host_ip)"
  echo "静态站点地址：http://$ip_addr:$host_port"
}

nginx_static_install() {
  if ! require_docker; then
    return 0
  fi

  local site_dir host_port
  site_dir="$(nginx_static_prepare_site)" || return 1
  host_port="$(grep -oP '^HOST_PORT=\K.*' "$site_dir/.env" | tr -d '[:space:]')"
  (cd "$site_dir" && docker compose up -d)
  nginx_static_show_address "$host_port"
  echo "容器名：$(basename "$site_dir")"
}

nginx_static_start() {
  local site_dir
  read -rp "请输入站点目录（默认站点根: $NGINX_STATIC_DIR）: " site_dir
  site_dir="$(path_under_script_dir "${site_dir:-$NGINX_STATIC_DIR}")"
  if [ ! -f "$site_dir/docker-compose.yml" ]; then
    echo "未找到站点 compose 文件，请先安装。"
    return 1
  fi

  if ! require_docker; then
    return 0
  fi

  (cd "$site_dir" && docker compose up -d)
}

nginx_static_stop() {
  local site_dir
  read -rp "请输入站点目录（默认站点根: $NGINX_STATIC_DIR）: " site_dir
  site_dir="$(path_under_script_dir "${site_dir:-$NGINX_STATIC_DIR}")"
  if [ ! -f "$site_dir/docker-compose.yml" ]; then
    echo "未找到站点 compose 文件，请先安装。"
    return 1
  fi

  if ! require_docker; then
    return 0
  fi

  (cd "$site_dir" && docker compose down)
}



# UptimeNode：先拉取仓库，再生成配置并安装。
uptimenode_clone_repo() {
  ensure_dir "$SCRIPT_DIR" || return 1

  if [ -d "$UPTIMENODE_DIR/.git" ]; then
    (cd "$UPTIMENODE_DIR" && git pull --rebase)
    return 0
  fi

  rm -rf "$UPTIMENODE_DIR"
  git clone -b "$UPTIMENODE_BRANCH" "$UPTIMENODE_REPO" "$UPTIMENODE_DIR"
}

uptimenode_write_env() {
  cat > "$UPTIMENODE_DIR/.env" <<EOF
PORT=$UPTIMENODE_PORT
CHECK_INTERVAL_MS=60000
REQUEST_TIMEOUT_MS=10000
SSL_CHECK_TIMEOUT_MS=10000
FAILURE_THRESHOLD=3
EMAIL_FAILURE_THRESHOLD=10
TELEGRAM_ENABLED=$UPTIMENODE_TELEGRAM_ENABLED
TELEGRAM_BOT_TOKEN=$UPTIMENODE_TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$UPTIMENODE_TELEGRAM_CHAT_ID
EMAIL_API_URL=$UPTIMENODE_EMAIL_API_URL
EMAIL_API_KEY=$UPTIMENODE_EMAIL_API_KEY
EMAIL_TO=$UPTIMENODE_EMAIL_TO
PAGE_PASSWORD=$UPTIMENODE_PAGE_PASSWORD
EOF
}

uptimenode_show_address() {
  local ip_addr
  ip_addr="$(detect_host_ip)"
  echo "UptimeNode 访问地址：http://$ip_addr:$UPTIMENODE_PORT"
}

uptimenode_install() {
  if ! require_docker; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "未检测到 git，请先安装 git。"
    return 1
  fi

  uptimenode_clone_repo
  if [ -f "$UPTIMENODE_DIR/.env.example" ]; then
    cp "$UPTIMENODE_DIR/.env.example" "$UPTIMENODE_DIR/.env"
  fi
  ensure_dir "$UPTIMENODE_DIR/data" "$UPTIMENODE_DIR/logs" || return 1
  if [ -f "$UPTIMENODE_DIR/data/sites.json" ]; then
    :
  else
    cat > "$UPTIMENODE_DIR/data/sites.json" <<'JSON'
[]
JSON
  fi
  uptimenode_write_env
  if [ -f "$UPTIMENODE_DIR/docker-auto.sh" ]; then
    chmod +x "$UPTIMENODE_DIR/docker-auto.sh"
    (cd "$UPTIMENODE_DIR" && ./docker-auto.sh)
  else
    (cd "$UPTIMENODE_DIR" && docker compose down --remove-orphans || true && docker compose build && docker compose up -d)
  fi
  uptimenode_show_address
}

uptimenode_start() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -d "$UPTIMENODE_DIR/.git" ]; then
    echo "未找到 UptimeNode 仓库，请先安装。"
    return 1
  fi

  (cd "$UPTIMENODE_DIR" && docker compose up -d)
}

uptimenode_stop() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -d "$UPTIMENODE_DIR/.git" ]; then
    echo "未找到 UptimeNode 仓库，请先安装。"
    return 1
  fi

  (cd "$UPTIMENODE_DIR" && docker compose down)
}

uptimenode_menu() {
  while true; do
    print_header
    cat <<'MENU'
【UptimeNode 监控】
1. 克隆 / 更新并自动安装 UptimeNode
2. 启动 UptimeNode
3. 停止 UptimeNode
4. 查看访问地址
5. 查看安装参数
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        uptimenode_install
        pause
        ;;
      2)
        uptimenode_start
        pause
        ;;
      3)
        uptimenode_stop
        pause
        ;;
      4)
        uptimenode_show_address
        pause
        ;;
      5)
        echo "仓库：$UPTIMENODE_REPO"
        echo "分支：$UPTIMENODE_BRANCH"
        echo "目录：$UPTIMENODE_DIR"
        echo "端口：$UPTIMENODE_PORT"
        echo "页面密码：$UPTIMENODE_PAGE_PASSWORD"
        echo "邮件接口：$UPTIMENODE_EMAIL_API_URL"
        echo "邮件密钥：$UPTIMENODE_EMAIL_API_KEY"
        echo "通知邮箱：$UPTIMENODE_EMAIL_TO"
        echo "Telegram：$UPTIMENODE_TELEGRAM_ENABLED"
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

# SendEmail：先拉取仓库，再生成配置并安装。
sendemail_clone_repo() {
  ensure_dir "$SCRIPT_DIR" || return 1

  if [ -d "$SEND_EMAIL_DIR/.git" ]; then
    (cd "$SEND_EMAIL_DIR" && git pull --rebase)
    return 0
  fi

  rm -rf "$SEND_EMAIL_DIR"
  git clone -b "$SEND_EMAIL_BRANCH" "$SEND_EMAIL_REPO" "$SEND_EMAIL_DIR"
}

sendemail_write_env() {
  cat > "$SEND_EMAIL_DIR/.env" <<EOF
PORT=$SEND_EMAIL_PORT
API_KEY=$SEND_EMAIL_API_KEY
SMTP_HOST=$SEND_EMAIL_SMTP_HOST
SMTP_PORT=$SEND_EMAIL_SMTP_PORT
SMTP_USER=$SEND_EMAIL_SMTP_USER
SMTP_PASS=$SEND_EMAIL_SMTP_PASS
EMAIL_FROM=$SEND_EMAIL_FROM
EMAIL_TO=$SEND_EMAIL_TO
EOF
}

sendemail_compose_file() {
  local compose_file
  for compose_file in \
    "$SEND_EMAIL_DIR/docker-compose.yml" \
    "$SEND_EMAIL_DIR/docker-compose.yaml" \
    "$SEND_EMAIL_DIR/compose.yml" \
    "$SEND_EMAIL_DIR/compose.yaml"
  do
    if [ -f "$compose_file" ]; then
      printf '%s' "$compose_file"
      return 0
    fi
  done

  return 1
}

sendemail_install() {
  if ! require_docker; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "未检测到 git，请先安装 git。"
    return 1
  fi

  sendemail_clone_repo
  if [ -f "$SEND_EMAIL_DIR/.env" ]; then
    echo "已发现本地 .env，跳过写入。"
  elif [ -f "$SEND_EMAIL_DIR/.env.example" ]; then
    cp "$SEND_EMAIL_DIR/.env.example" "$SEND_EMAIL_DIR/.env"
  else
    sendemail_write_env
  fi
  local compose_file
  compose_file="$(sendemail_compose_file)" || {
    echo "仓库中未找到 docker-compose.yml / docker-compose.yaml / compose.yml / compose.yaml，请先检查仓库内容。"
    return 1
  }
  (cd "$SEND_EMAIL_DIR" && docker compose -f "$compose_file" up -d --build)
  echo "SendEmail 已启动。"
}

sendemail_start() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -d "$SEND_EMAIL_DIR/.git" ]; then
    echo "未找到 SendEmail 仓库，请先安装。"
    return 1
  fi

  local compose_file
  compose_file="$(sendemail_compose_file)" || {
    echo "未找到 SendEmail 的 compose 文件。"
    return 1
  }

  (cd "$SEND_EMAIL_DIR" && docker compose -f "$compose_file" up -d)
}

sendemail_stop() {
  if ! require_docker; then
    return 0
  fi

  if [ ! -d "$SEND_EMAIL_DIR/.git" ]; then
    echo "未找到 SendEmail 仓库，请先安装。"
    return 1
  fi

  local compose_file
  compose_file="$(sendemail_compose_file)" || {
    echo "未找到 SendEmail 的 compose 文件。"
    return 1
  }

  (cd "$SEND_EMAIL_DIR" && docker compose -f "$compose_file" down)
}

sendemail_menu() {
  while true; do
    print_header
    cat <<'MENU'
【SendEmail 邮件服务】
1. 克隆 / 更新并自动安装 SendEmail
2. 启动 SendEmail
3. 停止 SendEmail
4. 查看安装参数
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        sendemail_install
        pause
        ;;
      2)
        sendemail_start
        pause
        ;;
      3)
        sendemail_stop
        pause
        ;;
      4)
        echo "仓库：$SEND_EMAIL_REPO"
        echo "分支：$SEND_EMAIL_BRANCH"
        echo "目录：$SEND_EMAIL_DIR"
        echo "端口：$SEND_EMAIL_PORT"
        echo "API Key：$SEND_EMAIL_API_KEY"
        echo "发件人：$SEND_EMAIL_FROM"
        echo "收件人：$SEND_EMAIL_TO"
        echo "SMTP：$SEND_EMAIL_SMTP_HOST:$SEND_EMAIL_SMTP_PORT"
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}
nginx_static_menu() {
  while true; do
    print_header
    cat <<'MENU'
【Nginx 静态应用站】
1. 安装 / 更新静态站点
2. 启动静态站点
3. 停止静态站点
4. 查看安装参数
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        nginx_static_install
        pause
        ;;
      2)
        nginx_static_start
        pause
        ;;
      3)
        nginx_static_stop
        pause
        ;;
      4)
        echo "镜像：$NGINX_STATIC_IMAGE"
        echo "默认站点目录：$NGINX_STATIC_DIR"
        echo "端口：$NGINX_STATIC_PORT"
        echo "容器名规则：输入的域名"
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

site_management_menu() {
  while true; do
    print_header
    cat <<'MENU'
【NPM站点反代管理】
1. 查看 NPM 后端管理地址
2. 安装 NPM
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        if docker ps -a --format '{{.Names}}' | grep -qx "$NPM_CONTAINER_NAME"; then
          npm_show_address
        else
          echo "未发现 NPM 容器，先执行安装。"
          npm_install
        fi
        pause
        ;;
      2)
        npm_install
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

backup_dir="${BACKUP_DIR:-$SCRIPT_DIR/backups}"

ensure_backup_dir() {
  mkdir -p "$backup_dir"
}

# 备份 / 还原 / 删除：处理 Docker 项目和目录。
docker_backup_project() {
  ensure_backup_dir
  local source_dir archive_name timestamp archive_path
  read -rp "请输入项目目录（默认: $SCRIPT_DIR）: " source_dir
  source_dir="$(path_under_script_dir "${source_dir:-$SCRIPT_DIR}")"

  if [ ! -d "$source_dir" ]; then
    echo "项目目录不存在。"
    return 1
  fi

  timestamp="$(date +%Y%m%d_%H%M%S)"
  archive_name="$(basename "$source_dir")_${timestamp}.tar.gz"
  archive_path="$backup_dir/$archive_name"
  tar -czf "$archive_path" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
  echo "备份完成：$archive_path"
}

docker_restore_project() {
  local archive_path target_dir
  read -rp "请输入备份文件（可填相对路径，目录: $backup_dir）: " archive_path
  if [ -z "$archive_path" ]; then
    echo "备份文件不能为空。"
    return 1
  fi
  archive_path="$(path_under_script_dir "$archive_path")"
  if [ ! -f "$archive_path" ]; then
    echo "备份文件不存在。"
    return 1
  fi

  read -rp "请输入恢复目标目录（默认: $SCRIPT_DIR）: " target_dir
  target_dir="$(path_under_script_dir "${target_dir:-$SCRIPT_DIR}")"
  mkdir -p "$target_dir"
  tar -xzf "$archive_path" -C "$target_dir"
  echo "恢复完成。"
}

docker_delete_project() {
  local project_dir confirm
  read -rp "请输入要删除的项目目录（相对路径基于 $SCRIPT_DIR）: " project_dir
  if [ -z "$project_dir" ]; then
    echo "项目目录不能为空。"
    return 1
  fi
  project_dir="$(path_under_script_dir "$project_dir")"

  if [ "$project_dir" = "$SCRIPT_DIR" ]; then
    read -rp "将删除整个数据目录，确认请输入 DELETE: " confirm
    if [ "$confirm" != "DELETE" ]; then
      echo "已取消。"
      return 1
    fi
  fi

  if [ ! -e "$project_dir" ]; then
    echo "项目目录不存在。"
    return 1
  fi

  rm -rf "$project_dir"
  echo "已删除：$project_dir"
}

system_update() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "系统更新建议使用 root 执行。"
    return 1
  fi

  if command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get upgrade -y
  elif command -v dnf >/dev/null 2>&1; then
    dnf upgrade -y
  elif command -v yum >/dev/null 2>&1; then
    yum update -y
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Syu --noconfirm
  else
    echo "未识别到可用的包管理器。"
    return 1
  fi
}

cron_manage() {
  while true; do
    print_header
    cat <<'MENU'
【Crontab 管理】
1. 查看当前用户定时任务
2. 编辑当前用户定时任务
3. 清空当前用户定时任务
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        crontab -l || echo "当前没有定时任务。"
        pause
        ;;
      2)
        crontab -e
        ;;
      3)
        crontab -r
        echo "已清空当前用户定时任务。"
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

swap_setup() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "swap 调整建议使用 root 执行。"
    return 1
  fi

  local swap_size swap_file
  read -rp "请输入 swap 大小（单位 GB，例如 2）：" swap_size
  if [ -z "$swap_size" ]; then
    echo "swap 大小不能为空。"
    return 1
  fi

  swap_file="/swapfile"
  fallocate -l "${swap_size}G" "$swap_file" || dd if=/dev/zero of="$swap_file" bs=1G count="$swap_size"
  chmod 600 "$swap_file"
  mkswap "$swap_file"
  swapon "$swap_file"
  if ! grep -q '^/swapfile ' /etc/fstab 2>/dev/null; then
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
  fi
  echo "swap 已创建：$swap_file"
}

timezone_change() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "时区调整建议使用 root 执行。"
    return 1
  fi

  local timezone
  read -rp "请输入时区，例如 Asia/Shanghai：" timezone
  if [ -z "$timezone" ]; then
    echo "时区不能为空。"
    return 1
  fi

  timedatectl set-timezone "$timezone"
  timedatectl status
}

ssh_port_change() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "SSH 端口修改建议使用 root 执行。"
    return 1
  fi

  local ssh_port sshd_config
  read -rp "请输入新的 SSH 端口：" ssh_port
  if [ -z "$ssh_port" ]; then
    echo "SSH 端口不能为空。"
    return 1
  fi

  sshd_config="/etc/ssh/sshd_config"
  if [ ! -f "$sshd_config" ]; then
    echo "未找到 sshd 配置文件。"
    return 1
  fi

  cp "$sshd_config" "${sshd_config}.bak"
  if grep -q '^#*Port ' "$sshd_config"; then
    sed -i "s/^#*Port .*/Port ${ssh_port}/" "$sshd_config"
  else
    echo "Port ${ssh_port}" >> "$sshd_config"
  fi
  systemctl restart sshd || systemctl restart ssh
  echo "SSH 端口已修改为：$ssh_port"
}

server_maintenance_menu() {
  while true; do
    print_header
    cat <<'MENU'
【服务器基础维护】
1. 系统更新
2. Crontab 管理
3. Swap 虚拟内存调整
4. 时区切换
5. SSH 端口更改
6. 快捷键注册 / 删除（r命令）
7. DNS 优化
8. 时区/语言切换
9. Nginx Proxy Manager
10. CodeX CLI(API)
11. V2Ray-Agent安装脚本
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        system_update
        pause
        ;;
      2)
        cron_manage
        ;;
      3)
        swap_setup
        pause
        ;;
      4)
        timezone_change
        pause
        ;;
      5)
        ssh_port_change
        pause
        ;;
      6)
        shortcut_r_menu
        ;;
      7)
        dns_optimize_menu
        ;;
      8)
        timezone_language_menu
        ;;
      9)
        npm_menu
        ;;
      10)
        codex_cli_menu
        ;;
      11)
        v2ray_agent_menu
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

npm_menu() {
  while true; do
    print_header
    cat <<'MENU'
【Nginx Proxy Manager】
1. 安装 NPM
2. 启动 NPM
3. 停止 NPM
4. 查看面板地址
5. 查看安装参数
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        npm_install
        pause
        ;;
      2)
        npm_start
        pause
        ;;
      3)
        npm_stop
        pause
        ;;
      4)
        npm_show_address
        pause
        ;;
      5)
        npm_install_hint
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}


security_state_dir="${SECURITY_STATE_DIR:-$SCRIPT_DIR/security-state}"
NGINX_SECURITY_CONF="${NGINX_SECURITY_CONF:-/etc/nginx/conf.d/r_sh_security.conf}"
NGINX_SECURITY_BACKUP_DIR="${NGINX_SECURITY_BACKUP_DIR:-$SCRIPT_DIR/security-backup}"

ensure_security_dirs() {
  mkdir -p "$security_state_dir" "$NGINX_SECURITY_BACKUP_DIR"
}

reload_nginx_if_possible() {
  if ! command -v nginx >/dev/null 2>&1; then
    echo "未检测到 Nginx，已保存配置文件，但没有执行重载。"
    return 0
  fi

  if ! run_privileged nginx -t >/dev/null 2>&1; then
    echo "Nginx 配置检查失败，请先检查刚生成的配置。"
    return 1
  fi

  if command -v systemctl >/dev/null 2>&1; then
    run_privileged systemctl reload nginx >/dev/null 2>&1 || run_privileged nginx -s reload >/dev/null 2>&1 || true
  else
    run_privileged nginx -s reload >/dev/null 2>&1 || true
  fi
}

write_nginx_security_conf() {
  local content target_dir
  content="$1"
  target_dir="$(dirname "$NGINX_SECURITY_CONF")"
  run_privileged mkdir -p "$target_dir"
  printf '%s\n' "$content" | run_privileged tee "$NGINX_SECURITY_CONF" >/dev/null
  echo "已写入 Nginx 安全配置：$NGINX_SECURITY_CONF"
}

remove_nginx_security_conf() {
  if [ -f "$NGINX_SECURITY_CONF" ]; then
    run_privileged rm -f "$NGINX_SECURITY_CONF"
    echo "已移除配置：$NGINX_SECURITY_CONF"
  else
    echo "未找到配置文件：$NGINX_SECURITY_CONF"
  fi
}


# 快捷键注册 / 删除：把 r / R 命令写入 shell 启动文件。
shortcut_r_detect_shell_rc() {
  local rc_file
  case "${SHELL:-}" in
    */zsh) rc_file="$HOME/.zshrc" ;;
    */bash) rc_file="$HOME/.bashrc" ;;
    *)
      if [ -f "$HOME/.zshrc" ]; then
        rc_file="$HOME/.zshrc"
      else
        rc_file="$HOME/.bashrc"
      fi
      ;;
  esac
  printf '%s' "$rc_file"
}

shortcut_r_script_path() {
  printf '%s' "$SCRIPT_DIR/r.sh"
}

shortcut_r_block() {
  local script_path
  script_path="$(shortcut_r_script_path)"
  cat <<EOF
# R_SH 快捷启动
alias r='bash "$script_path"'
alias R='bash "$script_path"'
EOF
}

shortcut_r_register() {
  local rc_file block
  rc_file="$(shortcut_r_detect_shell_rc)"
  block="$(shortcut_r_block)"

  if [ ! -f "$rc_file" ]; then
    touch "$rc_file"
  fi

  if grep -q 'R_SH 快捷启动' "$rc_file" 2>/dev/null; then
    echo "快捷启动已经存在于：$rc_file"
    return 0
  fi

  printf '\n%s\n' "$block" >> "$rc_file"
  echo "已写入快捷启动到：$rc_file"
  echo "请执行：source $rc_file 或重新打开终端后生效。"
}

shortcut_r_remove() {
  local rc_file tmp_file
  rc_file="$(shortcut_r_detect_shell_rc)"
  tmp_file="${rc_file}.tmp"

  if [ ! -f "$rc_file" ]; then
    echo "未找到启动配置文件：$rc_file"
    return 1
  fi

  awk '
    BEGIN { skip = 0 }
    /^# R_SH 快捷启动$/ { skip = 1; next }
    skip == 1 && /^alias r=/{ next }
    skip == 1 && /^alias R=/{ skip = 0; next }
    { print }
  ' "$rc_file" > "$tmp_file"
  mv "$tmp_file" "$rc_file"
  echo "已删除快捷启动配置：$rc_file"
  echo "请执行：source $rc_file 或重新打开终端后生效。"
}

shortcut_r_status() {
  local rc_file
  rc_file="$(shortcut_r_detect_shell_rc)"
  echo "当前检测的启动文件：$rc_file"
  if grep -q 'R_SH 快捷启动' "$rc_file" 2>/dev/null; then
    echo "状态：已注册"
  else
    echo "状态：未注册"
  fi
}

shortcut_r_menu() {
  while true; do
    print_header
    cat <<'MENU'
【快捷键注册 / 删除（r 命令）】
1. 注册 r / R 命令
2. 删除 r / R 命令
3. 查看当前状态
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        shortcut_r_register
        pause
        ;;
      2)
        shortcut_r_remove
        pause
        ;;
      3)
        shortcut_r_status
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

# 网站防护 / 安全：统一识别可用的防火墙后端。
firewall_backend() {
  if command -v ufw >/dev/null 2>&1; then
    echo "ufw"
    return 0
  fi

  if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld >/dev/null 2>&1; then
    echo "firewalld"
    return 0
  fi

  if command -v iptables >/dev/null 2>&1; then
    echo "iptables"
    return 0
  fi

  echo "none"
}

firewall_list_rules() {
  local backend
  backend="$(firewall_backend)"

  case "$backend" in
    ufw)
      run_privileged ufw status verbose
      ;;
    firewalld)
      run_privileged firewall-cmd --list-all
      ;;
    iptables)
      run_privileged iptables -S
      ;;
    *)
      echo "未检测到可用的防火墙管理工具。"
      return 1
      ;;
  esac
}

firewall_open_port() {
  local port protocol backend
  read -rp "请输入端口号: " port
  read -rp "请输入协议（tcp/udp，默认 tcp）: " protocol
  protocol="${protocol:-tcp}"

  if [ -z "$port" ]; then
    echo "端口不能为空。"
    return 1
  fi

  backend="$(firewall_backend)"
  case "$backend" in
    ufw)
      run_privileged ufw allow "${port}/${protocol}"
      ;;
    firewalld)
      run_privileged firewall-cmd --permanent --add-port="${port}/${protocol}"
      run_privileged firewall-cmd --reload
      ;;
    iptables)
      run_privileged iptables -I INPUT -p "$protocol" --dport "$port" -j ACCEPT
      echo "iptables 规则已添加，若需要持久化请自行保存规则。"
      ;;
    *)
      echo "未检测到可用的防火墙管理工具。"
      return 1
      ;;
  esac
}

firewall_close_port() {
  local port protocol backend
  read -rp "请输入端口号: " port
  read -rp "请输入协议（tcp/udp，默认 tcp）: " protocol
  protocol="${protocol:-tcp}"

  if [ -z "$port" ]; then
    echo "端口不能为空。"
    return 1
  fi

  backend="$(firewall_backend)"
  case "$backend" in
    ufw)
      run_privileged ufw delete allow "${port}/${protocol}"
      ;;
    firewalld)
      run_privileged firewall-cmd --permanent --remove-port="${port}/${protocol}"
      run_privileged firewall-cmd --reload
      ;;
    iptables)
      run_privileged iptables -D INPUT -p "$protocol" --dport "$port" -j ACCEPT || true
      echo "iptables 规则已尝试删除。"
      ;;
    *)
      echo "未检测到可用的防火墙管理工具。"
      return 1
      ;;
  esac
}

firewall_menu() {
  while true; do
    print_header
    cat <<'MENU'
【防火墙端口管理】
1. 查看防火墙规则
2. 放行端口
3. 关闭端口
0. 返回上级菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        firewall_list_rules
        pause
        ;;
      2)
        firewall_open_port
        pause
        ;;
      3)
        firewall_close_port
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

ip_acl_list_rules() {
  local backend
  backend="$(firewall_backend)"

  case "$backend" in
    ufw)
      run_privileged ufw status numbered
      ;;
    firewalld)
      run_privileged firewall-cmd --list-rich-rules
      ;;
    iptables)
      run_privileged iptables -S INPUT | awk '/-s / {print}'
      ;;
    *)
      echo "未检测到可用的防火墙管理工具。"
      return 1
      ;;
  esac
}

ip_allow_rule() {
  local ip_addr backend
  read -rp "请输入要放行的 IP: " ip_addr
  if [ -z "$ip_addr" ]; then
    echo "IP 不能为空。"
    return 1
  fi

  backend="$(firewall_backend)"
  case "$backend" in
    ufw)
      run_privileged ufw allow from "$ip_addr" to any
      ;;
    firewalld)
      run_privileged firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip_addr' accept"
      run_privileged firewall-cmd --reload
      ;;
    iptables)
      run_privileged iptables -I INPUT -s "$ip_addr" -j ACCEPT
      echo "iptables 规则已添加，若需要持久化请自行保存规则。"
      ;;
    *)
      echo "未检测到可用的防火墙管理工具。"
      return 1
      ;;
  esac
}

ip_block_rule() {
  local ip_addr backend
  read -rp "请输入要禁止的 IP: " ip_addr
  if [ -z "$ip_addr" ]; then
    echo "IP 不能为空。"
    return 1
  fi

  backend="$(firewall_backend)"
  case "$backend" in
    ufw)
      run_privileged ufw deny from "$ip_addr" to any
      ;;
    firewalld)
      run_privileged firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip_addr' drop"
      run_privileged firewall-cmd --reload
      ;;
    iptables)
      run_privileged iptables -I INPUT -s "$ip_addr" -j DROP
      echo "iptables 规则已添加，若需要持久化请自行保存规则。"
      ;;
    *)
      echo "未检测到可用的防火墙管理工具。"
      return 1
      ;;
  esac
}

ip_acl_menu() {
  while true; do
    print_header
    cat <<'MENU'
【IP 黑白名单】
1. 查看 IP 规则
2. 放行 IP
3. 禁止 IP
0. 返回上级菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        ip_acl_list_rules
        pause
        ;;
      2)
        ip_allow_rule
        pause
        ;;
      3)
        ip_block_rule
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

fetch_cloudflare_ips() {
  local output_file url
  output_file="$1"
  url="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$output_file"
    return $?
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$output_file" "$url"
    return $?
  fi

  return 1
}

cloudflare_conf_content() {
  local v4_file v6_file content
  v4_file="$security_state_dir/cloudflare-ips-v4.txt"
  v6_file="$security_state_dir/cloudflare-ips-v6.txt"

  if ! fetch_cloudflare_ips "$v4_file" 'https://www.cloudflare.com/ips-v4'; then
    if [ ! -f "$v4_file" ]; then
      echo "无法获取 Cloudflare IPv4 段，也没有本地缓存。"
      return 1
    fi
  fi

  if ! fetch_cloudflare_ips "$v6_file" 'https://www.cloudflare.com/ips-v6'; then
    if [ ! -f "$v6_file" ]; then
      echo "无法获取 Cloudflare IPv6 段，也没有本地缓存。"
      return 1
    fi
  fi

  {
    echo '# R_SH Cloudflare 模式'
    echo 'real_ip_header CF-Connecting-IP;'
    echo 'real_ip_recursive on;'
    while IFS= read -r line; do
      [ -n "$line" ] && echo "set_real_ip_from $line;"
    done < "$v4_file"
    while IFS= read -r line; do
      [ -n "$line" ] && echo "set_real_ip_from $line;"
    done < "$v6_file"
  }
}

waf_conf_content() {
  cat <<'EOF_WAF'
# R_SH WAF 基础防护
server_tokens off;
add_header X-Frame-Options SAMEORIGIN always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy strict-origin-when-cross-origin always;
EOF_WAF
}

enable_waf_mode() {
  ensure_security_dirs
  waf_conf_content | write_nginx_security_conf /dev/stdin
  reload_nginx_if_possible
}

enable_cloudflare_mode() {
  ensure_security_dirs
  cloudflare_conf_content | write_nginx_security_conf /dev/stdin
  reload_nginx_if_possible
}

disable_security_mode() {
  remove_nginx_security_conf
  reload_nginx_if_possible
}

security_mode_menu() {
  while true; do
    print_header
    cat <<'MENU'
【WAF / Cloudflare 模式】
1. 启用 WAF 基础防护
2. 启用 Cloudflare 模式
3. 关闭当前安全配置
4. 查看安全配置文件
0. 返回上级菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        enable_waf_mode
        pause
        ;;
      2)
        enable_cloudflare_mode
        pause
        ;;
      3)
        disable_security_mode
        pause
        ;;
      4)
        if [ -f "$NGINX_SECURITY_CONF" ]; then
          cat "$NGINX_SECURITY_CONF"
        else
          echo "当前没有安全配置文件。"
        fi
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

log_monitor_menu() {
  while true; do
    print_header
    cat <<'MENU'
【拦截记录 / 日志监控】
1. 监控 Nginx 访问日志
2. 监控 Nginx 错误日志
3. 监控 Nginx 服务日志
4. 监控 Docker 服务日志
5. 监控自定义日志文件
0. 返回上级菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        if [ -f /var/log/nginx/access.log ]; then
          tail -f /var/log/nginx/access.log
        else
          echo "未找到 /var/log/nginx/access.log"
          pause
        fi
        ;;
      2)
        if [ -f /var/log/nginx/error.log ]; then
          tail -f /var/log/nginx/error.log
        else
          echo "未找到 /var/log/nginx/error.log"
          pause
        fi
        ;;
      3)
        if command -v journalctl >/dev/null 2>&1; then
          run_privileged journalctl -u nginx -f
        else
          echo "未找到 journalctl。"
          pause
        fi
        ;;
      4)
        if command -v journalctl >/dev/null 2>&1; then
          run_privileged journalctl -u docker -f
        else
          echo "未找到 journalctl。"
          pause
        fi
        ;;
      5)
        local custom_log
        read -rp "请输入日志文件路径: " custom_log
        if [ -f "$custom_log" ]; then
          tail -f "$custom_log"
        else
          echo "日志文件不存在。"
          pause
        fi
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

security_menu() {
  while true; do
    print_header
    cat <<'MENU'
【网站防护 / 安全】
1. 防火墙端口管理
2. IP 黑白名单
3. WAF / Cloudflare
4. 拦截记录 / 日志监控
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        firewall_menu
        ;;
      2)
        ip_acl_menu
        ;;
      3)
        security_mode_menu
        ;;
      4)
        log_monitor_menu
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}


# CodeX CLI：先准备 Node.js / npm，再配置 Codex。
codex_cli_ensure_node() {
  if command -v npm >/dev/null 2>&1 && (command -v node >/dev/null 2>&1 || command -v nodejs >/dev/null 2>&1); then
    return 0
  fi

  echo "未检测到 Node.js / npm，开始自动安装..."
  if command -v apt-get >/dev/null 2>&1; then
    run_privileged apt-get update
    run_privileged apt-get install -y curl ca-certificates gnupg
    run_privileged sh -c 'curl -fsSL https://deb.nodesource.com/setup_24.x | bash -'
    run_privileged apt-get install -y nodejs
  elif command -v dnf >/dev/null 2>&1; then
    run_privileged dnf install -y curl ca-certificates
    run_privileged sh -c 'curl -fsSL https://rpm.nodesource.com/setup_24.x | bash -'
    run_privileged dnf install -y nodejs npm
  elif command -v yum >/dev/null 2>&1; then
    run_privileged yum install -y curl ca-certificates
    run_privileged sh -c 'curl -fsSL https://rpm.nodesource.com/setup_24.x | bash -'
    run_privileged yum install -y nodejs npm
  elif command -v pacman >/dev/null 2>&1; then
    run_privileged pacman -Sy --noconfirm nodejs npm
  elif command -v zypper >/dev/null 2>&1; then
    run_privileged zypper refresh
    run_privileged zypper install -y nodejs npm
  else
    echo "未找到可用的包管理器，无法自动安装 Node.js / npm。"
    return 1
  fi

  if command -v nodejs >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
    run_privileged ln -sf "$(command -v nodejs)" /usr/local/bin/node >/dev/null 2>&1 || true
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "Node.js / npm 安装完成后仍未找到 npm。"
    return 1
  fi
}

codex_cli_write_config() {
  mkdir -p "$CODEX_DIR"
  cat > "$CODEX_CONFIG_FILE" <<EOF
model_provider = "$CODEX_MODEL_PROVIDER"
model = "$CODEX_MODEL"
model_reasoning_effort = "$CODEX_REASONING"
ask_for_approval = "never"
sandbox_mode = "workspace-write"

[model_providers.$CODEX_MODEL_PROVIDER]
name = "$CODEX_MODEL_PROVIDER"
base_url = "$CODEX_BASE_URL"
requires_openai_auth = true
wire_api = "responses"
EOF
}

codex_cli_write_auth() {
  if [ -n "${CODEX_API_KEY:-}" ]; then
    mkdir -p "$CODEX_DIR"
    cat > "$CODEX_AUTH_FILE" <<EOF
{"OPENAI_API_KEY":"$CODEX_API_KEY"}
EOF
  fi
}

codex_cli_show_status() {
  local version="未安装"
  if command -v codex >/dev/null 2>&1; then
    version="$(codex --version 2>/dev/null || echo "已安装，但无法读取版本")"
  fi

  echo "Codex CLI 版本: $version"
  echo "配置文件: $CODEX_CONFIG_FILE"
  echo "鉴权文件: $CODEX_AUTH_FILE"
  if [ -f "$CODEX_CONFIG_FILE" ]; then
    echo "配置文件已存在。"
  else
    echo "配置文件不存在。"
  fi
  if [ -f "$CODEX_AUTH_FILE" ]; then
    echo "OPENAI_API_KEY: 已设置（已打码）"
  else
    echo "OPENAI_API_KEY: 未设置"
  fi
}

codex_cli_install_or_upgrade() {
  if ! codex_cli_ensure_node; then
    return 1
  fi

  echo "开始安装/升级 CodeX CLI..."
  npm install -g @openai/codex
  if command -v codex >/dev/null 2>&1; then
    echo "安装完成，当前版本：$(codex --version 2>/dev/null)"
  fi
}

codex_cli_config_api_mode() {
  local input_model_provider input_base_url input_model input_reasoning input_api_key

  echo "当前默认配置："
  echo "Provider: $CODEX_MODEL_PROVIDER"
  echo "Base URL: $CODEX_BASE_URL"
  echo "Model: $CODEX_MODEL"
  echo "Reasoning: $CODEX_REASONING"
  echo ""

  read -rp "Provider 名称 [${CODEX_MODEL_PROVIDER}]: " input_model_provider
  input_model_provider="${input_model_provider:-$CODEX_MODEL_PROVIDER}"
  read -rp "Base URL [${CODEX_BASE_URL}]: " input_base_url
  input_base_url="${input_base_url:-$CODEX_BASE_URL}"
  read -rp "模型名称 [${CODEX_MODEL}]: " input_model
  input_model="${input_model:-$CODEX_MODEL}"
  read -rp "推理强度（low/medium/high）[${CODEX_REASONING}]: " input_reasoning
  input_reasoning="${input_reasoning:-$CODEX_REASONING}"
  read -rp "OpenAI API Key（可选，回车跳过）: " input_api_key

  CODEX_MODEL_PROVIDER="$input_model_provider"
  CODEX_BASE_URL="$input_base_url"
  CODEX_MODEL="$input_model"
  CODEX_REASONING="$input_reasoning"
  codex_cli_write_config

  if [ -n "$input_api_key" ]; then
    CODEX_API_KEY="$input_api_key"
    codex_cli_write_auth
  fi

  echo "Codex 配置已更新。"
  codex_cli_show_status
}

codex_cli_launch() {
  if command -v codex >/dev/null 2>&1; then
    echo "启动 Codex CLI..."
    CODEX_HOME="$CODEX_DIR" codex
  else
    echo "未找到 codex，请先执行安装/升级。"
  fi
}

codex_cli_menu() {
  while true; do
    print_header
    cat <<'MENU'
【CodeX CLI(API)】
1. 查看当前配置
2. 安装 / 升级 CodeX CLI
3. 配置 API 模式
4. 启动 CodeX CLI
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        codex_cli_show_status
        pause
        ;;
      2)
        codex_cli_install_or_upgrade
        pause
        ;;
      3)
        codex_cli_config_api_mode
        pause
        ;;
      4)
        codex_cli_launch
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

# V2Ray-Agent：下载并执行官方安装脚本。
v2ray_agent_install() {
  if ! require_docker; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "未检测到 git，请先安装 git。"
    return 1
  fi

  local tmp_script="$SCRIPT_DIR/tmp/v2ray-agent-install.sh"
  ensure_dir "$SCRIPT_DIR/tmp" || return 1
  if command -v wget >/dev/null 2>&1; then
    wget -O "$tmp_script" "${V2RAY_AGENT_INSTALL_URL}"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "${V2RAY_AGENT_INSTALL_URL}" -o "$tmp_script"
  else
    echo "未检测到 wget/curl，无法下载 V2Ray-Agent 安装脚本。"
    return 1
  fi

  chmod 700 "$tmp_script"
  bash "$tmp_script"
}

v2ray_agent_uninstall() {
  if ! require_docker; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "未检测到 git，请先安装 git。"
    return 1
  fi

  local tmp_script="$SCRIPT_DIR/tmp/v2ray-agent-install.sh"
  ensure_dir "$SCRIPT_DIR/tmp" || return 1
  if command -v wget >/dev/null 2>&1; then
    wget -O "$tmp_script" "${V2RAY_AGENT_INSTALL_URL}"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "${V2RAY_AGENT_INSTALL_URL}" -o "$tmp_script"
  else
    echo "未检测到 wget/curl，无法下载 V2Ray-Agent 安装脚本。"
    return 1
  fi

  chmod 700 "$tmp_script"
  printf '20
y
' | bash "$tmp_script"
}

v2ray_agent_menu() {
  while true; do
    print_header
    cat <<'MENU'
【V2Ray-Agent 安装脚本】
1. 下载并执行 V2Ray-Agent 安装脚本
2. 卸载 V2Ray-Agent
3. 查看安装脚本地址
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        v2ray_agent_install
        pause
        ;;
      2)
        v2ray_agent_uninstall
        pause
        ;;
      3)
        echo "安装脚本地址：${V2RAY_AGENT_INSTALL_URL}"
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}


# DNS 优化：按国家自动选择 DNS。
dns_optimize_detect_country() {
  local country
  country="$(curl -fsSL --max-time 5 https://ipinfo.io/country 2>/dev/null || echo "")"
  printf '%s' "$country"
}

dns_write_resolv_conf() {
  local dns1_ipv4="$1"
  local dns2_ipv4="$2"
  local dns1_ipv6="$3"
  local dns2_ipv6="$4"

  run_privileged chattr -i /etc/resolv.conf >/dev/null 2>&1 || true
  run_privileged sh -c "> /etc/resolv.conf"
  if [ -n "$dns1_ipv4" ]; then
    echo "nameserver $dns1_ipv4" | run_privileged tee -a /etc/resolv.conf >/dev/null
  fi
  if [ -n "$dns2_ipv4" ]; then
    echo "nameserver $dns2_ipv4" | run_privileged tee -a /etc/resolv.conf >/dev/null
  fi
  if [ -n "$dns1_ipv6" ]; then
    echo "nameserver $dns1_ipv6" | run_privileged tee -a /etc/resolv.conf >/dev/null
  fi
  if [ -n "$dns2_ipv6" ]; then
    echo "nameserver $dns2_ipv6" | run_privileged tee -a /etc/resolv.conf >/dev/null
  fi
  if [ ! -s /etc/resolv.conf ]; then
    echo "nameserver 223.5.5.5" | run_privileged tee -a /etc/resolv.conf >/dev/null
    echo "nameserver 8.8.8.8" | run_privileged tee -a /etc/resolv.conf >/dev/null
  fi
  run_privileged chattr +i /etc/resolv.conf >/dev/null 2>&1 || true
}

dns_optimize_foreign() {
  dns_write_resolv_conf "1.1.1.1" "8.8.8.8" "2606:4700:4700::1111" "2001:4860:4860::8888"
  echo "已切换为国外 DNS。"
}

dns_optimize_domestic() {
  dns_write_resolv_conf "223.5.5.5" "183.60.83.19" "2400:3200::1" "2400:da00::6666"
  echo "已切换为国内 DNS。"
}

dns_optimize_auto() {
  local country
  country="$(dns_optimize_detect_country)"
  if [ "$country" = "CN" ]; then
    dns_optimize_domestic
  else
    dns_optimize_foreign
  fi
  echo "当前国家代码：${country:-未知}"
}

dns_optimize_manual() {
  local dns1_ipv4 dns2_ipv4 dns1_ipv6 dns2_ipv6
  read -rp "请输入第一个 IPv4 DNS: " dns1_ipv4
  read -rp "请输入第二个 IPv4 DNS: " dns2_ipv4
  read -rp "请输入第一个 IPv6 DNS（可留空）: " dns1_ipv6
  read -rp "请输入第二个 IPv6 DNS（可留空）: " dns2_ipv6
  dns_write_resolv_conf "$dns1_ipv4" "$dns2_ipv4" "$dns1_ipv6" "$dns2_ipv6"
  echo "已写入手动 DNS 配置。"
}



# 时区 / 语言：修改系统时区和语言环境。
timezone_change_apply() {
  local timezone
  read -rp "请输入时区，例如 Asia/Shanghai: " timezone
  if [ -z "$timezone" ]; then
    echo "时区不能为空。"
    return 1
  fi

  if command -v timedatectl >/dev/null 2>&1; then
    run_privileged timedatectl set-timezone "$timezone"
    run_privileged timedatectl status
  else
    local zoneinfo="/usr/share/zoneinfo/$timezone"
    if [ ! -f "$zoneinfo" ]; then
      echo "未找到该时区文件：$zoneinfo"
      return 1
    fi
    run_privileged cp "$zoneinfo" /etc/localtime
    echo "$timezone" | run_privileged tee /etc/timezone >/dev/null
    echo "时区已切换为：$timezone"
  fi
}

language_change_apply() {
  local language
  read -rp "请输入系统语言代码，例如 zh_CN.UTF-8 / en_US.UTF-8: " language
  if [ -z "$language" ]; then
    echo "语言不能为空。"
    return 1
  fi

  if command -v localectl >/dev/null 2>&1; then
    run_privileged localectl set-locale "LANG=$language"
  fi

  if [ -f /etc/default/locale ]; then
    echo "LANG=$language" | run_privileged tee /etc/default/locale >/dev/null
  elif [ -f /etc/locale.conf ]; then
    echo "LANG=$language" | run_privileged tee /etc/locale.conf >/dev/null
  fi

  echo "系统语言已切换为：$language"
}

timezone_language_menu() {
  while true; do
    print_header
    cat <<'MENU'
【时区 / 语言切换】
1. 查看当前时区
2. 切换系统时区
3. 切换系统语言
4. 查看当前语言环境
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        if command -v timedatectl >/dev/null 2>&1; then
          timedatectl status | sed -n 's/^.*Time zone: //p'
        else
          cat /etc/timezone 2>/dev/null || date +"%Z %z"
        fi
        pause
        ;;
      2)
        timezone_change_apply
        pause
        ;;
      3)
        language_change_apply
        pause
        ;;
      4)
        if command -v localectl >/dev/null 2>&1; then
          localectl status
        else
          echo "LANG=${LANG:-unknown}"
          locale
        fi
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}
dns_optimize_menu() {
  while true; do
    print_header
    cat <<'MENU'
【DNS 优化】
1. 自动识别并优化
2. 使用国内 DNS
3. 使用国外 DNS
4. 手动编辑 DNS
5. 查看当前 DNS
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        dns_optimize_auto
        pause
        ;;
      2)
        dns_optimize_domestic
        pause
        ;;
      3)
        dns_optimize_foreign
        pause
        ;;
      4)
        dns_optimize_manual
        pause
        ;;
      5)
        cat /etc/resolv.conf
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

data_migration_menu() {
  while true; do
    print_header
    cat <<'MENU'
【数据迁移】
1. 备份 Docker 项目目录
2. 从备份恢复项目
3. 删除项目目录
0. 返回主菜单
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        docker_backup_project
        pause
        ;;
      2)
        docker_restore_project
        pause
        ;;
      3)
        docker_delete_project
        pause
        ;;
      0)
        break
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

main_menu() {
  while true; do
    print_header
    cat <<'MENU'
【主菜单】
1. Docker 基础管理
2. NPM站点反代管理
3. 数据迁移
4. 网站防护 / 安全
5. 服务器基础维护
0. 退出
MENU

    read -rp "请选择: " choice
    case "$choice" in
      1)
        docker_menu
        ;;
      2)
        site_management_menu
        ;;
      3)
        data_migration_menu
        ;;
      4)
        security_menu
        ;;
      5)
        server_maintenance_menu
        ;;
      0)
        echo "已退出。"
        exit 0
        ;;
      *)
        echo "无效选择。"
        pause
        ;;
    esac
  done
}

main_menu

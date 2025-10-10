cat > arcium-node-hub.sh <<'BASH'
#!/usr/bin/env bash
# =====================================================================
#  Arcium-Node-Hub — RU/EN interactive installer/manager (Docker)
#  Version: 0.2.0 (RU labels, default cluster 10102025 for propose, menu tweaks)
# =====================================================================
set -Eeuo pipefail

display_logo() {
  cat <<'EOF'
 _   _           _  _____      
| \ | |         | ||____ |     
|  \| | ___   __| |    / /_ __ 
| . ` |/ _ \ / _` |    \ \ '__|
| |\  | (_) | (_| |.___/ / |   
\_| \_/\___/ \__,_|\____/|_|   
          
  TG: https://t.me/NodesN3R 
EOF
}

clrGreen=$'\033[0;32m'; clrCyan=$'\033[0;36m'; clrBlue=$'\033[0;34m'
clrRed=$'\033[0;31m'; clrYellow=$'\033[1;33m'; clrMag=$'\033[1;35m'
clrReset=$'\033[0m'; clrBold=$'\033[1m'; clrDim=$'\033[2m'

ok()   { echo -e "${clrGreen}[OK]${clrReset} ${*:-}"; }
info() { echo -e "${clrCyan}[INFO]${clrReset} ${*:-}"; }
warn() { echo -e "${clrYellow}[WARN]${clrReset} ${*:-}"; }
err()  { echo -e "${clrRed}[ERROR]${clrReset} ${*:-}"; }
hr()   { echo -e "${clrDim}────────────────────────────────────────────────────────${clrReset}"; }

SCRIPT_NAME="Arcium-Node-Hub"
SCRIPT_VERSION="0.2.0"
LANG_CHOICE="ru"
BASE_DIR_DEFAULT="$HOME/arcium-node-setup"
ENV_FILE_DEFAULT="$HOME/arcium-node-setup/.env"
IMAGE_DEFAULT="arcium/arx-node:v0.3.0"
CONTAINER_DEFAULT="arx-node"
RPC_DEFAULT_HTTP="https://api.devnet.solana.com"
RPC_DEFAULT_WSS="wss://api.devnet.solana.com"

BASE_DIR=${BASE_DIR:-$BASE_DIR_DEFAULT}
ENV_FILE=${ENV_FILE:-$ENV_FILE_DEFAULT}
IMAGE=${IMAGE:-$IMAGE_DEFAULT}
CONTAINER=${CONTAINER:-$CONTAINER_DEFAULT}
RPC_HTTP=${RPC_HTTP:-$RPC_DEFAULT_HTTP}
RPC_WSS=${RPC_WSS:-$RPC_DEFAULT_WSS}
OFFSET=${OFFSET:-}
PUBLIC_IP=${PUBLIC_IP:-}
CLUSTER_OFFSET=${CLUSTER_OFFSET:-}

[[ -f "$ENV_FILE" ]] && source "$ENV_FILE" || true

CFG_FILE="$BASE_DIR/node-config.toml"
NODE_KP="$BASE_DIR/node-keypair.json"
CALLBACK_KP="$BASE_DIR/callback-kp.json"
IDENTITY_PEM="$BASE_DIR/identity.pem"
LOGS_DIR="$BASE_DIR/arx-node-logs"

choose_language() {
  clear; display_logo
  echo -e "\n${clrBold}${clrMag}Select language / Выберите язык${clrReset}"
  echo -e "${clrDim}1) Русский${clrReset}"
  echo -e "${clrDim}2) English${clrReset}"
  read -rp "> " ans
  case "${ans:-}" in 2) LANG_CHOICE="en";; *) LANG_CHOICE="ru";; esac
}

tr() {
  local k="${1-}"; [[ -z "$k" ]] && return 0
  case "$LANG_CHOICE" in
    en) case "$k" in
      need_root_warn) echo "Some steps need sudo/root. You'll be prompted if needed.";;
      menu_title) echo "Arcium Node — Installer & Manager";;
      m1_setup) echo "Node setup";;
      m2_manage) echo "Container control";;
      m3_config) echo "Configuration";;
      m4_tools) echo "Tools (logs, status)";;
      m5_exit) echo "Exit";;
      press_enter) echo "Press Enter to continue...";;
      docker_setup) echo "Installing Docker (engine + compose plugin)...";;
      docker_done) echo "Docker installed";;
      pull_image) echo "Pulling image...";;
      start_container) echo "Starting container...";;
      container_started) echo "Container started";;
      container_stopped) echo "Container stopped";;
      container_removed) echo "Container removed";;
      container_restarted) echo "Container restarted";;
      status_table) echo "Status table";;
      ask_rpc_http) echo "Enter Solana RPC HTTP URL (or leave default): ";;
      ask_rpc_wss)  echo "Enter Solana RPC WSS URL  (or leave default): ";;
      ask_offset)   echo "Enter unique node OFFSET (digits, e.g. 8-10 numbers): ";;
      ask_cluster_offset) echo "Enter CLUSTER OFFSET to join (digits) or leave empty: ";;
      ask_ip)       echo "Enter public IP (auto-detected if empty): ";;
      cfg_current) echo "Current config";;
      cfg_saved)   echo "Saved to .env";;
      gen_keys)    echo "Generating keys...";;
      keys_done)   echo "Keys generated";;
      init_onchain) echo "Initializing on-chain node accounts...";;
      init_done) echo "On-chain initialization done";;
      logs_follow) echo "Logs (follow)";;        # header on logs screen
      menu_logs)   echo "Logs (follow)";;        # menu label
      show_logs_hint) echo "Press Ctrl+C to stop following logs.";;
      setup_binfmt_note) echo "Enabling amd64 emulation for ARM64 host...";;
      tools_status) echo "Node status";;
      tools_active) echo "Check if Node is Active";;
      join_cluster_lbl) echo "Join cluster";;
      propose_join_lbl) echo "Send join proposal (propose-join-cluster)";;
      check_membership_lbl) echo "Check node membership in your cluster";;
      manage_start) echo "Start container";;
      manage_restart) echo "Restart container";;
      manage_stop) echo "Stop container";;
      manage_remove) echo "Remove container";;
      manage_status) echo "Status";;
      cfg_edit_rpc_http) echo "Edit RPC_HTTP";;
      cfg_edit_rpc_wss)  echo "Edit RPC_WSS";;
    esac;;
    *) case "$k" in
      need_root_warn) echo "Некоторые шаги требуют sudo/root. Вас попросят ввести пароль при необходимости.";;
      menu_title) echo "Arcium Node — установщик и менеджер";;
      m1_setup) echo "Установка ноды";;
      m2_manage) echo "Управление контейнером";;
      m3_config) echo "Конфигурация";;
      m4_tools) echo "Инструменты (логи, статус)";;
      m5_exit) echo "Выход";;
      press_enter) echo "Нажмите Enter для продолжения...";;
      docker_setup) echo "Устанавливаю Docker (движок + compose-плагин)...";;
      docker_done) echo "Docker установлен";;
      pull_image) echo "Тяну образ...";;
      start_container) echo "Запускаю контейнер...";;
      container_started) echo "Контейнер запущен";;
      container_stopped) echo "Контейнер остановлен";;
      container_removed) echo "Контейнер удалён";;
      container_restarted) echo "Контейнер перезапущен";;
      status_table) echo "Таблица статуса";;
      ask_rpc_http) echo "Введи Solana RPC HTTP URL (или оставь по умолчанию): ";;
      ask_rpc_wss)  echo "Введи Solana RPC WSS URL  (или оставь по умолчанию): ";;
      ask_offset)   echo "Введи уникальный OFFSET ноды (цифры, например 8–10 знаков): ";;
      ask_cluster_offset) echo "Введи CLUSTER OFFSET (цифры) или оставь пустым: ";;
      ask_ip)       echo "Введи публичный IP (если пусто — автоопределю): ";;
      cfg_current) echo "Текущая конфигурация";;
      cfg_saved)   echo "Сохранено в .env";;
      gen_keys)    echo "Генерирую ключи...";;
      keys_done)   echo "Ключи сгенерированы";;
      init_onchain) echo "Инициализирую on-chain аккаунты ноды...";;
      init_done) echo "Инициализация завершена";;
      logs_follow) echo "Логи (онлайн)";;       # заголовок экрана логов
      menu_logs)   echo "Просмотр логов";;      # пункт меню
      show_logs_hint) echo "Нажмите Ctrl+C, чтобы остановить просмотр.";;
      setup_binfmt_note) echo "Включаю эмуляцию amd64 для ARM64-хоста...";;
      tools_status) echo "Статус ноды";;
      tools_active) echo "Проверить активность ноды";;
      join_cluster_lbl) echo "Присоединиться к кластеру";;
      propose_join_lbl) echo "Отправить заявку в кластер";;
      check_membership_lbl) echo "Проверить членство ноды в кластере";;
      manage_start) echo "Запустить контейнер";;
      manage_restart) echo "Перезапустить контейнер";;
      manage_stop) echo "Остановить контейнер";;
      manage_remove) echo "Удалить контейнер";;
      manage_status) echo "Статус";;
      cfg_edit_rpc_http) echo "Изменить RPC_HTTP";;
      cfg_edit_rpc_wss)  echo "RPC_WSS";;
    esac;;
  esac
}

need_sudo() { if [[ $(id -u) -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then err "sudo не найден. Запусти под root или установи sudo."; exit 1; fi; }
run_root() { if [[ $(id -u) -ne 0 ]]; then sudo bash -lc "$*"; else bash -lc "$*"; fi; }
ensure_cmd() { command -v "$1" >/dev/null 2>&1; }

sanitize_offset() {
  if [[ -n "${OFFSET:-}" ]]; then
    local clean
    clean="$(printf '%s\n' "$OFFSET" | sed -n 's/[^0-9]*\([0-9][0-9]*\).*/\1/p')"
    if [[ -n "$clean" && "$clean" != "$OFFSET" ]]; then
      OFFSET="$clean"
      save_env 2>/dev/null || true
    fi
  fi
}

ensure_offsets() {
  [[ -f "$ENV_FILE" ]] && source "$ENV_FILE" || true
  sanitize_offset
  if [[ -z "${OFFSET:-}" && -f "$CFG_FILE" ]]; then
    local parsed
    parsed="$(sed -n 's/^[[:space:]]*offset[[:space:]]*=[[:space:]]*\([0-9]\+\).*$/\1/p' "$CFG_FILE" | head -1)"
    if [[ -n "$parsed" ]]; then
      OFFSET="$parsed"
      sanitize_offset
      save_env 2>/dev/null || true
    fi
  fi
}

save_env() {
  mkdir -p "$(dirname "$ENV_FILE")"
  cat >"$ENV_FILE" <<EOF
IMAGE=$IMAGE
CONTAINER=$CONTAINER
BASE_DIR=$BASE_DIR
RPC_HTTP=$RPC_HTTP
RPC_WSS=$RPC_WSS
OFFSET=$OFFSET
CLUSTER_OFFSET=$CLUSTER_OFFSET
PUBLIC_IP=$PUBLIC_IP
EOF
  ok "$(tr cfg_saved) ($ENV_FILE)"
}

install_docker() {
  clear; display_logo; hr
  info "$(tr docker_setup)"; need_sudo
  run_root "apt-get update -y && apt-get install -y ca-certificates curl gnupg lsb-release"
  run_root "install -m 0755 -d /etc/apt/keyrings || true"
  run_root "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
  run_root "chmod a+r /etc/apt/keyrings/docker.gpg"
  run_root "bash -lc 'echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" > /etc/apt/sources.list.d/docker.list'"
  run_root "apt-get update -y && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  run_root "systemctl enable --now docker"
  ok "$(tr docker_done)"
}

maybe_enable_binfmt() {
  local arch; arch=$(uname -m || echo unknown)
  if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
    warn "$(tr setup_binfmt_note)"
    docker run --privileged --rm tonistiigi/binfmt --install amd64 || true
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
  fi
}

install_arcium_tooling() {
  mkdir -p "$HOME/.cargo/bin" || true
  local target="x86_64_linux"; [[ $(uname -m) =~ (aarch64|arm64) ]] && target="aarch64_linux"
  info "Installing arcup (platform: $target)"
  curl -fsSL "https://bin.arcium.com/download/arcup_${target}_0.3.0" -o "$HOME/.cargo/bin/arcup"
  chmod +x "$HOME/.cargo/bin/arcup"
  if ! command -v arcium >/dev/null 2>&1; then
    info "Installing Arcium CLI 0.3.0"; arcup install || true
  fi
}

ask_config() {
  mkdir -p "$BASE_DIR" "$LOGS_DIR"
  echo
  read -rp "$(tr ask_rpc_http) [$RPC_HTTP] " ans; RPC_HTTP=${ans:-$RPC_HTTP}
  read -rp "$(tr ask_rpc_wss)  [$RPC_WSS] " ans; RPC_WSS=${ans:-$RPC_WSS}
  read -rp "$(tr ask_offset) " OFFSET
  sanitize_offset
  if [[ -z "${PUBLIC_IP:-}" ]]; then PUBLIC_IP=$(curl -4 -s https://ipecho.net/plain || true); fi
  read -rp "$(tr ask_ip) [$PUBLIC_IP] " ans; PUBLIC_IP=${ans:-$PUBLIC_IP}
  save_env
}

generate_keys() {
  clear; display_logo; hr
  info "$(tr gen_keys)"
  if ! ensure_cmd solana-keygen; then err "solana-keygen not found. Install Solana CLI first."; exit 1; fi
  [[ -f "$NODE_KP" ]] || solana-keygen new --outfile "$NODE_KP" --no-bip39-passphrase <<<"y" >/dev/null 2>&1 || true
  [[ -f "$CALLBACK_KP" ]] || solana-keygen new --outfile "$CALLBACK_KP" --no-bip39-passphrase <<<"y" >/dev/null 2>&1 || true
  [[ -f "$IDENTITY_PEM" ]] || openssl genpkey -algorithm Ed25519 -out "$IDENTITY_PEM" >/dev/null 2>&1 || true
  ok "$(tr keys_done)"; hr
  echo "Node pubkey:     $(solana address --keypair "$NODE_KP" 2>/dev/null || true)"
  echo "Callback pubkey: $(solana address --keypair "$CALLBACK_KP" 2>/dev/null || true)"
}

write_config() {
  mkdir -p "$BASE_DIR"
  cat >"$CFG_FILE" <<EOF
[node]
offset = ${OFFSET}
hardware_claim = 0
starting_epoch = 0
ending_epoch = 9223372036854775807

[network]
address = "0.0.0.0"

[solana]
endpoint_rpc = "${RPC_HTTP}"
endpoint_wss = "${RPC_WSS}"
cluster = "Devnet"

[solana.commitment]
commitment = "confirmed"
EOF
}

init_onchain() {
  clear; display_logo; hr
  info "$(tr init_onchain)"
  solana config set --url "$RPC_HTTP" >/dev/null 2>&1 || true
  local key_dir; key_dir="$(dirname "$NODE_KP")"
  if [[ ! -f "$NODE_KP" ]]; then err "Файл ключа ноды не найден: $NODE_KP"; echo -e "\n$(tr press_enter)"; read -r; return; fi
  if [[ ! -f "$CALLBACK_KP" ]]; then err "Файл callback ключа не найден: $CALLBACK_KP"; echo -e "\n$(tr press_enter)"; read -r; return; fi
  if [[ ! -f "$IDENTITY_PEM" ]]; then err "Файл identity не найден: $IDENTITY_PEM"; echo -e "\n$(tr press_enter)"; read -r; return; fi
  if [[ -d "$key_dir" ]]; then
    ( cd "$key_dir" && arcium init-arx-accs \
        --keypair-path "$NODE_KP" \
        --callback-keypair-path "$CALLBACK_KP" \
        --peer-keypair-path "$IDENTITY_PEM" \
        --node-offset "$OFFSET" \
        --ip-address "$PUBLIC_IP" \
        --rpc-url "$RPC_HTTP" )
    cd "$HOME" || true
  else
    arcium init-arx-accs \
      --keypair-path "$NODE_KP" \
      --callback-keypair-path "$CALLBACK_KP" \
      --peer-keypair-path "$IDENTITY_PEM" \
      --node-offset "$OFFSET" \
      --ip-address "$PUBLIC_IP" \
      --rpc-url "$RPC_HTTP"
  fi
  ok "$(tr init_done)"
}

pull_image() { info "$(tr pull_image) $IMAGE"; docker pull "$IMAGE"; }

start_container() {
  mkdir -p "$LOGS_DIR"
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  info "$(tr start_container)"
  docker run -d \
    --name "$CONTAINER" \
    -e NODE_IDENTITY_FILE=/usr/arx-node/node-keys/node_identity.pem \
    -e NODE_KEYPAIR_FILE=/usr/arx-node/node-keys/node_keypair.json \
    -e OPERATOR_KEYPAIR_FILE=/usr/arx-node/node-keys/operator_keypair.json \
    -e CALLBACK_AUTHORITY_KEYPAIR_FILE=/usr/arx-node/node-keys/callback_authority_keypair.json \
    -e NODE_CONFIG_PATH=/usr/arx-node/arx/node_config.toml \
    -v "$CFG_FILE:/usr/arx-node/arx/node_config.toml" \
    -v "$NODE_KP:/usr/arx-node/node-keys/node_keypair.json:ro" \
    -v "$NODE_KP:/usr/arx-node/node-keys/operator_keypair.json:ro" \
    -v "$CALLBACK_KP:/usr/arx-node/node-keys/callback_authority_keypair.json:ro" \
    -v "$IDENTITY_PEM:/usr/arx-node/node-keys/node_identity.pem:ro" \
    -v "$LOGS_DIR:/usr/arx-node/logs" \
    -p 8080:8080 \
    "$IMAGE"
  ok "$(tr container_started)"
}

stop_container()  { docker stop "$CONTAINER" && ok "$(tr container_stopped)" || true; }
remove_container(){ docker rm -f "$CONTAINER" && ok "$(tr container_removed)" || true; }
restart_container(){ docker restart "$CONTAINER" && ok "$(tr container_restarted)" || true; }
status_table()    { echo -e "$(tr status_table):\n"; docker ps -a --filter "name=$CONTAINER" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'; }

show_logs_follow() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr logs_follow)${clrReset}\n"; hr
  echo -e "${clrDim}$(tr show_logs_hint)${clrReset}\n"
  docker exec -it "$CONTAINER" sh -lc 'tail -n +1 -f "$(ls -t /usr/arx-node/logs/arx_log_*.log 2>/dev/null | head -1)"' || true
}

_get_offset_or_prompt() {
  ensure_offsets
  sanitize_offset
  if [[ -n "${OFFSET:-}" ]]; then
    info "Using node OFFSET: ${OFFSET}"
    return 0
  fi
  read -rp "$(tr ask_offset) " OFFSET
  sanitize_offset
  [[ -z "${OFFSET:-}" ]] && { warn "OFFSET пустой — операция отменена."; return 1; }
  return 0
}

node_status() { clear; display_logo; hr; echo -e "${clrBold}${clrMag}$(tr tools_status)${clrReset}\n"; hr; if _get_offset_or_prompt; then arcium arx-info "$OFFSET" --rpc-url "$RPC_HTTP" || true; fi; }
node_active() { clear; display_logo; hr; echo -e "${clrBold}${clrMag}$(tr tools_active)${clrReset}\n"; hr; if _get_offset_or_prompt; then arcium arx-active "$OFFSET" --rpc-url "$RPC_HTTP" || true; fi; }

join_cluster() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr join_cluster_lbl)${clrReset}\n"; hr
  if !_get_offset_or_prompt; then echo -e "\n$(tr press_enter)"; read -r; return; fi
  local cur_cluster="${CLUSTER_OFFSET:-}" ans
  read -rp "$(tr ask_cluster_offset) ${cur_cluster:+[$cur_cluster]} " ans
  local cluster_offset="${ans:-$cur_cluster}"
  if [[ -z "$cluster_offset" ]]; then warn "cluster_offset пустой — операция отменена."; echo -e "\n$(tr press_enter)"; read -r; return; fi
  if [[ ! -f "$NODE_KP" ]]; then err "Файл ключа ноды не найден: $NODE_KP"; echo -e "\n$(tr press_enter)"; read -r; return; fi
  info "Joining cluster: node_offset=$OFFSET, cluster_offset=$cluster_offset"
  local key_dir; key_dir="$(dirname "$NODE_KP")"
  if [[ -d "$key_dir" ]]; then
    ( cd "$key_dir" && arcium join-cluster true --keypair-path "$NODE_KP" --node-offset "$OFFSET" --cluster-offset "$cluster_offset" --rpc-url "$RPC_HTTP" )
    cd "$HOME" || true
  else
    arcium join-cluster true --keypair-path "$NODE_KP" --node-offset "$OFFSET" --cluster-offset "$cluster_offset" --rpc-url "$RPC_HTTP"
  fi
  CLUSTER_OFFSET="$cluster_offset"; save_env; echo -e "\n$(tr press_enter)"; read -r
}

propose_join_cluster() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr propose_join_lbl)${clrReset}\n"; hr
  local cur_cluster="${CLUSTER_OFFSET:-}" ans
  read -rp "$(tr ask_cluster_offset) ${cur_cluster:+[$cur_cluster]} " ans
  local cluster_offset="${ans:-$cur_cluster}"
  # default cluster if empty
  if [[ -z "$cluster_offset" ]]; then
    cluster_offset="10102025"
    info "CLUSTER OFFSET не указан — использую по умолчанию: $cluster_offset"
  fi
  if !_get_offset_or_prompt; then echo -e "\n$(tr press_enter)"; read -r; return; fi
  if [[ ! -f "$NODE_KP" ]]; then err "Ключ не найден: $NODE_KP"; echo -e "\n$(tr press_enter)"; read -r; return; fi
  info "Proposing node_offset=$OFFSET to cluster_offset=$cluster_offset"
  local key_dir; key_dir="$(dirname "$NODE_KP")"
  if [[ -d "$key_dir" ]]; then
    ( cd "$key_dir" && arcium propose-join-cluster --keypair-path "$NODE_KP" --node-offset "$OFFSET" --cluster-offset "$cluster_offset" --rpc-url "$RPC_HTTP" ) && ok "Proposal sent"
    cd "$HOME" || true
  else
    arcium propose-join-cluster --keypair-path "$NODE_KP" --node-offset "$OFFSET" --cluster-offset "$cluster_offset" --rpc-url "$RPC_HTTP" && ok "Proposal sent"
  fi
  CLUSTER_OFFSET="$cluster_offset"; save_env; echo -e "\n$(tr press_enter)"; read -r
}

check_membership_single() {
  ensure_offsets; sanitize_offset
  local cur_cluster="${CLUSTER_OFFSET:-}" ans
  read -rp "$(tr ask_cluster_offset) ${cur_cluster:+[$cur_cluster]} " ans
  local cluster_offset="${ans:-$cur_cluster}"
  [[ -z "$cluster_offset" ]] && { warn "cluster_offset пустой"; return; }
  local node_off; read -rp "$(tr ask_offset) " node_off
  node_off="$(printf '%s\n' "$node_off" | sed -n 's/[^0-9]*\([0-9][0-9]*\).*/\1/p')"
  [[ -z "$node_off" ]] && { warn "node offset пустой"; return; }
  echo; info "Checking node $node_off in cluster $cluster_offset..."
  if arcium arx-info "$node_off" --rpc-url "$RPC_HTTP" | awk -v c="$cluster_offset" '
    /^Cluster memberships:/ { inlist=1; next }
    inlist {
      if ($0 ~ /^[[:space:]]*$/) { inlist=0; next }
      if (index($0, c)) { found=1 }
    }
    END { exit(found ? 0 : 1) }
  ' >/dev/null; then ok "Node $node_off is IN cluster $cluster_offset"; else warn "Node $node_off is NOT in cluster $cluster_offset (or not found)"; fi
  echo
}

config_menu() {
  while true; do
    clear; display_logo; hr
    echo -e "${clrBold}${clrMag}$(tr cfg_current)${clrReset}\n"
    echo -e "IMAGE:        ${clrBlue}${IMAGE}${clrReset}"
    echo -e "CONTAINER:    ${clrBlue}${CONTAINER}${clrReset}"
    echo -e "BASE_DIR:     ${clrBlue}${BASE_DIR}${clrReset}"
    echo -e "RPC_HTTP:     ${clrBlue}${RPC_HTTP}${clrReset}"
    echo -e "RPC_WSS:      ${clrBlue}${RPC_WSS}${clrReset}"
    ensure_offsets; sanitize_offset
    echo -e "OFFSET:       ${clrBlue}${OFFSET:-not-set}${clrReset}"
    echo -e "PUBLIC_IP:    ${clrBlue}${PUBLIC_IP:-auto}${clrReset}"
    hr
    echo -e "${clrGreen}1)${clrReset} $(tr cfg_edit_rpc_http)"
    echo -e "${clrGreen}2)${clrReset} $(tr cfg_edit_rpc_wss)"
    echo -e "${clrGreen}0)${clrReset} $(tr m5_exit)"
    hr
    read -rp "> " c
    case "${c:-}" in
      1) read -rp "RPC_HTTP: " RPC_HTTP ;;
      2) read -rp "RPC_WSS: " RPC_WSS ;;
      0) return ;;
      *) ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

tools_menu() {
  while true; do
    clear; display_logo; hr
    echo -e "${clrBold}${clrMag}$(tr m4_tools)${clrReset}\n"
    echo -e "${clrGreen}1)${clrReset} $(tr menu_logs)"
    echo -e "${clrGreen}2)${clrReset} $(tr tools_status)"
    echo -e "${clrGreen}3)${clrReset} $(tr tools_active)"
    echo -e "${clrGreen}4)${clrReset} $(tr propose_join_lbl)"   # propose first
    echo -e "${clrGreen}5)${clrReset} $(tr join_cluster_lbl)"     # then join
    echo -e "${clrGreen}6)${clrReset} $(tr check_membership_lbl)"
    echo -e "${clrGreen}0)${clrReset} $(tr m5_exit)"
    hr
    read -rp "> " c
    case "${c:-}" in
      1) show_logs_follow ;;
      2) node_status ;;
      3) node_active ;;
      4) propose_join_cluster ;;
      5) join_cluster ;;
      6) check_membership_single ;;
      0) return ;;
      *) ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

manage_menu() {
  while true; do
    clear; display_logo; hr
    echo -e "${clrBold}${clrMag}$(tr m2_manage)${clrReset}\n"
    echo -e "${clrGreen}1)${clrReset} $(tr manage_start)"
    echo -e "${clrGreen}2)${clrReset} $(tr manage_restart)"
    echo -e "${clrGreen}3)${clrReset} $(tr manage_stop)"
    echo -e "${clrGreen}4)${clrReset} $(tr manage_remove)"
    echo -e "${clrGreen}5)${clrReset} $(tr manage_status)"
    echo -e "${clrGreen}0)${clrReset} $(tr m5_exit)"
    hr
    read -rp "> " c
    case "${c:-}" in
      1) start_container ;;
      2) restart_container ;;
      3) stop_container ;;
      4) remove_container ;;
      5) status_table ;;
      0) return ;;
      *) ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

quick_setup() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr m1_setup)${clrReset}\n"; hr
  need_sudo
  if ! ensure_cmd docker; then install_docker; fi
  maybe_enable_binfmt
  install_arcium_tooling || true
  ask_config
  generate_keys
  write_config
  pull_image
  init_onchain
  start_container
  status_table
  echo -e "\n$(tr press_enter)"; read -r
}

main_menu() {
  choose_language
  info "$(tr need_root_warn)" || true
  while true; do
    clear; display_logo; hr
    echo -e "${clrBold}${clrMag}$(tr menu_title)${clrReset} ${clrDim}(v${SCRIPT_VERSION})${clrReset}\n"
    echo -e "${clrGreen}1)${clrReset} $(tr m1_setup)"
    echo -e "${clrGreen}2)${clrReset} $(tr m2_manage)"
    echo -e "${clrGreen}3)${clrReset} $(tr m3_config)"
    echo -e "${clrGreen}4)${clrReset} $(tr m4_tools)"
    echo -e "${clrGreen}5)${clrReset} $(tr m5_exit)"
    hr
    read -rp "> " choice
    case "${choice:-}" in
      1) quick_setup ;;
      2) manage_menu ;;
      3) config_menu ;;
      4) tools_menu ;;
      5) exit 0 ;;
      *) ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

main_menu
BASH

chmod +x arcium-node-hub.sh

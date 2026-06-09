#!/usr/bin/env bash
# core.sh — главный цикл, маршрутизация шагов, обработка аргументов

set -euo pipefail

# Цветной вывод (если TTY)
if [[ -t 1 ]]; then
  C_RED='\033[0;31m'
  C_GREEN='\033[0;32m'
  C_YELLOW='\033[1;33m'
  C_BLUE='\033[0;34m'
  C_RESET='\033[0m'
else
  C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_RESET=''
fi

say()    { printf "${C_BLUE}==>${C_RESET} %s\n" "$*"; }
ok()     { printf "${C_GREEN}✓${C_RESET} %s\n" "$*"; }
warn()   { printf "${C_YELLOW}⚠${C_RESET} %s\n" "$*"; }
err()    { printf "${C_RED}✗${C_RESET} %s\n" "$*" >&2; }
die()    { err "$*"; exit 1; }

# === Pre-flight checks ===

preflight_check() {
  local -a missing=()
  for tool in whiptail sudo; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    cat <<EOF
site-install: отсутствуют обязательные утилиты: ${missing[*]}

Установите их:
  apt-get install -y whiptail sudo

Или запустите bootstrap-установщик:
  curl -fsSL https://raw.githubusercontent.com/eveiljuice/site-install/main/bootstrap/install.sh | sudo bash
EOF
    exit 1
  fi

  if (( EUID != 0 )); then
    die "site-install требует root. Запустите: sudo site-install $*"
  fi
}

# === Маршруты ===

main_help() {
  cat <<EOF
site-install — интерактивный TUI-установщик сайтов

Использование:
  sudo site-install                 # интерактивный режим
  sudo site-install --dry-run PATH   # показать план без изменений
  sudo site-install --list           # список установленных проектов
  sudo site-install --version        # версия утилиты
  sudo site-install --help           # эта справка

EOF
}

main_version() {
  echo "site-install 0.1.0 (MVP)"
}

main_list() {
  if [[ ! -f "$HOME/.config/site-install/state.json" ]]; then
    echo "Нет установленных проектов."
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    die "Для --list требуется jq. Установите: apt-get install -y jq"
  fi
  jq -r '.projects | to_entries[] | "\(.key): \(.value.project_path) (\(.value.adapter))"' \
    "$HOME/.config/site-install/state.json"
}

main_interactive() {
  preflight_check "$@"
  source "$SITE_INSTALL_LIB/state.sh"
  source "$SITE_INSTALL_LIB/log.sh"
  source "$SITE_INSTALL_LIB/ui.sh"

  # Главное меню
  while true; do
    local choice
    choice=$(ui_menu "Site Install" "Выберите действие:" \
      "NEW"  "🆕 Новая установка" \
      "EXIT" "❌ Выход") || exit 0

    case "$choice" in
      NEW)  wizard_new_install ;;
      EXIT) exit 0 ;;
    esac
  done
}

main_dry_run() {
  local target_path="${1:-$(pwd)}"
  if [[ ! -d "$target_path" ]]; then
    die "Путь не существует: $target_path"
  fi
  preflight_check
  source "$SITE_INSTALL_LIB/detect.sh"
  source "$SITE_INSTALL_LIB/sizes.sh"
  source "$SITE_INSTALL_LIB/state.sh"

  say "Dry-run для: $target_path"
  local stack_json; stack_json=$(detect_stack "$target_path")
  echo "$stack_json" | jq .
  show_size_forecast "$target_path"
}

# Заглушка для wizard — реализуем в Task 12
wizard_new_install() {
  # 1. Источник
  local source
  source=$(ui_radio "Источник проекта" "Откуда взять проект?" \
    "git"   "Git-репозиторий (URL)" on \
    "zip"   "ZIP-архив (локальный путь)" off \
    "local" "Локальная папка" off) || return 0

  local source_arg
  case "$source" in
    git)
      source_arg=$(ui_input "URL git-репозитория" "https://github.com/user/repo.git")
      ;;
    zip)
      source_arg=$(ui_input "Путь к ZIP-архиву" "/root/site.zip")
      ;;
    local)
      source_arg=$(ui_input "Путь к локальной папке" "/root/my-site")
      ;;
  esac

  # 2. Папка установки
  local basename
  basename=$(basename "$source_arg" .git | sed 's/\.zip$//' | tr '/' '_')
  local default_dest="/var/www/$basename"
  local dest
  dest=$(ui_input "Директория установки" "$default_dest")

  if [[ -d "$dest" ]] && [[ -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
    local overwrite
    overwrite=$(ui_radio "Папка не пуста" "$dest уже содержит файлы. Что делать?" \
      "ABORT" "Прервать установку" on \
      "USE"   "Использовать существующую" off \
      "WIPE"  "Удалить и установить заново" off) || return 0
    case "$overwrite" in
      ABORT) return 0 ;;
      WIPE)  rm -rf "$dest" ;;
      USE)   : ;;  # ok
    esac
  fi

  # 3. Получаем проект
  mkdir -p "$dest"
  case "$source" in
    git)   run_with_progress "Клонирование" 1 "git clone --depth=1 '$source_arg' '$dest'" ;;
    zip)   source_zip "$source_arg" "$dest" ;;
    local) source_local "$source_arg" "$dest" ;;
  esac

  # 4. Детект стека + выбор адаптера
  local stack_json; stack_json=$(detect_stack "$dest")
  local adapter_file=""
  for adapter in "$SITE_INSTALL_ADAPTERS"/*.sh; do
    [[ -f "$adapter" ]] || continue
    [[ "$(basename "$adapter")" == "_contract.sh" ]] && continue
    source "$adapter"
    if declare -F adapter_matches >/dev/null && adapter_matches "$stack_json"; then
      adapter_file="$adapter"
      break
    fi
  done

  if [[ -z "$adapter_file" ]]; then
    err "Не найден подходящий адаптер для этого проекта"
    return 1
  fi
  ok "Адаптер: $(basename "$adapter_file")"

  # 5. Домен (опц.)
  local domain=""; local ssl="no"
  local want_domain
  want_domain=$(ui_radio "Домен" "Как настраивать домен?" \
    "LOCAL" "Только локальный URL" on \
    "DOMAIN" "Свой домен (с настройкой DNS)" off \
    "DOMAIN_SSL" "Свой домен + SSL (Let's Encrypt)" off) || return 0
  case "$want_domain" in
    LOCAL) domain="" ;;
    DOMAIN|DOMAIN_SSL)
      domain=$(ui_input "Доменное имя" "example.com")
      domain_check_dns "$domain" || true
      [[ "$want_domain" == "DOMAIN_SSL" ]] && ssl="yes"
      ;;
  esac

  # 6. Проверка места
  local proj_size; proj_size=$(size_bytes "$dest")
  if ! check_disk_space "$proj_size" "$dest"; then
    return 1
  fi

  # 7. Запуск шагов
  run_install "$dest" "$adapter_file" "$domain" "$ssl"
}

# run_install: основной пайплайн установки
# run_install <project_path> <adapter_file> <domain> <ssl>
run_install() {
  local dest="$1" adapter_file="$2" domain="$3" ssl="$4"
  local project_name; project_name=$(basename "$dest")

  source "$SITE_INSTALL_LIB/state.sh"
  source "$SITE_INSTALL_LIB/log.sh"
  source "$SITE_INSTALL_LIB/apt.sh"
  source "$SITE_INSTALL_LIB/apache.sh"
  source "$SITE_INSTALL_LIB/mysql.sh"
  source "$SITE_INSTALL_LIB/domain.sh"
  source "$SITE_INSTALL_LIB/env.sh"
  source "$SITE_INSTALL_LIB/migrate.sh"

  # Подгружаем адаптер
  source "$adapter_file"
  local apt_pkgs=()
  while IFS= read -r line; do apt_pkgs+=("$line"); done < <(adapter_apt_packages)
  local apache_mods=()
  while IFS= read -r line; do apache_mods+=("$line"); done < <(adapter_apache_modules)
  local env_prompts
  env_prompts=$(adapter_env_prompts "$domain")

  state_init
  log_init
  log_rotate

  # Глобальные переменные для step()
  export PROJECT_NAME="$project_name"
  export DEST="$dest"

  # Шаги в фиксированном порядке
  step "apt_packages"  install_apt_packages  "${apt_pkgs[@]}"
  step "apache_modules" enable_apache_modules "${apache_mods[@]}"

  if [[ -n "$domain" ]]; then
    local vhost_content
    vhost_content=$(make_vhost "$domain" "$dest/public" "$dest" "fpm" "$ssl")
    step "vhost"        apply_vhost          "$domain" "$vhost_content" "$dest"
    if [[ "$ssl" == "yes" ]]; then
      local email
      email=$(ui_input "Email для Let's Encrypt" "admin@$domain")
      step "ssl_cert" setup_ssl "$domain" "$email"
    fi
  fi

  step "mysql_db"      mysql_setup_wizard
  step "env_generated" generate_env         "$dest" "$env_prompts"
  step "migrations"    run_migrations       "$dest"

  ok "Установка завершена!"
  ui_msgbox "Готово" "Проект $project_name установлен в $dest\n\nURL: ${domain:+https://$domain}${domain:-локально}"
}

# Обёртка для шага: проверяет is_step_done, вызывает функцию, обновляет state
# step <step_name> <func_name> <func_args...>
step() {
  local name="$1" func="$2"
  shift 2

  if is_step_done "$PROJECT_NAME" "$name"; then
    log_skip "$name"
    return 0
  fi

  set_step "$PROJECT_NAME" "$name" "in_progress" "$DEST"
  if "$func" "$@"; then
    set_step "$PROJECT_NAME" "$name" "done"
  else
    set_step "$PROJECT_NAME" "$name" "failed"
    err "Шаг «$name» не выполнен"
    return 1
  fi
}

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
  ui_msgbox "WIP" "Мастер новой установки появится в Task 12"
}

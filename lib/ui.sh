#!/usr/bin/env bash
# ui.sh — единая обёртка над whiptail/dialog

set -euo pipefail

# Определяем, что доступно
WHIPTAIL_BIN=""
if command -v whiptail >/dev/null 2>&1; then
  WHIPTAIL_BIN="whiptail"
elif command -v dialog >/dev/null 2>&1; then
  WHIPTAIL_BIN="dialog"
else
  err "Не найден whiptail или dialog. Установите: apt-get install -y whiptail"
  return 1 2>/dev/null || exit 1
fi

# Все UI-функции используют переменную для swap на dialog
_ui() {
  "$WHIPTAIL_BIN" "$@"
}

# Menu: возвращает TAG выбранного пункта
ui_menu() {
  local title="$1" prompt="$2"
  shift 2
  local height=18 width=70 menuheight=10
  _ui --title "$title" --menu "$prompt" $height $width $menuheight -- "${@}" 3>&1 1>&2 2>&3
}

# Radiolist: возвращает TAG выбранного
ui_radio() {
  local title="$1" prompt="$2"
  shift 2
  _ui --title "$title" --radiolist "$prompt" 18 70 10 -- "${@}" 3>&1 1>&2 2>&3
}

# Checklist: возвращает TAG выбранных (через пробел)
ui_checklist() {
  local title="$1" prompt="$2"
  shift 2
  _ui --title "$title" --checklist "$prompt" 18 70 10 -- "${@}" 3>&1 1>&2 2>&3
}

# Inputbox: возвращает введённое значение
ui_input() {
  local label="$1" default="${2:-}"
  if [[ -n "$default" ]]; then
    _ui --title "Ввод" --inputbox "$label" 10 60 "$default" 3>&1 1>&2 2>&3
  else
    _ui --title "Ввод" --inputbox "$label" 10 60 3>&1 1>&2 2>&3
  fi
}

# Passwordbox: возвращает введённое (скрыто)
ui_password() {
  _ui --title "Пароль" --passwordbox "$1" 10 60 3>&1 1>&2 2>&3
}

# Msgbox: показывает сообщение
ui_msgbox() {
  _ui --title "$1" --msgbox "$2" 12 70
}

# Yesno: возвращает 0 если Yes, 1 если No
ui_yesno() {
  _ui --title "Подтверждение" --yesno "$1" 12 70
}

# Textbox: показывает содержимое файла
ui_textbox() {
  _ui --title "$2" --textbox "$1" 22 80
}

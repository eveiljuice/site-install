#!/usr/bin/env bash
set -euo pipefail
# Заглушка — реализация в Task 7
ui_menu() {
  whiptail --menu "$1" 18 70 10 --cancel-button Exit -- "${@:2}" 3>&1 1>&2 2>&3
}
ui_msgbox() {
  whiptail --msgbox "$2" 10 60 --title "$1" 3>&1 1>&2 2>&3
}
ui_input() {
  local label="$1" default="${2:-}"
  [[ -n "$default" ]] && whiptail --inputbox "$label" 10 60 "$default" 3>&1 1>&2 2>&3 \
                       || whiptail --inputbox "$label" 10 60 3>&1 1>&2 2>&3
}
ui_password() {
  whiptail --passwordbox "$1" 10 60 3>&1 1>&2 2>&3
}
ui_yesno() {
  whiptail --yesno "$1" 10 60 --title "Подтверждение" 3>&1 1>&2 2>&3
}
ui_radio() {
  whiptail --radiolist "$2" 18 70 10 -- "${@:3}" 3>&1 1>&2 2>&3
}

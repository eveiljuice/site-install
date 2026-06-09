#!/usr/bin/env bash
# sizes.sh — подсчёт размера, прогноз свободного места

set -euo pipefail

# Размер папки в байтах
size_bytes() {
  local path="$1"
  if [[ -d "$path" ]]; then
    du -sb "$path" 2>/dev/null | awk '{print $1}'
  elif [[ -f "$path" ]]; then
    stat -c%s "$path" 2>/dev/null || stat -f%z "$path"
  else
    echo 0
  fi
}

# Форматирование байтов в человеко-читаемый вид
size_human() {
  local bytes="${1:-0}"
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec-i --suffix=B "$bytes" 2>/dev/null || echo "${bytes}B"
  else
    if   (( bytes >= 1073741824 )); then echo "$((bytes / 1073741824))GiB"
    elif (( bytes >= 1048576 ));    then echo "$((bytes / 1048576))MiB"
    elif (( bytes >= 1024 ));       then echo "$((bytes / 1024))KiB"
    else echo "${bytes}B"
    fi
  fi
}

# Проверка свободного места в точке монтирования
# check_disk_space <needed_bytes> <target_path>
# Возвращает 0 если хватает (или пользователь подтвердил), 1 если отмена
check_disk_space() {
  local needed_bytes="$1"
  local target_path="$2"
  local avail_bytes
  avail_bytes=$(df -B1 "$(dirname "$target_path")" 2>/dev/null | awk 'NR==2 {print $4}')

  if (( needed_bytes > avail_bytes )); then
    if [[ -t 0 ]] && command -v whiptail >/dev/null 2>&1; then
      local msg="Недостаточно места!\n\nНужно: $(size_human "$needed_bytes")\nДоступно: $(size_human "$avail_bytes")\n\nПродолжить всё равно?"
      if whiptail --yesno "$msg" 12 60 --title "Мало места" 3>&1 1>&2 2>&3; then
        return 0
      fi
    else
      err "Недостаточно места: нужно $(size_human "$needed_bytes"), доступно $(size_human "$avail_bytes")"
      return 1
    fi
  fi
  return 0
}

# Показать инфу о размере (для dry-run)
show_size_forecast() {
  local path="$1"
  local current_size avail_bytes forecast

  current_size=$(size_bytes "$path")
  avail_bytes=$(df -B1 "$(dirname "$path")" 2>/dev/null | awk 'NR==2 {print $4}')
  forecast=$(( current_size * 110 / 100 ))  # +10% запас

  echo "=== Прогноз размера ==="
  echo "  Проект: $path"
  echo "  Текущий размер: $(size_human "$current_size")"
  echo "  Свободно в целевой папке: $(size_human "$avail_bytes")"
  echo "  После установки (прогноз): $(size_human "$forecast")"
}

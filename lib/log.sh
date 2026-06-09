#!/usr/bin/env bash
# log.sh — логирование, progress-gauge, sanitize

set -euo pipefail

LOG_DIR="${LOG_DIR:-/tmp}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/site-install-$(date +%Y%m%d-%H%M%S).log}"

# Sanitize — заменяет секреты в выводе
sanitize() {
  sed -E \
    -e 's/(password|passwd|pass|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^ &"]*/\1=***REDACTED***/gi' \
    -e 's/(MYSQL_PWD)[[:space:]]*=[[:space:]]*[^ &"]*/\1=***REDACTED***/gi' \
    -e 's/(Authorization:[[:space:]]*Bearer[[:space:]]+)[^ &"]*/\1***/gi'
}

# Progress-gauge: запускает список команд, показывая whiptail-gauge
# Использование: run_with_progress "Title" <step_count> <cmd1> <cmd2> ...
# Возвращает 0 если все команды успешны, 1 если хоть одна упала или пользователь нажал Esc
run_with_progress() {
  local title="$1"
  local total="${2:-1}"
  shift 2
  local cmds=("$@")
  local exit_code=0

  if [[ ${#cmds[@]} -eq 0 ]]; then
    err "run_with_progress: нет команд для выполнения"
    return 1
  fi

  local pipe
  pipe=$(mktemp -u)
  mkfifo "$pipe"

  # Запускаем команды в под-шелле с выводом в gauge
  (
    set +e
    local step=0
    for cmd in "${cmds[@]}"; do
      step=$((step + 1))
      local pct=$(( (step - 1) * 100 / total ))
      echo "XXX"
      echo "$pct"
      echo "$title [$step/$total]"
      echo "$cmd"
      echo "XXX"
      echo "==> Выполняю: $cmd" | tee -a "$LOG_FILE"

      # Выполняем с sanitize
      local output
      output=$(eval "$cmd" 2>&1 | sanitize)
      local rc=$?
      echo "$output" | tee -a "$LOG_FILE"
      if [[ $rc -ne 0 ]]; then
        echo "STEP FAILED ($rc): $cmd" | tee -a "$LOG_FILE"
        echo "$rc" > /tmp/.site-install.exit
        exit $rc
      fi
    done
    echo "0" > /tmp/.site-install.exit
  ) > "$pipe" &

  local gauge_pid=$!

  # Показываем gauge
  whiptail --gauge "$title" 10 70 0 < "$pipe"
  local gauge_rc=$?

  wait "$gauge_pid" 2>/dev/null || true
  rm -f "$pipe"

  if [[ $gauge_rc -ne 0 ]]; then
    # Пользователь нажал Esc
    return 1
  fi

  local step_exit
  step_exit=$(cat /tmp/.site-install.exit 2>/dev/null || echo "1")
  rm -f /tmp/.site-install.exit
  return "$step_exit"
}

# Пропуск шага (лог)
log_skip() {
  ok "Пропуск (уже выполнено): $1"
}

# Инициализация лог-файла
log_init() {
  : > "$LOG_FILE"
  chmod 600 "$LOG_FILE"
  echo "==> site-install log started $(date -Iseconds)" > "$LOG_FILE"
}

# Ротация старых логов (старше 7 дней)
log_rotate() {
  find "$LOG_DIR" -name 'site-install-*.log' -mtime +7 -delete 2>/dev/null || true
}

#!/usr/bin/env bash
# state.sh — управление state.json (идемпотентность установки)

set -euo pipefail

STATE_DIR="${STATE_DIR:-$HOME/.config/site-install}"
STATE_FILE="${STATE_FILE:-$STATE_DIR/state.json}"
STATE_LOCK="${STATE_DIR}/state.lock"

state_init() {
  mkdir -p "$STATE_DIR"
  if [[ ! -f "$STATE_FILE" ]]; then
    echo '{"version":1,"projects":{}}' > "$STATE_FILE"
    chmod 600 "$STATE_FILE"
  fi
}

# Получить блок проекта
get_project_state() {
  local name="$1"
  [[ -f "$STATE_FILE" ]] || return 1
  jq -r ".projects[\"$name\"] // empty" "$STATE_FILE"
}

# Проверить, выполнен ли шаг
is_step_done() {
  local name="$1" step="$2"
  [[ -f "$STATE_FILE" ]] || return 1
  local val
  val=$(jq -r ".projects[\"$name\"].steps[\"$step\"] // empty" "$STATE_FILE")
  [[ "$val" == "done" ]]
}

# Установить статус шага (атомарно, с flock)
# set_step <project> <step> <status> [project_path]
set_step() {
  local name="$1" step="$2" status="$3" project_path="${4:-}"

  state_init

  (
    flock -w 10 200
    local current
    current=$(cat "$STATE_FILE")
    local tmp; tmp=$(mktemp)

    jq --arg name "$name" \
       --arg step "$step" \
       --arg status "$status" \
       --arg path "$project_path" \
       --arg ts "$(date -Iseconds)" \
       '.version = 1 |
        .projects[$name] = (
          (.projects[$name] // {}) |
          (if $path != "" then .project_path = $path else . end) |
          .steps = ((.steps // {}) + {($step): $status}) |
          .updated_at = $ts
        )' \
       <<< "$current" > "$tmp"

    mv "$tmp" "$STATE_FILE"
    chmod 600 "$STATE_FILE"
  ) 200>"$STATE_LOCK"
}

# Удалить проект из state
remove_project() {
  local name="$1"
  state_init
  (
    flock -w 10 200
    local tmp; tmp=$(mktemp)
    jq --arg name "$name" 'del(.projects[$name])' "$STATE_FILE" > "$tmp"
    mv "$tmp" "$STATE_FILE"
  ) 200>"$STATE_LOCK"
}

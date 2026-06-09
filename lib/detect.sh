#!/usr/bin/env bash
# detect.sh — детектор стека проекта

set -euo pipefail

detect_stack() {
  local path="$1"
  local -a markers=()
  local entry_type="unknown"
  local webroot="."
  local db="none"
  local has_env=false
  local has_mig=false
  local has_cron=false
  local has_docker=false

  [[ -f "$path/composer.json" ]]    && markers+=("php")
  [[ -f "$path/package.json" ]]     && markers+=("node")
  [[ -f "$path/requirements.txt" ]] && markers+=("python")
  [[ -f "$path/pyproject.toml" ]]   && markers+=("python")
  [[ -f "$path/go.mod" ]]           && markers+=("go")
  [[ -f "$path/Gemfile" ]]          && markers+=("ruby")

  # Entry type
  if [[ -f "$path/index.php" ]]; then
    entry_type="php"
  elif [[ -f "$path/index.js" || -f "$path/server.js" ]]; then
    entry_type="node"
  elif [[ -f "$path/app.py" || -f "$path/main.py" ]]; then
    entry_type="python"
  fi

  # Webroot
  for candidate in public web htdocs www; do
    if [[ -d "$path/$candidate" ]]; then
      webroot="$candidate"
      break
    fi
  done

  # DB (через composer.json require)
  if [[ -f "$path/composer.json" ]]; then
    if grep -qi "mysql\|mariadb"  "$path/composer.json" 2>/dev/null; then
      db="mysql"
    elif grep -qi "pgsql\|postgres" "$path/composer.json" 2>/dev/null; then
      db="pgsql"
    elif grep -qi "sqlite" "$path/composer.json" 2>/dev/null; then
      db="sqlite"
    fi
  fi

  # Флаги
  [[ -f "$path/.env.example" ]] && has_env=true
  [[ -d "$path/database/migrations" || -d "$path/migrations" ]] && has_mig=true
  [[ -d "$path/cron" ]] && has_cron=true
  [[ -f "$path/Dockerfile" || -f "$path/docker-compose.yml" ]] && has_docker=true

  # Формируем JSON
  local markers_json="[]"
  if [[ ${#markers[@]} -gt 0 ]]; then
    markers_json=$(printf '"%s",' "${markers[@]}" | sed 's/,$//')
    markers_json="[${markers_json}]"
  fi

  cat <<EOF
{
  "markers": ${markers_json},
  "entry_type": "${entry_type}",
  "webroot": "${webroot}",
  "db": "${db}",
  "has_env_example": ${has_env},
  "has_migrations": ${has_mig},
  "has_cron": ${has_cron},
  "has_docker": ${has_docker}
}
EOF
}

#!/usr/bin/env bash
# migrate.sh — запуск миграций

set -euo pipefail

run_migrations() {
  local project_path="$1"

  if [[ ! -d "$project_path/database/migrations" ]]; then
    log_skip "migrations: папка не найдена"
    return 0
  fi

  run_with_progress "Применение миграций" 1 \
    "cd '$project_path' && php database/migrate.php"
}

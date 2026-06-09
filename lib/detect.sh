#!/usr/bin/env bash
set -euo pipefail
# Заглушка — реализация в Task 8
detect_stack() {
  local path="$1"
  cat <<JSON
{"markers":[],"entry_type":"unknown","webroot":".","db":"none","has_env_example":false,"has_migrations":false,"has_cron":false,"has_docker":false}
JSON
}

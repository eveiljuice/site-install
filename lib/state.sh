#!/usr/bin/env bash
set -euo pipefail
# Заглушка — реализация в Task 5
STATE_DIR="${HOME}/.config/site-install"
STATE_FILE="${STATE_DIR}/state.json"
get_project_state() { echo ""; }
is_step_done() { return 1; }
set_step() { :; }

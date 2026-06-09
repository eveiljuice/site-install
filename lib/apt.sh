#!/usr/bin/env bash
# apt.sh — установка apt-пакетов

set -euo pipefail

# Проверить, какие пакеты уже установлены
apt_missing_packages() {
  local -a missing=()
  for pkg in "$@"; do
    if ! dpkg -s "$pkg" 2>/dev/null | grep -q "Status: install ok"; then
      missing+=("$pkg")
    fi
  done
  printf '%s\n' "${missing[@]}"
}

# Установить список пакетов (идемпотентно)
install_apt_packages() {
  local -a pkgs=("$@")
  local -a missing
  mapfile -t missing < <(apt_missing_packages "${pkgs[@]}")

  if [[ ${#missing[@]} -eq 0 ]]; then
    log_skip "apt: все пакеты уже установлены"
    return 0
  fi

  local -a steps=(
    "apt-get update -qq"
    "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ${missing[*]}"
  )

  run_with_progress "Установка apt-пакетов (${#missing[@]})" "${#steps[@]}" "${steps[@]}"
}

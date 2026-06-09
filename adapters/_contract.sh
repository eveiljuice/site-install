#!/usr/bin/env bash
# _contract.sh — валидатор контракта адаптера

REQUIRED_FUNCTIONS=(
  "adapter_name"
  "adapter_matches"
  "adapter_describe"
  "adapter_apt_packages"
  "adapter_apache_modules"
  "adapter_vhost_template"
  "adapter_env_prompts"
  "adapter_post_install"
  "adapter_migrate"
)

# validate_adapter <path-to-adapter.sh>
# Возвращает 0 если адаптер валиден, 1 если нет.
# Печатает список отсутствующих функций.
validate_adapter() {
  local file="$1"
  local -a missing=()

  # Source в под-шелле чтобы не загрязнять текущий
  (
    source "$file" 2>/dev/null
    for fn in "${REQUIRED_FUNCTIONS[@]}"; do
      if ! declare -F "$fn" >/dev/null; then
        echo "$fn"
      fi
    done
  )
}

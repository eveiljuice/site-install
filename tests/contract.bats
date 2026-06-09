#!/usr/bin/env bats

load 'test_helper'

setup() {
  source "$ADAPTERS_DIR/_contract.sh"
}

@test "validate_adapter: валидный адаптер (php-mysql) проходит" {
  result=$(validate_adapter "$ADAPTERS_DIR/php-mysql.sh")
  [[ -z "$result" ]]
}

@test "validate_adapter: пустой файл невалиден" {
  tmp=$(mktemp)
  result=$(validate_adapter "$tmp")
  [[ -n "$result" ]]
  rm -f "$tmp"
}

@test "validate_adapter: адаптер с одной функцией невалиден" {
  tmp=$(mktemp)
  echo "adapter_name() { echo 'bad'; }" > "$tmp"
  result=$(validate_adapter "$tmp")
  # Должно быть 8 отсутствующих
  count=$(echo "$result" | wc -l)
  [[ "$count" -ge 8 ]]
  rm -f "$tmp"
}

#!/usr/bin/env bats

load 'test_helper'

setup() {
  source "$LIB_DIR/sizes.sh"
}

# Создаём фикстуру с известным размером
create_fixture_with_size() {
  local dir; dir=$(mktemp -d)
  # 1 MB файл
  dd if=/dev/zero of="$dir/file1mb.bin" bs=1024 count=1024 2>/dev/null
  # 2 MB файл
  dd if=/dev/zero of="$dir/file2mb.bin" bs=1024 count=2048 2>/dev/null
  echo "$dir"
}

@test "size_bytes: возвращает размер папки в байтах" {
  dir=$(create_fixture_with_size)
  size=$(size_bytes "$dir")
  # Допускаем погрешность (overhead файловой системы)
  [ "$size" -ge 3145728 ]  # 3 MB
  [ "$size" -lt  4194304 ]  # < 4 MB
  rm -rf "$dir"
}

@test "size_human: форматирует байты в человеко-читаемый вид" {
  result=$(size_human 1048576)  # 1 MB
  [[ "$result" == *"M"* ]] || [[ "$result" == *"MiB"* ]]
}

@test "check_disk_space: возвращает 0 если места хватает" {
  dir=$(create_fixture_with_size)
  run check_disk_space 1 "/tmp"
  [ "$status" -eq 0 ]
  rm -rf "$dir"
}

@test "check_disk_space: возвращает 1 если места не хватает" {
  # Запрашиваем 99999999999999 байт — заведомо больше свободного
  run check_disk_space 99999999999999 "/tmp"
  [ "$status" -eq 1 ]
}

@test "show_size_forecast: показывает инфу о проекте" {
  dir=$(create_fixture_with_size)
  result=$(show_size_forecast "$dir" 2>&1)
  [[ "$result" == *"Размер"* ]] || [[ "$result" == *"size"* ]] || [[ "$result" == *"KB"* ]] || [[ "$result" == *"MB"* ]]
  rm -rf "$dir"
}

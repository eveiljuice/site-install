#!/usr/bin/env bash
# mysql.sh — создание/использование MySQL БД

set -euo pipefail

# Результат сохраняется в массиве MYSQL_RESULT: [name, user, pass, host]
MYSQL_RESULT=()

# Тест подключения к MySQL
mysql_test_connection() {
  local host="$1" user="$2" pass="$3" db="${4:-}"
  if [[ -n "$pass" ]]; then
    MYSQL_PWD="$pass" mysql -h "$host" -u "$user" -e "SELECT 1" "$db" >/dev/null 2>&1
  else
    mysql -h "$host" -u "$user" -e "SELECT 1" "$db" >/dev/null 2>&1
  fi
}

# Генерация пароля
mysql_generate_password() {
  local length="${1:-24}"
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
}

# Создать новую БД + пользователя
mysql_create() {
  local db_name="$1" db_user="$2" db_pass="$3"
  local -a steps=(
    "mysql -e \"CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci\""
    "mysql -e \"CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}'\""
    "mysql -e \"GRANT ALL ON \`${db_name}\`.* TO '${db_user}'@'localhost'\""
    "mysql -e \"FLUSH PRIVILEGES\""
  )
  run_with_progress "Создание БД и пользователя MySQL" "${#steps[@]}" "${steps[@]}"
  MYSQL_RESULT=("$db_name" "$db_user" "$db_pass" "localhost")
}

# Использовать существующую БД
mysql_use_existing() {
  local host="$1" user="$2" pass="$3" db="$4"
  if ! mysql_test_connection "$host" "$user" "$pass" "$db"; then
    err "Не удалось подключиться к MySQL: $host / $db / $user"
    return 1
  fi
  ok "Подключение к MySQL успешно"
  MYSQL_RESULT=("$db" "$user" "$pass" "$host")
}

# Использовать локальный root
mysql_use_local_root() {
  local pass="$1"
  if ! mysql_test_connection "localhost" "root" "$pass"; then
    err "Не удалось подключиться как root"
    return 1
  fi
  ok "Подключение как root успешно"
  MYSQL_RESULT=("realestate_db" "root" "$pass" "localhost")
}

# Wizard: 3 режима MySQL
mysql_setup_wizard() {
  local mode
  mode=$(ui_radio "MySQL" "Как настроить базу данных?" \
    "new"      "Создать новую БД + пользователя" on \
    "existing" "Использовать существующую" off \
    "local"    "Локальный root (без пароля)" off) || return 1

  case "$mode" in
    new)
      local db_name db_user db_pass
      db_name=$(ui_input "Имя БД" "realestate_db")
      db_user=$(ui_input "Пользователь" "realestate_user")
      db_pass=$(mysql_generate_password 24)
      mysql_create "$db_name" "$db_user" "$db_pass"
      ok "Создан пользователь: $db_user (пароль: $db_pass)"
      ;;
    existing)
      local host name user pass
      host=$(ui_input "DB host" "localhost")
      name=$(ui_input "DB name" "")
      user=$(ui_input "DB user" "")
      pass=$(ui_password "DB password")
      mysql_use_existing "$host" "$user" "$pass" "$name"
      ;;
    local)
      local rpass
      rpass=$(ui_password "Пароль root MySQL (пусто = без пароля)")
      mysql_use_local_root "$rpass"
      ;;
  esac
}

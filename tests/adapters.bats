#!/usr/bin/env bats

load 'test_helper'

setup() {
  source "$ADAPTERS_DIR/php-mysql.sh"
}

@test "php-mysql: adapter_name возвращает 'php-mysql'" {
  [ "$(adapter_name)" = "php-mysql" ]
}

@test "php-mysql: matches для PHP+MySQL" {
  stack='{"entry_type":"php","db":"mysql"}'
  adapter_matches "$stack"
}

@test "php-mysql: НЕ matches для Node" {
  stack='{"entry_type":"node","db":"none"}'
  ! adapter_matches "$stack"
}

@test "php-mysql: НЕ matches для PHP+Postgres" {
  stack='{"entry_type":"php","db":"pgsql"}'
  ! adapter_matches "$stack"
}

@test "php-mysql: env_prompts содержит APP_URL первым" {
  output=$(adapter_env_prompts "https://example.com")
  first_line=$(echo "$output" | head -1)
  [[ "$first_line" == "APP_URL|"* ]]
  [[ "$first_line" == *"https://example.com"* ]]
}

@test "php-mysql: apt_packages содержит php8.1-fpm" {
  output=$(adapter_apt_packages)
  echo "$output" | grep -q "php8.1-fpm"
}

@test "php-mysql: vhost_template содержит ServerName" {
  output=$(adapter_vhost_template "example.com" "/var/www/x/public" "/var/www/x" "fpm" "no")
  echo "$output" | grep -q "ServerName example.com"
}

#!/usr/bin/env bats

load 'test_helper'

setup() {
  source "$LIB_DIR/detect.sh"
}

@test "detect_stack: PHP-проект с composer.json и MySQL" {
  result=$(detect_stack "$FIXTURES_DIR/php-mysql")
  entry=$(echo "$result" | jq -r '.entry_type')
  db=$(echo "$result" | jq -r '.db')
  has_mig=$(echo "$result" | jq -r '.has_migrations')

  [ "$entry" = "php" ]
  [ "$db" = "mysql" ]
  [ "$has_mig" = "true" ]
}

@test "detect_stack: находит webroot в public/" {
  mkdir -p "$FIXTURES_DIR/_test/with-public"
  echo "{}" > "$FIXTURES_DIR/_test/with-public/composer.json"
  echo "<?php" > "$FIXTURES_DIR/_test/with-public/index.php"
  mkdir "$FIXTURES_DIR/_test/with-public/public"
  result=$(detect_stack "$FIXTURES_DIR/_test/with-public")
  webroot=$(echo "$result" | jq -r '.webroot')
  [ "$webroot" = "public" ]
  rm -rf "$FIXTURES_DIR/_test"
}

@test "detect_stack: Node-проект определяется" {
  result=$(detect_stack "$FIXTURES_DIR/node")
  entry=$(echo "$result" | jq -r '.entry_type')
  [ "$entry" = "node" ]
}

@test "detect_stack: пустая папка — unknown" {
  result=$(detect_stack "$FIXTURES_DIR/empty")
  entry=$(echo "$result" | jq -r '.entry_type')
  db=$(echo "$result" | jq -r '.db')
  [ "$entry" = "unknown" ]
  [ "$db" = "none" ]
}

@test "detect_stack: has_env_example = true если есть .env.example" {
  result=$(detect_stack "$FIXTURES_DIR/php-mysql")
  val=$(echo "$result" | jq -r '.has_env_example')
  [ "$val" = "true" ]
}

@test "detect_stack: возвращает валидный JSON" {
  result=$(detect_stack "$FIXTURES_DIR/php-mysql")
  echo "$result" | jq -e . >/dev/null
}

@test "detect_stack: has_cron = true если есть cron/" {
  mkdir -p "$FIXTURES_DIR/_test/with-cron"
  mkdir "$FIXTURES_DIR/_test/with-cron/cron"
  result=$(detect_stack "$FIXTURES_DIR/_test/with-cron")
  val=$(echo "$result" | jq -r '.has_cron')
  [ "$val" = "true" ]
  rm -rf "$FIXTURES_DIR/_test"
}

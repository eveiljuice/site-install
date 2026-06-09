#!/usr/bin/env bats

load 'test_helper'

setup() {
  source "$LIB_DIR/log.sh"
}

@test "sanitize: пароли в KEY=VALUE заменяются на ***" {
  echo "password=secret123" | sanitize
}

@test "sanitize: токены заменяются" {
  echo "API_TOKEN=abc.def.ghi" | sanitize
}

@test "sanitize: обычный текст не трогается" {
  echo "Reading package lists..." | sanitize
}

@test "sanitize: MYSQL_PWD заменяется" {
  echo "MYSQL_PWD=hidden running query" | sanitize
}

@test "sanitize: регистронезависимо (PASSWORD тоже)" {
  echo "Password=hunter2 logged" | sanitize
}

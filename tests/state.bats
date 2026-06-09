#!/usr/bin/env bats

load 'test_helper'

setup() {
  export HOME="$(mktemp -d)"
  export TEST_STATE_DIR="$HOME/.config/site-install"
  mkdir -p "$TEST_STATE_DIR"
  source "$LIB_DIR/state.sh"
}

teardown() {
  rm -rf "$HOME"
}

@test "state.sh: STATE_FILE указывает на ~/.config/site-install/state.json" {
  [ "$STATE_FILE" = "$HOME/.config/site-install/state.json" ]
}

@test "state.sh: state_dir создаётся автоматически" {
  rm -rf "$TEST_STATE_DIR"
  state_init
  [ -d "$TEST_STATE_DIR" ]
}

@test "state.sh: set_step создаёт state.json и записывает шаг" {
  state_init
  set_step "testproj" "apt_packages" "done"
  [ -f "$STATE_FILE" ]
  result=$(jq -r '.projects.testproj.steps.apt_packages' "$STATE_FILE")
  [ "$result" = "done" ]
}

@test "state.sh: set_step обновляет существующий шаг" {
  state_init
  set_step "testproj" "apt_packages" "in_progress"
  set_step "testproj" "apt_packages" "done"
  result=$(jq -r '.projects.testproj.steps.apt_packages' "$STATE_FILE")
  [ "$result" = "done" ]
}

@test "state.sh: is_step_done возвращает true для done" {
  state_init
  set_step "testproj" "vhost" "done"
  is_step_done "testproj" "vhost"
}

@test "state.sh: is_step_done возвращает false для pending" {
  state_init
  set_step "testproj" "vhost" "pending"
  ! is_step_done "testproj" "vhost"
}

@test "state.sh: is_step_done возвращает false для несуществующего проекта" {
  state_init
  ! is_step_done "unknown" "vhost"
}

@test "state.sh: set_step сохраняет project_path" {
  state_init
  set_step "testproj" "apt_packages" "done" "/var/www/test"
  result=$(jq -r '.projects.testproj.project_path' "$STATE_FILE")
  [ "$result" = "/var/www/test" ]
}

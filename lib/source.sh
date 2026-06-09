#!/usr/bin/env bash
# source.sh — получение проекта из разных источников

set -euo pipefail

# Клонирование git
source_git() {
  local url="$1" dest="$2"
  git clone --depth=1 "$url" "$dest"
}

# Распаковка zip
source_zip() {
  local zip_path="$1" dest="$2"

  if [[ ! -f "$zip_path" ]]; then
    err "ZIP-файл не найден: $zip_path"
    return 1
  fi

  local tmp; tmp=$(mktemp -d)
  unzip -q "$zip_path" -d "$tmp/extract"

  # Определяем корень архива: если в extract/ ровно одна папка — берём её, иначе берём содержимое
  local entries; entries=$(find "$tmp/extract" -maxdepth 1 -mindepth 1 | wc -l)
  if [[ "$entries" -eq 1 ]] && [[ -d "$tmp/extract"/* ]]; then
    shopt -s dotglob nullglob
    mv "$tmp/extract"/*/* "$dest/" 2>/dev/null || mv "$tmp/extract"/* "$dest/"
    shopt -u dotglob nullglob
  else
    shopt -s dotglob nullglob
    mv "$tmp/extract"/* "$dest/"
    shopt -u dotglob nullglob
  fi
  rm -rf "$tmp"
}

# Копирование локальной папки
source_local() {
  local src="$1" dest="$2"
  if [[ ! -d "$src" ]]; then
    err "Папка не найдена: $src"
    return 1
  fi
  mkdir -p "$dest"
  shopt -s dotglob
  cp -a "$src/." "$dest/"
  shopt -u dotglob
}

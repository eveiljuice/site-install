#!/usr/bin/env bash
# install.sh — установка site-install в /usr/local/
# Использование: curl -fsSL https://raw.githubusercontent.com/eveiljuice/site-install/main/bootstrap/install.sh | sudo bash

set -euo pipefail

REPO="https://github.com/eveiljuice/site-install.git"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
VERSION="${VERSION:-main}"

if [[ $EUID -ne 0 ]]; then
  echo "Запустите: curl ... | sudo bash"
  exit 1
fi

# Зависимости
echo "==> Установка зависимостей (whiptail, git, jq)"
apt-get update -qq
apt-get install -y -qq git whiptail jq

# Клонируем / обновляем /opt/site-install
if [[ -d /opt/site-install ]]; then
  echo "==> Обновление /opt/site-install"
  git -C /opt/site-install fetch --all --prune
  git -C /opt/site-install checkout "$VERSION"
  git -C /opt/site-install pull
else
  echo "==> Клонирование site-install"
  git clone --depth=1 -b "$VERSION" "$REPO" /opt/site-install
fi

# Копируем файлы
echo "==> Установка файлов в $INSTALL_PREFIX"
mkdir -p "$INSTALL_PREFIX/share/site-install/lib"
mkdir -p "$INSTALL_PREFIX/share/site-install/adapters"
# cp -r SRC/. DST/ копирует СОДЕРЖИМОЕ SRC в DST (надёжнее чем cp -r SRC DST/ в edge-case с существующим подкаталогом)
cp -r /opt/site-install/lib/.      "$INSTALL_PREFIX/share/site-install/lib/"
cp -r /opt/site-install/adapters/. "$INSTALL_PREFIX/share/site-install/adapters/"
cp /opt/site-install/bin/site-install "$INSTALL_PREFIX/bin/site-install"
chmod +x "$INSTALL_PREFIX/bin/site-install"

# State-каталог
mkdir -p /root/.config/site-install
chmod 700 /root/.config/site-install

echo ""
echo "✓ Установлено: site-install $($INSTALL_PREFIX/bin/site-install --version 2>/dev/null || echo '0.1.0')"
echo ""
echo "Запуск:       sudo site-install"
echo "Документация: https://github.com/eveiljuice/site-install#readme"

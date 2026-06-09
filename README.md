# site-install

Интерактивный TUI-установщик PHP/MySQL/Apache-сайтов с автодетектом стека,
идемпотентностью, прогресс-баром и опциональным SSL через Let's Encrypt.

## Возможности

- 🆕 **Новая установка** за один проход: источник → детект стека → apt-пакеты → Apache vhost → SSL → MySQL → .env → миграции
- 📂 **Идемпотентность** через `~/.config/site-install/state.json` — пропускает уже сделанные шаги
- 📊 **Подсчёт размера** до установки + прогноз свободного места
- 🔌 **Расширяемость** через адаптеры (`adapters/*.sh`) с фиксированным контрактом
- 🔒 **Безопасность** — секреты только в `.env` (chmod 600), sanitize логов
- 🪪 **SSL одной кнопкой** через Let's Encrypt + certbot

## Установка

```bash
curl -fsSL https://raw.githubusercontent.com/eveiljuice/site-install/main/bootstrap/install.sh | sudo bash
```

Требования: Debian/Ubuntu 20.04+ с `apt` и `sudo`.

## Использование

```bash
sudo site-install
```

Главное меню:
- **🆕 Новая установка** — пошаговый визард
- **❌ Выход**

## CLI

```bash
sudo site-install --help         # справка
sudo site-install --version      # версия
sudo site-install --list         # список установленных проектов
sudo site-install --dry-run PATH # показать план без изменений
```

## Поддерживаемые стеки

| Стек | Адаптер | Статус |
|---|---|---|
| PHP 8.1 + MySQL + Apache | `php-mysql` | ✅ MVP |
| Node / Python / Go | (планируется) | 🔜 Контракт готов |

## Документация

Подробная инструкция: [docs/USAGE.md](docs/USAGE.md)

## Лицензия

MIT

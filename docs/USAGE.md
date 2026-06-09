# USAGE — Подробная инструкция

## Сценарий 1: установка нового сайта

1. `sudo site-install` → "🆕 Новая установка"
2. Выбрать источник: `Git` / `ZIP` / `Локальная папка`
3. Ввести URL/путь
4. Подтвердить директорию установки (по умолчанию `/var/www/<basename>`)
5. Дождаться клонирования/распаковки
6. Детектор покажет стек, подтвердить
7. Домен: `Только локальный` / `Свой домен` / `Свой домен + SSL`
8. Если выбран домен — будет DNS-проверка (warning если не совпадает с IP сервера)
9. MySQL: `Создать новую` / `Использовать существующую` / `Локальный root`
10. Заполнить поля `.env` (whiptail-формы)
11. Дождаться миграций
12. Финал: URL сайта, логин/пароль (если генерили)

## Сценарий 2: прерывание и возобновление

Если на шаге N нажат Esc:
- Текущий шаг → `failed` в state.json
- Остальные → `pending`
- Повторный запуск `site-install` пропустит `done`-шаги и начнёт с неудачного

## Сценарий 3: обновление сертификата

Сертификаты Let's Encrypt обновляются автоматически через `certbot.timer`.
Проверить вручную: `sudo certbot renew --dry-run`.

## Отладка

Оперативный лог: `/tmp/site-install-YYYYMMDD-HHMMSS.log` — показывает весь вывод apt/mysql/certbot с редактированием секретов.

State: `~/.config/site-install/state.json` — текущее состояние установок.

## Удаление проекта

В MVP нет встроенного uninstaller. Удаление вручную:

```bash
# 1. Удалить VirtualHost
sudo a2dissite example.com.conf
sudo rm /etc/apache2/sites-available/example.com.conf

# 2. Удалить SSL (если был)
sudo certbot delete --cert-name example.com

# 3. Удалить БД и пользователя
sudo mysql -e "DROP DATABASE realestate_db"
sudo mysql -e "DROP USER 'realestate_user'@'localhost'"

# 4. Удалить папку проекта
sudo rm -rf /var/www/myproject

# 5. Удалить из state
rm -rf ~/.config/site-install/state.json
```

## Написание адаптера

Адаптер — это `*.sh` файл в `adapters/`, экспортирующий 9 функций:

- `adapter_name` — возвращает имя
- `adapter_matches <stack_json>` — 0 если подходит
- `adapter_describe` — описание для чек-листа
- `adapter_apt_packages` — список пакетов
- `adapter_apache_modules` — модули
- `adapter_vhost_template <domain> <webroot> <project_path> <php_mode> <ssl>` — VirtualHost
- `adapter_env_prompts <app_url>` — поля для `.env` (формат `key|label|default`)
- `adapter_post_install <project_path>` — composer install, npm ci
- `adapter_migrate <project_path>` — запуск миграций

Валидация: `source adapters/_contract.sh && validate_adapter /path/to/your-adapter.sh`.

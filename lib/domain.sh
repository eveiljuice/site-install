#!/usr/bin/env bash
# domain.sh — ввод домена, DNS-проверка, SSL

set -euo pipefail

# Получить IP текущего сервера
server_ip() {
  # Берём первый не-localhost IPv4
  hostname -I 2>/dev/null | awk '{print $1}' | head -1
}

# Проверить DNS A-запись домена
domain_dns_ip() {
  local domain="$1"
  dig +short "$domain" A 2>/dev/null | head -1 | grep -E '^[0-9.]+$' || echo ""
}

# Проверить, что DNS указывает на нас
domain_check_dns() {
  local domain="$1"
  local dns_ip; dns_ip=$(domain_dns_ip "$domain")
  local my_ip; my_ip=$(server_ip)

  if [[ -z "$dns_ip" ]]; then
    warn "DNS A-запись для $domain не найдена"
    return 2  # не критично
  elif [[ "$dns_ip" != "$my_ip" ]]; then
    warn "DNS $domain → $dns_ip, IP сервера $my_ip"
    return 2
  fi
  ok "DNS $domain → $my_ip ✓"
  return 0
}

# Получить SSL-сертификат
setup_ssl() {
  local domain="$1" email="$2"

  local -a steps=(
    "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq certbot python3-certbot-apache"
    "certbot certonly --apache --non-interactive --agree-tos -m '$email' -d '$domain'"
    "systemctl enable certbot.timer"
  )

  if ! run_with_progress "Получение SSL (Let's Encrypt)" "${#steps[@]}" "${steps[@]}"; then
    warn "SSL не получен. Сайт будет работать по http://"
    return 1
  fi

  # Проверка автопродления (не критично)
  if certbot renew --dry-run >/dev/null 2>&1; then
    ok "Автопродление SSL проверено ✓"
  else
    warn "Автопродление не проверено. Запустите позже: sudo certbot renew --dry-run"
  fi
  return 0
}

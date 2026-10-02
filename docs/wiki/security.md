# Безопасность

Полная политика — в [`SECURITY.md`](https://github.com/kprklg/ansible-cobbler/blob/main/SECURITY.md)
на GitHub.

## Краткая сводка

### Поддерживаемые версии

| Version | Поддержка |
|---|---|
| v1.1.x | ✅ активно |
| v1.0.x | ❌ устаревшая |

### Что делает роль

- ✅ Создаёт пароль через SHA3-512 (Cobbler 4 default)
- ✅ Использует `iptables` для NAT (без внешнего доступа к PXE)
- ✅ `no-new-privileges` + `label:disable` для traefik
- ✅ Монтирует `/var/run/docker.sock` **только в traefik** (read-only)

### Что нужно проверить

- ⚠️ Смените дефолтный пароль (`cobbler/cobbler`) перед production
- ⚠️ Закройте Traefik dashboard (`127.0.0.1:8082`) если не нужен
- ⚠️ Не выставляйте macvlan `eth0.10` в интернет без firewall
- ⚠️ HTTPS не реализован — добавьте reverse-proxy с Let's Encrypt

### Сообщить об уязвимости

Не создавайте публичный issue. Отправьте через:

- GitHub Security Advisories: https://github.com/kprklg/ansible-cobbler/security/advisories/new

Ожидайте ответа в течение 3 рабочих дней.
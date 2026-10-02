# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| v1.1.x  | ✅ активно         |
| v1.0.x  | ❌ устаревшая      |

## Reporting a Vulnerability

Если вы нашли уязвимость в этой Ansible-роли или в собранных ею Docker-образах:

1. **Не создавайте публичный issue** — это может подвергнуть пользователей риску.
2. Отправьте описание в **приватном порядке** через один из каналов ниже.

### Каналы для security-репортов

- GitHub Security Advisories: https://github.com/kprklg/ansible-cobbler/security/advisories/new
- Email: см. профиль автора

### Что включить в репорт

- Описание уязвимости
- Шаги для воспроизведения
- Версия роли (`git rev-parse HEAD`)
- Версия Cobbler (из `docker inspect cobbler/ghcr.io/cobbler/cobblerd:latest`)
- Версия Ansible (`ansible --version`)
- Возможные последствия (что атакующий может сделать)

### Чего ожидать

- Подтверждение получения в течение **3 рабочих дней**
- Оценка серьёзности в течение **7 рабочих дней**
- Патч в течение **30 дней** (для критических — быстрее)
- Координация раскрытия (disclosure date) по договорённости

## Безопасность роли

### Что делает роль

- Создаёт пароль для Web UI (`cobbler_default_password`) и хранит его
  в `users.digest` (SHA3-512)
- Использует `iptables` для NAT MASQUERADE (без внешнего доступа к PXE)
- Использует `no-new-privileges` и `label:disable` для traefik
- Монтирует `/var/run/docker.sock` **только в traefik** (read-only)

### Что нужно проверить самостоятельно

- **Смените пароль по умолчанию** (`cobbler` / `cobbler`) перед использованием
  в production
- **Закройте Traefik dashboard** (`127.0.0.1:8082`) если не нужен — порт уже
  привязан к localhost
- **Не выставляйте** macvlan `eth0.10` в интернет без firewall
- **Используйте HTTPS** при публикации Web UI в общую сеть (в текущей роли
  это не реализовано — добавьте reverse-proxy с Let's Encrypt перед Traefik)

### Известные CVE в зависимостях

| Пакет | CVE | Влияние на роль |
|---|---|---|
| — | — | Нет известных критических уязвимостей |

Следите за обновлениями:
- https://github.com/cobbler/cobbler/releases
- https://hub.docker.com/_/traefik
- https://github.com/docker/compose/releases
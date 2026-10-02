# Docker-стек

Роль поднимает 7 контейнеров через `docker compose`:

## Сервисы

### traefik (reverse-proxy)

- **Образ**: `traefik:v3.6`
- **Порты**: `0.0.0.0:80`, `127.0.0.1:8082` (dashboard)
- **Назначение**: маршрутизация запросов к нужному контейнеру

Маршруты:

```yaml
- "traefik.http.routers.cobbler-web.rule=PathPrefix(`/`)"
- "traefik.http.routers.cobbler-api.rule=PathPrefix(`/cobbler_api`)"
- "traefik.http.routers.cobbler-http-api.rule=PathPrefix(`/cblr`) || PathPrefix(`/httpboot`) || PathPrefix(`/images`)"
```

### cobblerd (ядро)

- **Образ**: `cobbler/cobblerd-patched:latest` (собран ролью)
- **Команда**: `cobblerd -F` (foreground)
- **Порты**: `8000/tcp`, `25151/tcp` (XML-RPC)
- **Назначение**: основное ядро Cobbler, обслуживает XML-RPC API

### http-api (HTTP вместо XML-RPC)

- **Образ**: `cobbler/cobblerd-patched:latest` (тот же, другая команда)
- **Команда**: `gunicorn cobbler.services:application --bind 0.0.0.0:8000`
- **Порты**: `8000/tcp`, `25151/tcp`
- **Назначение**: HTTP API для preseed/kickstart (cobbler-web использует его)

### web (Angular UI)

- **Образ**: `cobbler/cobbler-web-patched:latest` (собран ролью)
- **Основа**: nginx-unprivileged
- **Порты**: `8080/tcp` (внутренний)
- **Назначение**: веб-интерфейс Cobbler

### cobbler-dhcp

- **Образ**: `ghcr.io/cobbler/cobbler-dhcp:latest`
- **Команда**: `dhcpd -f -cf /etc/dhcp/dhcpd.conf`
- **Сеть**: cobbler-pxe (macvlan)
- **Назначение**: DHCP-сервер для PXE-клиентов

### cobbler-dns

- **Образ**: `cobbler/cobbler-dns-patched:latest` (собран ролью)
- **Основа**: BIND9
- **Сеть**: cobbler-pxe (macvlan)
- **Назначение**: DNS-сервер (форвардер + локальные зоны)

### cobbler-tftp

- **Образ**: `ghcr.io/cobbler/cobbler-tftp:latest`
- **Порты**: `6969/udp`
- **Назначение**: TFTP-сервер для PXE-boot файлов

## Сети

### cobbler (bridge, internal)

- Подсеть: `10.17.0.0/16`
- Все контейнеры, кроме DHCP/DNS

### cobbler-pxe (macvlan, external)

- Подсеть: `cobbler_pxe_network` (по умолчанию `10.254.254.0/24`)
- Подключены: cobbler-dhcp, cobbler-dns, cobbler-tftp, cobbler-web
- Создаётся через `docker network create ... --driver macvlan --parent eth0.10`

## Порядок запуска

```yaml
depends_on:
  web:
    condition: service_started  # web после всего
```

Traefik запускается последним (после web), чтобы все роуты уже были доступны.

## Полезные команды

```bash
# Статус всех контейнеров
docker ps --filter name=cobbler-stack

# Логи конкретного сервиса
docker logs cobbler-stack-cobblerd-1 --tail 50

# Все логи в реальном времени
cd /opt/cobbler-stack && docker compose logs -f

# Перезапустить сервис
cd /opt/cobbler-stack && docker compose restart cobblerd
```

## Пересборка только одного образа

```bash
docker rmi cobbler/cobblerd-patched:latest
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags build
```
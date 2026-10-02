# Ansible Role: cobbler

[![Version v1.1.0](https://img.shields.io/badge/version-v1.1.0-brightgreen)](../../releases/tag/v1.1.0)
[![License MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![lint](https://github.com/kprklg/ansible-cobbler/actions/workflows/lint.yml/badge.svg)](../../actions/workflows/lint.yml)
[![syntax-check](https://github.com/kprklg/ansible-cobbler/actions/workflows/syntax-check.yml/badge.svg)](../../actions/workflows/syntax-check.yml)
[![aarch64-smoke](https://github.com/kprklg/ansible-cobbler/actions/workflows/aarch64-smoke.yml/badge.svg)](../../actions/workflows/aarch64-smoke.yml)

> 📚 **Документация:** [README](README.md) (вы здесь) ·
> [PREREQUISITES](PREREQUISITES.md) ·
> [ARCHITECTURE](ARCHITECTURE.md) ·
> [TROUBLESHOOTING](TROUBLESHOOTING.md) ·
> [CHANGELOG](CHANGELOG.md) ·
> [SECURITY](SECURITY.md) ·
> [CODE_OF_CONDUCT](CODE_OF_CONDUCT.md)

> 👥 **Участники:** Сообщить о баге через [bug report](../../issues/new?template=bug_report.md),
> предложить улучшение через [feature request](../../issues/new?template=feature_request.md),
> или прочитать [Contributor Covenant](CODE_OF_CONDUCT.md) перед PR.

Устанавливает PXE-провижининг сервер **Cobbler 4.x** на Raspberry Pi (aarch64) или любой x86_64-хост с Debian/Ubuntu.

> Роль **полностью автономная**: все артефакты (`compose.yml`, `Dockerfile`'ы, патчи, webroot) генерируются из upstream-образов `ghcr.io/cobbler/*`. Бэкапы и предварительно подготовленные файлы не требуются.

---

## ⚠ Что нужно сделать ДО запуска плейбука

Плейбук устанавливает Cobbler, но **предварительно на хосте должны быть установлены** пакеты и настроена сеть. Без этого роль не запустится или сломается в середине.

### 1. Установить системные пакеты (вручную)

```bash
apt-get update
apt-get install -y \
  ca-certificates curl gnupg git \
  ansible ansible-core \
  qemu-user-static binfmt-support \
  iptables-persistent netfilter-persistent \
  python3 python3-yaml python3-passlib

# preseed для неинтерактивной установки iptables-persistent
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
```

### 2. Установить Docker **из официального репозитория** (НЕ `docker.io` из Debian)

```bash
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-rootless-extras docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
```

### 3. Убедиться, что сеть соответствует требованиям

- **2 сетевых интерфейса**: один с интернетом (wlan0 / eth1), второй для PXE (eth0)
- На хостах **aarch64**: проверить работу эмуляции x86_64
  ```bash
  docker run --rm --platform linux/amd64 alpine:3.20 uname -m
  # Должно вернуть: x86_64
  ```

### 4. Создать инвентарь и переменные (обязательно)

Роль **не знает** ваших IP-адресов и имён интерфейсов — их нужно задать вручную. Пример:

```bash
mkdir -p inventories/myhost/group_vars
```

```yaml
# inventories/myhost/hosts.yml
---
all:
  children:
    cobbler:
      hosts:
        rasp01:
          ansible_host: 192.168.0.88
          ansible_connection: local
          ansible_become: yes
```

```yaml
# inventories/myhost/group_vars/all.yml
---
# Сеть
cobbler_mgmt_ip: "192.168.0.88"      # IP для Web UI (cobbler-web)
cobbler_pxe_iface: "eth0"            # PXE-интерфейс (патч-корд к коммутатору)
cobbler_wifi_iface: "wlan0"          # Интернет-интерфейс (NAT для PXE-клиентов)
cobbler_pxe_network: "10.254.254.0/24"  # Подсеть для PXE-клиентов
cobbler_pxe_ip: "10.254.254.1/24"    # IP macvlan-интерфейса

# Аутентификация Web UI
cobbler_default_user: "cobbler"
cobbler_default_password: "cobbler"
```

### 5. Запустить плейбук

```bash
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

**Время выполнения:**
- Pre-flight, зависимости, сеть: ~1 мин
- Сборка 3 patched-образов: ~15-20 мин на RPi 4 (qemu-эмуляция x86_64), 3-5 мин на x86_64
- Запуск контейнеров + инициализация: ~3-5 мин
- **Итого: ~25 минут на Raspberry Pi**

---

## ✅ Что делает роль автоматически

| Этап | Что делается |
|---|---|
| `preflight` | Проверка архитектуры, Docker, compose |
| `dependencies` | Установка qemu, iptables-persistent (apt) |
| `network` (macvlan) | Создание `eth0.10` через systemd-networkd |
| `network` (nat) | IP forwarding + iptables NAT MASQUERADE |
| `compose` | Генерация `compose.yml`, Dockerfile'ов, patch-скриптов |
| `webroot` | Извлечение webroot из `cobbler-web:v1.2.0` |
| `build` | Сборка 3 patched-образов через `docker buildx` |
| `volumes` | Создание Docker volumes + дефолтные конфиги (`users.digest`, `dhcpd.conf`, `named.conf`) |
| `stack` | `docker compose up -d` всего стека |
| `systemd` | Установка `cobbler-recover.service` для автозапуска |

---

## Требования к хосту

| Параметр | Минимум | Рекомендуется |
|---|---|---|
| **Платформа** | Debian 12 / Ubuntu 22.04 | Debian 13 / Ubuntu 24.04 |
| **Архитектура** | aarch64 / x86_64 | — |
| **Ansible** | ≥ 2.14 | 2.19+ |
| **Коллекции** | `community.docker ≥ 4.0` | `community.docker ≥ 4.7` |
| **Python** | ≥ 3.11 | 3.13 |
| **RAM** | 2 GB | 4 GB (для сборки 3 образов) |
| **Свободное место** | 5 GB | 10 GB (Docker-образы + volumes) |
| **Сеть** | 1 Ethernet (PXE) + 1 интерфейс с интернетом | — |

---

## Поддерживаемые архитектуры

| Arch | Эмуляция | qemu-user-static | Производительность сборки |
|------|----------|------------------|---------------------------|
| **aarch64** (RPi 3/4/5) | ✅ через qemu | устанавливается автоматически | ~5-10× медленнее |
| **x86_64** (Intel/AMD) | ❌ не нужна | НЕ устанавливается | нативная |

---

## CI / автотесты

Каждый push и PR в `main` запускает 4 workflow:

| Workflow | Что проверяет |
|---|---|
| [`lint.yml`](../../actions/workflows/lint.yml) | `yamllint` (strict) + `ansible-lint` для роли, плейбуков и инвентарей |
| [`syntax-check.yml`](../../actions/workflows/syntax-check.yml) | `ansible-playbook --syntax-check` для всех плейбуков на Ansible 2.14-2.19 |
| [`aarch64-smoke.yml`](../../actions/workflows/aarch64-smoke.yml) | рендеринг Jinja-шаблонов на реальном ARM runner + проверка, что в финальном `compose.yml` нет IPv4-адресов с CIDR-маской |
| [`release.yml`](../../actions/workflows/release.yml) | автоматическое создание GitHub Release при пуше тега `v*.*.*` (с changelog) |

Включён **Dependabot** для GitHub Actions и Docker.

---

## После установки

| Действие | Команда |
|---|---|
| Открыть Web UI | `http://192.168.0.88/` (логин cobbler/cobbler) |
| Проверить статус контейнеров | `docker ps --filter name=cobbler-stack` |
| Посмотреть логи | `cd /opt/cobbler-stack && docker compose logs -f` |
| Импортировать дистрибутив | `docker exec -it cobbler-stack-cobblerd-1 cobbler import --path=/mnt --name=ubuntu-22.04 --arch=x86_64` |
| Включить автозапуск | `systemctl enable --now cobbler-recover` (включено автоматически) |

---

## Переменные роли

### Сеть

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_mgmt_ip` | `ansible_host` | IP хоста для Web UI |
| `cobbler_pxe_iface` | `eth0` | Физический интерфейс для PXE |
| `cobbler_wifi_iface` | `wlan0` | Интерфейс для NAT в интернет |
| `cobbler_pxe_network` | `10.254.254.0/24` | Подсеть PXE-клиентов |
| `cobbler_pxe_ip` | `10.254.254.1/24` | IP macvlan-интерфейса |
| `cobbler_mgmt_network` | `10.17.0.0/16` | Внутренняя docker-сеть для cobbler |
| `cobbler_macvlan_configure_without_carrier` | `true` | Работать даже без кабеля в eth0 |

### Аутентификация

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_default_user` | `cobbler` | Web UI логин |
| `cobbler_default_password` | `cobbler` | Web UI пароль |

### Установка

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_workdir` | `/opt/cobbler-stack` | Рабочая директория |
| `cobbler_web_image_version` | `v1.2.0` | Версия `cobbler-web` |
| `cobbler_skip_builds` | `false` | Не пересобирать образы (использовать кэш) |
| `cobbler_skip_webroot` | `false` | Не извлекать webroot из upstream |
| `cobbler_rebuild_images` | `false` | Принудительная пересборка |
| `cobbler_qemu_emulation` | `auto` | Когда ставить qemu: `always`, `auto`, `never` |
| `cobbler_supported_archs` | `[aarch64, x86_64]` | Список поддерживаемых архитектур |

### Systemd

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_systemd_service_name` | `cobbler-recover` | Имя systemd-сервиса |
| `cobbler_systemd_timeout` | `300` | Таймаут systemd (сек) |

Полный список — `roles/cobbler/defaults/main.yml`.

---

## Теги

| Тег | Описание |
|---|---|
| `preflight` | Проверки архитектуры, Docker, compose |
| `dependencies` | apt install |
| `network` | macvlan + NAT |
| `macvlan` | Только macvlan |
| `nat` | Только NAT |
| `compose` | Генерация compose + Dockerfile'ов |
| `build` / `images` | Сборка образов |
| `webroot` | Извлечение webroot из upstream |
| `volumes` / `config` | Создание volumes |
| `stack` / `deploy` | `docker compose up` |
| `systemd` / `autostart` | cobbler-recover.service |

---

## Changelog

### v1.1.0 — aarch64 / Ansible 2.19 / Cobbler 4 compatibility

- `fix(preflight)`: убраны Jinja-разделители в условии `assert`
- `fix(macvlan)`: переименование `eth0-host` → `eth0.10` (требование Docker 25+ к именам VLAN)
- `fix(stack)`: миграция на `ipam_config` (community.docker 4.x)
- `fix(stack)`: `pull: no` / `build: no` → `pull: never` / `build: never`
- `fix(stack)`: исправлена CIDR-нотация для iprange
- `fix(stack)`: Traefik bind `0.0.0.0:80` (для local-приложений и health-check)
- `fix(compose)`: добавлен отсутствующий `templates/named.conf.j2`
- `fix(compose)`: переменные `mgmt_ip` / `pxe_network` → `cobbler_mgmt_ip` / `cobbler_pxe_network`
- `fix(compose)`: `ipaddr('+N')` → `| ipaddr('address')` для IPv4 без маски
- `fix(volumes)`: Go-template `{{.Name}}` экранирован в `{% raw %}`
- `fix(patch-remote)`: учтена многострочная сигнатура `get_valid_distro_boot_loaders` в Cobbler 4
- `fix(deps)`: убрана принудительная установка `docker.io` поверх `docker-ce`
- `fix(volumes)`: генерация `users.digest` через `hashlib.sha3_512` (Cobbler 4 по умолчанию)
- `fix(cobbler-recover)`: префикс `cobbler_` у переменных шаблона
- `chore(playbook)`: объявлена коллекция `ansible.utils` для фильтра `ipaddr`
- `chore(ansible.cfg)`: подключена папка `filter_plugins`

См. подробности: [v1.1.0 release](../../releases/tag/v1.1.0) или `git log b756cd5..v1.1.0`.

### v1.0.0

Начальная версия. Работала только на x86_64 с Docker 24+ и старыми версиями community.docker.

---

## Известные ограничения

- **`nginx-unprivileged` в `web`-контейнере** на aarch64: 4 из 5 worker падают с `io_setup() failed (Function not implemented)` из-за qemu-эмуляции. Master-worker обрабатывает все запросы, Web UI работает, но с пониженной производительностью. Лечится добавлением `aio threads;` в `/etc/nginx/conf.d/default.conf` образа web.

---

## Структура роли

```
cobbler/
├── defaults/main.yml       # Переменные по умолчанию
├── meta/main.yml           # Galaxy метаданные
├── handlers/main.yml       # Handlers
├── tasks/                  # Tasks
│   ├── main.yml            # Включает остальные
│   ├── preflight.yml
│   ├── dependencies.yml
│   ├── macvlan.yml
│   ├── nat.yml
│   ├── compose.yml
│   ├── webroot.yml
│   ├── images.yml
│   ├── volumes.yml
│   ├── stack.yml
│   └── systemd.yml
└── templates/              # Jinja-шаблоны
    ├── compose.yml.j2
    ├── cobbler-recover.sh.j2
    ├── Dockerfile.cobbler.j2
    ├── Dockerfile.cobbler-web.j2
    ├── Dockerfile.cobbler-dns.j2
    ├── patch-remote.py.j2
    ├── patch-manager.py.j2
    ├── patch-nginx.sh.j2
    ├── entrypoint.sh.j2
    └── named.conf.j2
```

---

## Лицензия

MIT

## Автор

MiniMax-M3 (rasp01 team)
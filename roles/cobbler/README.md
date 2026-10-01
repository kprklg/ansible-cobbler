# Ansible Role: cobbler

Устанавливает PXE-провижининг сервер Cobbler 4.x на Raspberry Pi (aarch64, Debian 12/13).

**Полностью автономная роль.** Все артефакты (compose.yml, Dockerfile'ы, патчи, webroot) генерируются ролью из upstream-образов `ghcr.io/cobbler/*`. Не требует бэкапов или предварительно подготовленных файлов.

## Требования

- **Платформа**: Debian 12/13 или Ubuntu 22.04/24.04
- **Архитектура**:
  - **aarch64** (Raspberry Pi 3/4/5) — используется qemu-эмуляция x86_64
  - **x86_64** (Intel/AMD) — нативный запуск, без эмуляции
- **Ansible**: >= 2.14
- **Collections**: `community.docker`
- **Сеть**: 1 Ethernet-порт (для PXE) + 1 Wi-Fi/2-й Ethernet (для интернета)

## Поддерживаемые архитектуры

| Arch | Эмуляция | qemu-user-static | Производительность |
|------|----------|------------------|---------------------|
| **aarch64** (RPi 3/4/5) | ✅ через qemu | устанавливается | медленнее (5-10x) |
| **x86_64** (Intel/AMD) | ❌ не нужна | НЕ устанавливается | нативная скорость |

## Использование

```yaml
# playbook.yml
- hosts: rasp01
  become: yes
  roles:
    - cobbler
```

```ini
# inventory.yml
[raspberry]
rasp01 ansible_host=192.168.0.88

[raspberry:vars]
cobbler_mgmt_ip=192.168.0.88
```

```bash
ansible-playbook -i inventory.yml playbook.yml
```

## Переменные роли

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_mgmt_ip` | `ansible_host` | IP хоста для Web UI |
| `cobbler_pxe_iface` | `eth0` | Физический интерфейс для PXE |
| `cobbler_wifi_iface` | `wlan0` | Интерфейс для NAT |
| `cobbler_pxe_network` | `10.254.254.0/24` | Подсеть PXE |
| `cobbler_pxe_ip` | `10.254.254.1/24` | IP macvlan |
| `cobbler_workdir` | `/opt/cobbler-stack` | Рабочая директория |
| `cobbler_default_user` | `cobbler` | Web UI логин |
| `cobbler_default_password` | `cobbler` | Web UI пароль |
| `cobbler_web_image_version` | `v1.2.0` | Версия cobbler-web |
| `cobbler_rebuild_images` | `false` | Принудительная пересборка |
| `cobbler_skip_builds` | `false` | Пропустить docker build |
| `cobbler_skip_webroot` | `false` | Пропустить извлечение webroot |
| `cobbler_supported_archs` | `[aarch64, x86_64]` | Список поддерживаемых архитектур |
| `cobbler_qemu_emulation` | `auto` | Когда ставить qemu: `always`, `auto`, `never` |
| `cobbler_macvlan_configure_without_carrier` | `true` | Работать без кабеля |
| `cobbler_systemd_service_name` | `cobbler-recover` | Имя systemd-сервиса |
| `cobbler_systemd_timeout` | `300` | Таймаут systemd (сек) |

Полный список — `defaults/main.yml`.

## Теги

| Тег | Описание |
|---|---|
| `preflight` | Проверки архитектуры, Docker, compose |
| `dependencies` | apt install |
| `network` | macvlan + NAT |
| `macvlan` | Только macvlan |
| `nat` | Только NAT |
| `compose` | Генерация compose + Dockerfile'ов |
| `build` | Сборка образов |
| `images` | Алиас для build |
| `webroot` | Извлечение webroot из upstream |
| `volumes` | Создание volumes |
| `config` | Алиас для volumes |
| `stack` | docker compose up |
| `deploy` | Алиас для stack |
| `systemd` | cobbler-recover.service |
| `autostart` | Алиас для systemd |

## Зависимости

- `geerlingguy.docker` (опционально, для установки Docker)

## Лицензия

MIT

## Автор

MiniMax-M3 (rasp01 team)

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
    └── entrypoint.sh.j2
```
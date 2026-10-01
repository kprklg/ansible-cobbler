# Ansible Role: cobbler

[![Ansible Role](https://img.shields.io/badge/ansible-role-blue.svg)](https://docs.ansible.com/ansible/latest/playbook_guide/index.html)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Устанавливает PXE-провижининг сервер Cobbler 4.x на Debian/Ubuntu хосты.

**Полностью автономная роль.** Все артефакты (compose.yml, Dockerfile'ы, патчи, webroot) генерируются ролью из upstream-образов `ghcr.io/cobbler/*`. Не требует бэкапов или предварительно подготовленных файлов.

## ✨ Возможности

- 🐳 Docker Compose с 7 сервисами (cobblerd, http-api, web, traefik, dhcp, dns, tftp)
- 🌐 Web UI на Angular + Traefik reverse-proxy
- 🔧 Поддержка aarch64 (Raspberry Pi) и x86_64
- 📡 Persistent macvlan через systemd-networkd
- 🛡️ NAT MASQUERADE для PXE-клиентов
- 🔄 Автозапуск через systemd
- ✅ Идемпотентна (можно запускать много раз)
- 🏗️ Все патчи встроены (legacy collection aliases, port_in_redirect)

## 📋 Требования

| Компонент | Версия |
|---|---|
| Ansible | >= 2.14 |
| Collections | `community.docker` |
| Платформа | Debian 12/13 или Ubuntu 22.04/24.04 |
| Архитектура | aarch64 (RPi) или x86_64 |

## 🚀 Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone https://github.com/kprklg/ansible-cobbler.git
cd ansible-cobbler

# 2. Установить зависимости
ansible-galaxy collection install community.docker

# 3. Настроить inventory
cat > inventories/my-hosts.yml <<EOF
all:
  children:
    cobbler:
      hosts:
        my-server:
          ansible_host: 192.168.0.88
          ansible_user: root
          ansible_become: yes
EOF

# 4. Запустить установку
ansible-playbook -i inventories/my-hosts.yml playbooks/site.yml
```

После установки Web UI: **http://192.168.0.88/** (логин: `cobbler` / `cobbler`)

## 📖 Что делает роль

1. **Preflight** — проверяет архитектуру, Docker, compose
2. **Dependencies** — устанавливает Docker, qemu (на ARM), iptables-persistent
3. **macvlan** — persistent настраивает systemd-networkd
4. **NAT** — MASQUERADE для PXE-подсети
5. **Compose** — генерирует `compose.yml` и Dockerfile'ы
7. **Webroot** — извлекает Angular UI из upstream `ghcr.io/cobbler/cobbler-web:v1.2.0`
8. **Images** — собирает 3 patched-образа через qemu (на ARM)
9. **Volumes** — создаёт 7 volumes с дефолтными конфигами
10. **Stack** — `docker compose up -d`
11. **Systemd** — устанавливает `cobbler-recover.service`

## 🏗️ Поддерживаемые архитектуры

| Arch | Эмуляция | qemu-user-static | Скорость |
|---|---|---|---|
| **aarch64** (RPi 3/4/5) | ✅ через qemu | ставится | медленнее |
| **x86_64** (Intel/AMD) | ❌ нативная | НЕ ставится | быстро |

## 🎯 Использование

### Полная установка
```bash
ansible-playbook playbooks/site.yml
```

### Только запуск стека (без пересборки)
```bash
ansible-playbook playbooks/deploy.yml
```

### Пересобрать образы (после изменения патчей)
```bash
ansible-playbook playbooks/rebuild.yml
```

### Полное удаление
```bash
ansible-playbook playbooks/uninstall.yml
```

### Только конкретные шаги (по тегам)
```bash
ansible-playbook playbooks/site.yml --tags network    # только сеть
ansible-playbook playbooks/site.yml --tags stack      # только compose
ansible-playbook playbooks/site.yml --tags systemd    # только systemd
```

## ⚙️ Переменные

Все переменные в [`roles/cobbler/defaults/main.yml`](roles/cobbler/defaults/main.yml).

Основные:

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_mgmt_ip` | `ansible_host` | IP хоста для Web UI |
| `cobbler_pxe_iface` | `eth0` | Физический интерфейс для PXE |
| `cobbler_wifi_iface` | `wlan0` | Интерфейс для NAT |
| `cobbler_pxe_network` | `10.254.254.0/24` | Подсеть PXE |
| `cobbler_pxe_ip` | `10.254.254.1/24` | IP macvlan |
| `cobbler_workdir` | `/opt/cobbler-stack` | Рабочая директория |
| `cobbler_default_password` | `cobbler` | Web UI пароль |
| `cobbler_rebuild_images` | `false` | Принудительная пересборка |
| `cobbler_skip_builds` | `false` | Пропустить build |
| `cobbler_supported_archs` | `[aarch64, x86_64]` | Поддерживаемые архитектуры |
| `cobbler_qemu_emulation` | `auto` | Когда ставить qemu |

Переопределение через inventory или `-e`:
```bash
ansible-playbook playbooks/site.yml -e "
  cobbler_pxe_network=192.168.100.0/24
  cobbler_default_password=secret123
"
```

## 📁 Структура репозитория

```
.
├── README.md                            # Этот файл
├── LICENSE
├── ansible.cfg                          # конфигурация Ansible
├── playbooks/                           # разные playbook'и
│   ├── site.yml                         # полная установка
│   ├── deploy.yml                       # только deploy
│   ├── rebuild.yml                      # пересборка образов
│   └── uninstall.yml                    # удаление
├── inventories/                         # inventories для разных сред
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/all.yml
│   └── staging/
│       ├── hosts.yml
│       └── group_vars/all.yml
└── roles/
    └── cobbler/                         # Ansible-роль
        ├── README.md
        ├── LICENSE
        ├── defaults/main.yml
        ├── handlers/main.yml
        ├── meta/main.yml
        ├── tasks/                       # 11 task-файлов
        ├── templates/                   # 9 Jinja-шаблонов
        └── tests/
```

## 🔧 Структура сети

```
┌────────────────────────────────────────────────────────┐
│          Internet (через wlan0)                       │
└────────────────┬───────────────────────────────────────┘
                 │ NAT MASQUERADE (10.254.254.0/24)
                 │
┌────────────────▼───────────────────────────────────────┐
│         eth0-host (macvlan, 10.254.254.1/24)         │
│   ┌─────────────────────────────────────────────────┐ │
│   │  cobbler-pxe (docker network)                    │ │
│   │  ├── cobbler-dhcp  (10.254.254.2)               │ │
│   │  ├── cobbler-dns   (10.254.254.3)               │ │
│   │  └── cobbler-tftp  (10.254.254.4)               │ │
│   └─────────────────────────────────────────────────┘ │
│                                                         │
│   ┌─────────────────────────────────────────────────┐ │
│   │  cobbler (docker bridge 10.17.0.0/16)          │ │
│   │  ├── cobblerd     (XML-RPC :25151)             │ │
│   │  ├── http-api     (gunicorn :8000)              │ │
│   │  ├── web          (nginx :8080)                 │ │
│   │  └── traefik      (192.168.0.88:80, :8082)    │ │
│   └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                 ▲
                 │ Web UI, XML-RPC
                 │
            ┌─────────┐
            │ Browser │
            └─────────┘
```

## 🧪 Тестирование

```bash
# Синтаксис
ansible-playbook playbooks/site.yml --syntax-check

# Dry-run (без изменений)
ansible-playbook -i inventories/staging/hosts.yml playbooks/site.yml --check --diff

# Lint
ansible-lint

# Тесты роли
cd roles/cobbler && ansible-playbook tests/test_preflight.yml -i tests/inventory.yml --check
```

## 🤝 Contributing

PR приветствуются! При добавлении функциональности:
1. Обновите `roles/cobbler/defaults/main.yml` для новых переменных
3. Добавьте тег в `tasks/main.yml`
4. Обновите `README.md` и `roles/cobbler/README.md`

## 📜 Лицензия

MIT — см. [LICENSE](LICENSE)

## 🔗 Используемые upstream-проекты

- [Cobbler](https://github.com/cobbler/cobbler)
- [cobbler-web](https://github.com/cobbler/cobbler-web)
- [bind9](https://gitlab.isc.org/isc-projects/bind9)
- [isc-dhcp-server](https://www.isc.org/dhcp/)
- [tftpd-hpa](https://git.kernel.org/pub/scm/network/tftpd/tftpd-hpa.git/)
- [Traefik](https://traefik.io/)

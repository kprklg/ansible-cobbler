# Ansible Cobbler Role

> Ansible-роль для установки PXE-провижининг сервера **Cobbler 4.x** на
> Raspberry Pi (aarch64) или x86_64-хост с Debian/Ubuntu.

[![Version v1.1.0](https://img.shields.io/badge/version-v1.1.0-brightgreen)](https://github.com/kprklg/ansible-cobbler/releases/tag/v1.1.0)
[![License MIT](https://img.shields.io/badge/license-MIT-blue)](https://github.com/kprklg/ansible-cobbler/blob/main/LICENSE)
[![CI](https://github.com/kprklg/ansible-cobbler/actions/workflows/lint.yml/badge.svg)](https://github.com/kprklg/ansible-cobbler/actions)

## Что это?

Роль `cobbler` устанавливает полноценный PXE-провижининг сервер за один
`ansible-playbook`. Все артефакты (`compose.yml`, `Dockerfile`, патчи, webroot)
генерируются ролью из официальных upstream-образов `ghcr.io/cobbler/*`.

## Зачем?

Без этой роли установка Cobbler 4 на Raspberry Pi — это часы ручной работы:

- Скачать образы и пропатчить их под `cobbler-web v1.x`
- Настроить macvlan для раздачи IP PXE-клиентам
- Настроить NAT, чтобы клиенты видели интернет
- Связать 7 контейнеров через `docker compose`
- Запустить и сконфигурировать их
- Настроить systemd-автозапуск

С этой ролью — одна команда:

```bash
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

## Возможности

- 🚀 **Полностью автоматическая** установка
- 🐳 **Docker Compose** из 7 сервисов (cobblerd, web, dns, dhcp, tftp, http-api, traefik)
- 📦 **Patched upstream-образы** собираются ролью автоматически
- 🌐 **macvlan + NAT** для PXE-клиентов
- 🔄 **Systemd-автозапуск** через `cobbler-recover.service`
- 🔐 **SHA3-512** для хеша пароля (Cobbler 4 default)
- 🏛️ **aarch64 + x86_64** — на RPi через qemu-эмуляцию, на x86_64 нативно
- 📚 **Полная документация** — 8 .md файлов + эта wiki
- 🤖 **CI/CD** — 5 GitHub Actions workflows
- 🐳 **Docker-образ** для запуска роли в CI/CD пайплайнах

## Содержание

Используйте навигацию слева для подробной документации.

## Быстрый старт

```bash
# 1. Подготовьте хост (см. [Installation → Prerequisites](installation/prerequisites.md))
apt-get install -y ansible git qemu-user-static binfmt-support \
                   iptables-persistent python3-passlib
curl -fsSL https://get.docker.com | sh

# 2. Клонируйте роль
git clone https://github.com/kprklg/ansible-cobbler.git
cd ansible-cobbler
git checkout v1.1.0

# 3. Создайте инвентарь
mkdir -p inventories/myhost/group_vars
cat > inventories/myhost/hosts.yml <<'EOF'
---
all:
  children:
    cobbler:
      hosts:
        rasp01:
          ansible_host: 192.168.0.88
          ansible_connection: local
          ansible_become: yes
EOF
cat > inventories/myhost/group_vars/all.yml <<'EOF'
---
cobbler_mgmt_ip: "192.168.0.88"
cobbler_pxe_iface: "eth0"
cobbler_wifi_iface: "wlan0"
cobbler_pxe_network: "10.254.254.0/24"
cobbler_pxe_ip: "10.254.254.1/24"
cobbler_default_user: "cobbler"
cobbler_default_password: "cobbler"
EOF

# 4. Запустите (15–40 минут)
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml

# 5. Откройте Web UI
xdg-open http://192.168.0.88/   # логин: cobbler / cobbler
```

## Где задать вопросы?

- 🐛 [Bug Report](https://github.com/kprklg/ansible-cobbler/issues/new?template=bug_report.md)
- 💡 [Feature Request](https://github.com/kprklg/ansible-cobbler/issues/new?template=feature_request.md)
- 💬 [Discussions](https://github.com/kprklg/ansible-cobbler/discussions)

## Лицензия

MIT — см. [LICENSE](https://github.com/kprklg/ansible-cobbler/blob/main/LICENSE)
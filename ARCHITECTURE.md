# Architecture / Архитектура

> 🇬🇧 **English below** — see [English version](#-english)
> 🇷🇺 **Русский ниже** — см. [Русская версия](#-русский)

---

<a id="-english"></a>

# 🇬🇧 English

This document describes the architecture of the Cobbler 4 stack that this
Ansible role deploys.

## Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       Raspberry Pi 4 / x86_64 host                       │
│                                                                          │
│  wlan0 / eth1 (Internet)                                                 │
│       ▲                                                                  │
│       │ NAT (iptables MASQUERADE)                                        │
│       │ IP forwarding = 1                                                │
│       │                                                                  │
│  eth0 (PXE) ──── macvlan ──── eth0.10 (10.254.254.1/24)                  │
│       │                                                                  │
│       │ through a switch ──── to PXE clients (10.254.254.100+)           │
│       │                                                                  │
│       └──── cobbler 192.168.0.88 ──── Web UI (Traefik → nginx → cobbler-web)│
│                                                                          │
│  ┌────────────────── Docker host ──────────────────────────────────┐    │
│  │                                                                  │    │
│  │  ┌────────────┐   ┌────────────┐   ┌────────────┐               │    │
│  │  │ traefik    │   │ cobblerd   │   │ http-api   │               │    │
│  │  │ :80→0.0.0.0│   │ :25151/tcp │   │ :8000/tcp  │               │    │
│  │  │ :8082      │   │ (gunicorn) │   │ (gunicorn) │               │    │
│  │  └────────────┘   └────────────┘   └────────────┘               │    │
│  │         │                │                │                      │    │
│  │         └────────────────┴────────────────┘                │    │
│  │                          │                                    │    │
│  │                  ┌───────┴────────┐                          │    │
│  │                  │   cobbler       │                          │    │
│  │                  │   bridge        │                          │    │
│  │                  │   10.17.0.0/16  │                          │    │
│  │                  └───────┬────────┘                          │    │
│  │                          │                                    │    │
│  │  ┌────────────┐  ┌──────┴──────┐  ┌────────────┐            │    │
│  │  │ web        │  │ tftp        │  │ dhcp       │            │    │
│  │  │ :8080/tcp  │  │ :6969/udp   │  │ (DHCPv4)   │            │    │
│  │  │ (nginx)    │  │             │  │            │            │    │
│  │  └────────────┘  └─────────────┘  └────────────┘            │    │
│  │                                                              │    │
│  │  ┌────────────┐                                                     │    │
│  │  │ dns         │                                                     │    │
│  │  │ (BIND9)     │                                                     │    │
│  │  └────────────┘                                                     │    │
│  │                                                                  │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌─── Persistent volumes: ──────────────────────────────────────────┐    │
│  │ cobbler-etc         /etc/cobbler       (settings.yaml, users.*) │    │
│  │ cobbler-var-lib     /var/lib/cobbler   (objects, distros, repos) │    │
│  │ cobbler-webdir      /srv/www/cobbler   (kickstart templates)     │    │
│  │ cobbler-tftproot    /srv/tftpboot      (PXE boot files)          │    │
│  │ cobbler-dhcp-config /etc/dhcp          (dhcpd.conf)              │    │
│  │ cobbler-dns-config  /etc/bind          (named.conf)              │    │
│  │ cobbler-dns-zones   /var/lib/named     (zone files)              │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
```

## Components

### Network

| Component | Purpose | Configuration |
|---|---|---|
| `eth0` (physical) | PXE interface | link, no IP, no carrier OK |
| `eth0.10` (macvlan) | bridge mode over eth0 | IP `10.254.254.1/24`, config in `/etc/systemd/network/20-eth0.10.netdev` |
| `wlan0` (physical) | Internet interface | IP `192.168.0.88/24` (example) |
| `iptables` | MASQUERADE for PXE subnet → wlan0 | rules in `/etc/iptables/rules.v4` |
| `ip_forward` | forward packets between interfaces | `net.ipv4.ip_forward=1` |

### Docker networks

| Network | Purpose | Subnet |
|---|---|---|
| `cobbler` (bridge) | internal network between cobblerd, http-api, web, traefik, tftp, dhcp, dns | `10.17.0.0/16` |
| `cobbler-pxe` (macvlan, external) | external PXE client network via eth0.10 | `10.254.254.0/24` |

### Containers (Docker Compose)

| Service | Image | Stack role | Ports |
|---|---|---|---|
| `traefik` | `traefik:v3.6` | reverse-proxy with TLS offload + dashboard | `0.0.0.0:80`, `127.0.0.1:8082` |
| `cobblerd` | `cobbler/cobblerd-patched:latest` | Cobbler 4 core (XML-RPC API + services) | `8000/tcp`, `25151/tcp` |
| `http-api` | `cobbler/cobblerd-patched:latest` | gunicorn with HTTP API (instead of XML-RPC) | `8000/tcp`, `25151/tcp` |
| `web` | `cobbler/cobbler-web-patched:latest` | Angular UI (nginx-unprivileged) | `8080/tcp` |
| `cobbler-tftp` | `ghcr.io/cobbler/cobbler-tftp:latest` | TFTP server for PXE | `6969/udp` |
| `cobbler-dhcp` | `ghcr.io/cobbler/cobbler-dhcp:latest` | DHCPv4 to hand out IPs to PXE clients | (raw socket) |
| `cobbler-dns` | `cobbler/cobbler-dns-patched:latest` | BIND9 for DNS (forwarder + local zones) | (not exposed) |

### Patched images

All `*-patched` images are built from upstream + patches in `templates/`:

- **`cobbler/cobblerd-patched`** = upstream `ghcr.io/cobbler/cobblerd:latest`
  + `patch-remote.py` (restores `get_autoinstall_templates` /
  `get_autoinstall_snippets`) + `patch-manager.py` (legacy collection aliases)
- **`cobbler/cobbler-web-patched`** = upstream `cobbler-web:v1.2.0`
  + `patch-nginx.sh` (`port_in_redirect off`)
- **`cobbler/cobbler-dns-patched`** = upstream `cobbler-dns:latest`
  + our `entrypoint.sh` + `named.conf`

### Traefik routing rules

```
http://192.168.0.88/                → cobbler-web (Angular SPA)
http://192.168.0.88/cobbler_api     → cobbler-dns (via strip prefix → 8080)
http://192.168.0.88/cblr            → http-api (via strip prefix → 8000)
http://192.168.0.88/httpboot        → http-api
http://192.168.0.88/images          → http-api
http://127.0.0.1:8082/              → Traefik dashboard (debug only)
```

### Volumes

| Volume | Contents | Generated by role? |
|---|---|---|
| `cobbler-stack_cobbler-etc` | `settings.yaml`, `users.conf`, `users.digest`, `auth.conf`, modules | yes (if missing) |
| `cobbler-stack_cobbler-var-lib` | objects: distros, profiles, systems, repos | as cobbler works |
| `cobbler-stack_cobbler-webdir` | kickstart templates, snippets | extracted from cobbler-web image |
| `cobbler-stack_cobbler-tftproot` | PXE-boot files (pxelinux.0, grub) | generated by cobblerd |
| `cobbler-stack_cobbler-dhcp-config` | `dhcpd.conf` | yes (if missing) |
| `cobbler-stack_cobbler-dns-config` | `named.conf` (reference) | yes |
| `cobbler-stack_cobbler-dns-zones` | zone files (`forward.zone`, `reverse.zone`) | generated by cobblerd |

### Systemd

| Unit | File | Purpose |
|---|---|---|
| `cobbler-recover.service` | `/etc/systemd/system/cobbler-recover.service` | auto-start cobbler after reboot |

`cobbler-recover.sh` (run by systemd):

1. Enables IP forwarding
2. Enables promiscuous-mode on `eth0`
3. Enables macvlan `eth0.10`
4. Restores iptables rules
5. Runs `docker compose up -d`

## Client network installation process

```
1. PXE client powers on
   │
   ├─ Network card sends DHCP-Discover (broadcast)
   │
2. cobbler-dhcp receives the request
   │
   ├─ Assigns IP from 10.254.254.0/24
   ├─ next-server: 10.254.254.4 (cobbler-tftp)
   ├─ boot_file: pxelinux.0
   │
3. Client downloads pxelinux.0 via TFTP
   │
4. pxelinux loads Linux kernel + initramfs
   │
5. Linux mounts preseed/kickstart (via HTTP, http-api)
   │
6. Automatic OS installation
   │
7. Host ready with a fresh OS
```

## Role file structure

```
ansible-cobbler/
├── README.md                  # Main documentation
├── PREREQUISITES.md          # Host preparation (what to install manually)
├── TROUBLESHOOTING.md        # Common problems and solutions
├── ARCHITECTURE.md           # This file
├── CHANGELOG.md              # Change history
├── SECURITY.md               # Security policy
├── LICENSE                   # MIT
├── ansible.cfg               # Ansible config
├── requirements.yml          # Galaxy dependencies
├── filter_plugins/
│   └── ipaddr.py             # alias for ansible.utils.ipaddr
├── playbooks/
│   ├── site.yml              # Main playbook
│   ├── deploy.yml            # Deploy only
│   ├── rebuild.yml           # Rebuild images
│   └── uninstall.yml         # Uninstall
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/all.yml
│   └── staging/
│       ├── hosts.yml
│       └── group_vars/all.yml
├── roles/
│   └── cobbler/
│       ├── defaults/main.yml
│       ├── meta/main.yml
│       ├── handlers/main.yml
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── preflight.yml
│       │   ├── dependencies.yml
│       │   ├── macvlan.yml
│       │   ├── nat.yml
│       │   ├── compose.yml
│       │   ├── webroot.yml
│       │   ├── images.yml
│       │   ├── volumes.yml
│       │   ├── stack.yml
│       │   └── systemd.yml
│       └── templates/
│           ├── compose.yml.j2
│           ├── cobbler-recover.sh.j2
│           ├── Dockerfile.cobbler.j2
│           ├── Dockerfile.cobbler-web.j2
│           ├── Dockerfile.cobbler-dns.j2
│           ├── patch-remote.py.j2
│           ├── patch-manager.py.j2
│           ├── patch-nginx.sh.j2
│           ├── entrypoint.sh.j2
│           └── named.conf.j2
└── .github/
    ├── workflows/
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   └── feature_request.md
    └── PULL_REQUEST_TEMPLATE.md
```

---

<a id="-русский"></a>

# 🇷🇺 Русский

Документ описывает архитектуру стека Cobbler 4, который разворачивает
эта Ansible-роль.

## Общая картина

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       Raspberry Pi 4 / x86_64 host                       │
│                                                                          │
│  wlan0 / eth1 (Internet)                                                 │
│       ▲                                                                  │
│       │ NAT (iptables MASQUERADE)                                        │
│       │ IP forwarding = 1                                                │
│       │                                                                  │
│  eth0 (PXE) ──── macvlan ──── eth0.10 (10.254.254.1/24)                  │
│       │                                                                  │
│       │ через коммутатор ──── к PXE-клиентам (10.254.254.100+)           │
│       │                                                                  │
│       └──── cobbler 192.168.0.88 ──── Web UI (Traefik → nginx → cobbler-web)│
│                                                                          │
│  ┌────────────────── Docker host ──────────────────────────────────┐    │
│  │                                                                  │    │
│  │  ┌────────────┐   ┌────────────┐   ┌────────────┐               │    │
│  │  │ traefik    │   │ cobblerd   │   │ http-api   │               │    │
│  │  │ :80→0.0.0.0│   │ :25151/tcp │   │ :8000/tcp  │               │    │
│  │  │ :8082      │   │ (gunicorn) │   │ (gunicorn) │               │    │
│  │  └────────────┘   └────────────┘   └────────────┘               │    │
│  │         │                │                │                      │    │
│  │         └────────────────┴────────────────┘                │    │
│  │                          │                                    │    │
│  │                  ┌───────┴────────┐                          │    │
│  │                  │   cobbler       │                          │    │
│  │                  │   bridge        │                          │    │
│  │                  │   10.17.0.0/16  │                          │    │
│  │                  └───────┬────────┘                          │    │
│  │                          │                                    │    │
│  │  ┌────────────┐  ┌──────┴──────┐  ┌────────────┐            │    │
│  │  │ web        │  │ tftp        │  │ dhcp       │            │    │
│  │  │ :8080/tcp  │  │ :6969/udp   │  │ (DHCPv4)   │            │    │
│  │  │ (nginx)    │  │             │  │            │            │    │
│  │  └────────────┘  └─────────────┘  └────────────┘            │    │
│  │                                                              │    │
│  │  ┌────────────┐                                                     │    │
│  │  │ dns         │                                                     │    │
│  │  │ (BIND9)     │                                                     │    │
│  │  └────────────┘                                                     │    │
│  │                                                                  │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌─── Persistent volumes: ──────────────────────────────────────────┐    │
│  │ cobbler-etc         /etc/cobbler       (settings.yaml, users.*) │    │
│  │ cobbler-var-lib     /var/lib/cobbler   (objects, distros, repos) │    │
│  │ cobbler-webdir      /srv/www/cobbler   (kickstart templates)     │    │
│  │ cobbler-tftproot    /srv/tftpboot      (PXE boot files)          │    │
│  │ cobbler-dhcp-config /etc/dhcp          (dhcpd.conf)              │    │
│  │ cobbler-dns-config  /etc/bind          (named.conf)              │    │
│  │ cobbler-dns-zones   /var/lib/named     (zone files)              │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
```

## Компоненты

### Сеть

| Компонент | Назначение | Конфигурация |
|---|---|---|
| `eth0` (физический) | PXE-интерфейс | link, no IP, no carrier OK |
| `eth0.10` (macvlan) | bridge mode поверх eth0 | IP `10.254.254.1/24`, конфиг в `/etc/systemd/network/20-eth0.10.netdev` |
| `wlan0` (физический) | Интернет-интерфейс | IP `192.168.0.88/24` (пример) |
| `iptables` | MASQUERADE для PXE-подсети → wlan0 | правила в `/etc/iptables/rules.v4` |
| `ip_forward` | пересылка пакетов между интерфейсами | `net.ipv4.ip_forward=1` |

### Docker-сети

| Сеть | Назначение | Подсеть |
|---|---|---|
| `cobbler` (bridge) | внутренняя сеть между cobblerd, http-api, web, traefik, tftp, dhcp, dns | `10.17.0.0/16` |
| `cobbler-pxe` (macvlan, external) | внешняя сеть PXE-клиентов через eth0.10 | `10.254.254.0/24` |

### Контейнеры (Docker Compose)

| Сервис | Образ | Роль в стеке | Порты |
|---|---|---|---|
| `traefik` | `traefik:v3.6` | reverse-proxy с TLS offload + dashboard | `0.0.0.0:80`, `127.0.0.1:8082` |
| `cobblerd` | `cobbler/cobblerd-patched:latest` | ядро Cobbler 4 (XML-RPC API + services) | `8000/tcp`, `25151/tcp` |
| `http-api` | `cobbler/cobblerd-patched:latest` | gunicorn с HTTP API (вместо XML-RPC) | `8000/tcp`, `25151/tcp` |
| `web` | `cobbler/cobbler-web-patched:latest` | Angular UI (nginx-unprivileged) | `8080/tcp` |
| `cobbler-tftp` | `ghcr.io/cobbler/cobbler-tftp:latest` | TFTP-сервер для PXE | `6969/udp` |
| `cobbler-dhcp` | `ghcr.io/cobbler/cobbler-dhcp:latest` | DHCPv4 для раздачи IP PXE-клиентам | (raw socket) |
| `cobbler-dns` | `cobbler/cobbler-dns-patched:latest` | BIND9 для DNS (форвардер + локальные зоны) | (не exposed) |

### Patched-образы

Все `*-patched` образы собираются из upstream + патчи в `templates/`:

- **`cobbler/cobblerd-patched`** = upstream `ghcr.io/cobbler/cobblerd:latest`
  + `patch-remote.py` (восстанавливает `get_autoinstall_templates` /
  `get_autoinstall_snippets`) + `patch-manager.py` (legacy collection aliases)
- **`cobbler/cobbler-web-patched`** = upstream `cobbler-web:v1.2.0`
  + `patch-nginx.sh` (`port_in_redirect off`)
- **`cobbler/cobbler-dns-patched`** = upstream `cobbler-dns:latest`
  + наш `entrypoint.sh` + `named.conf`

### Traefik правила маршрутизации

```
http://192.168.0.88/                → cobbler-web (Angular SPA)
http://192.168.0.88/cobbler_api     → cobbler-dns (через strip prefix → 8080)
http://192.168.0.88/cblr            → http-api (через strip prefix → 8000)
http://192.168.0.88/httpboot        → http-api
http://192.168.0.88/images          → http-api
http://127.0.0.1:8082/              → Traefik dashboard (debug only)
```

### Volumes

| Volume | Что внутри | Генерируется ролью? |
|---|---|---|
| `cobbler-stack_cobbler-etc` | `settings.yaml`, `users.conf`, `users.digest`, `auth.conf`, modules | да (если отсутствует) |
| `cobbler-stack_cobbler-var-lib` | объекты: distros, profiles, systems, repos | по мере работы cobbler |
| `cobbler-stack_cobbler-webdir` | kickstart templates, snippets | извлекается из cobbler-web image |
| `cobbler-stack_cobbler-tftproot` | PXE-boot файлы (pxelinux.0, grub) | генерируется cobblerd |
| `cobbler-stack_cobbler-dhcp-config` | `dhcpd.conf` | да (если отсутствует) |
| `cobbler-stack_cobbler-dns-config` | `named.conf` (reference) | да |
| `cobbler-stack_cobbler-dns-zones` | zone files (`forward.zone`, `reverse.zone`) | генерируется cobblerd |

### Systemd

| Юнит | Файл | Назначение |
|---|---|---|
| `cobbler-recover.service` | `/etc/systemd/system/cobbler-recover.service` | автозапуск cobbler после reboot |

`cobbler-recover.sh` (запускается systemd):

1. Включает IP forwarding
2. Включает promiscuous-mode на `eth0`
3. Включает macvlan `eth0.10`
4. Восстанавливает iptables-правила
5. Запускает `docker compose up -d`

## Процесс установки клиента по сети

```
1. PXE-клиент включается
   │
   ├─ Сетевая карта отправляет DHCP-Discover (broadcast)
   │
2. cobbler-dhcp получает запрос
   │
   ├─ Назначает IP из 10.254.254.0/24
   ├─ next-server: 10.254.254.4 (cobbler-tftp)
   ├─ boot_file: pxelinux.0
   │
3. Клиент скачивает pxelinux.0 по TFTP
   │
4. pxelinux загружает ядро Linux + initramfs
   │
5. Linux монтирует preseed/kickstart (через HTTP, http-api)
   │
6. Автоматическая установка ОС
   │
7. Готовый хост с свежей ОС
```

## Файловая структура роли

```
ansible-cobbler/
├── README.md                  # Главная документация
├── PREREQUISITES.md          # Подготовка хоста (что ставить руками)
├── TROUBLESHOOTING.md        # Частые проблемы и решения
├── ARCHITECTURE.md           # Этот файл
├── CHANGELOG.md              # История изменений
├── SECURITY.md               # Политика безопасности
├── LICENSE                   # MIT
├── ansible.cfg               # Конфиг Ansible
├── requirements.yml          # Galaxy-зависимости
├── filter_plugins/
│   └── ipaddr.py             # Алиас для ansible.utils.ipaddr
├── playbooks/
│   ├── site.yml              # Главный плейбук
│   ├── deploy.yml            # Только запуск
│   ├── rebuild.yml           # Пересборка
│   └── uninstall.yml         # Удаление
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/all.yml
│   └── staging/
│       ├── hosts.yml
│       └── group_vars/all.yml
├── roles/
│   └── cobbler/
│       ├── defaults/main.yml
│       ├── meta/main.yml
│       ├── handlers/main.yml
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── preflight.yml
│       │   ├── dependencies.yml
│       │   ├── macvlan.yml
│       │   ├── nat.yml
│       │   ├── compose.yml
│       │   ├── webroot.yml
│       │   ├── images.yml
│       │   ├── volumes.yml
│       │   ├── stack.yml
│       │   └── systemd.yml
│       └── templates/
│           ├── compose.yml.j2
│           ├── cobbler-recover.sh.j2
│           ├── Dockerfile.cobbler.j2
│           ├── Dockerfile.cobbler-web.j2
│           ├── Dockerfile.cobbler-dns.j2
│           ├── patch-remote.py.j2
│           ├── patch-manager.py.j2
│           ├── patch-nginx.sh.j2
│           ├── entrypoint.sh.j2
│           └── named.conf.j2
└── .github/
    ├── workflows/
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   └── feature_request.md
    └── PULL_REQUEST_TEMPLATE.md
```

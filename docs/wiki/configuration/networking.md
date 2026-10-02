# Сетевые настройки

## Архитектура сети

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
│       └──── cobbler-web:80 ──── Web UI (Traefik → nginx → cobbler-web)    │
└──────────────────────────────────────────────────────────────────────────┘
```

## Docker-сети

| Сеть | Назначение | Подсеть |
|---|---|---|
| `cobbler` (bridge) | внутренняя сеть cobblerd ↔ web ↔ traefik | `10.17.0.0/16` |
| `cobbler-pxe` (macvlan, external) | PXE-клиенты через eth0.10 | `10.254.254.0/24` |

## Изменение подсети

!!! warning "После изменения `cobbler_pxe_network` нужно пересоздать docker-сеть"
    ```bash
    docker network rm cobbler-stack_cobbler-pxe 2>/dev/null
    ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags network,stack
    ```

## Firewall

Если используется ufw / firewalld, нужно открыть:

- **TCP 80** (Web UI, Traefik)
- **TCP 25151** (cobblerd XML-RPC)
- **TCP 8000** (cobbler http-api)
- **TCP 8082** (Traefik dashboard, опционально)
- **UDP 6969** (TFTP для PXE)
- **UDP 67-68** (DHCP)
- **DNS 53/UDP+TCP** (если нужен DNS от cobbler-dns)

## DNSMASQ/DHCP конфликты

Если в сети уже есть DHCP-сервер, PXE-клиенты получат IP от него,
а не от cobbler-dhcp. Решения:

- Подключить PXE-клиентов через **отдельный коммутатор** (без DHCP в нём)
- Использовать **VLAN** для изоляции PXE-подсети
- Отключить существующий DHCP на время настройки

## Без NAT

Если PXE-клиенты не должны видеть интернет (например, изолированная сеть):

1. Не включайте `cobbler_wifi_iface` в NAT-правилах
2. Установите пакеты через локальный репозиторий (`cobbler repo add`)
3. Используйте `--skip-nat` тег (если реализован)

См. `tasks/nat.yml` для подробностей.

## См. также

- [Variables Reference](variables.md) — все сетевые переменные
- [Architecture → Networking](../architecture/overview.md#networking)
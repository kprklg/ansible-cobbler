# Архитектура

## Полная картина

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
│                                                                          │
│  ┌────────────────── Docker host ──────────────────────────────────┐    │
│  │                                                                  │    │
│  │  ┌────────────┐   ┌────────────┐   ┌────────────┐               │    │
│  │  │ traefik    │   │ cobblerd   │   │ http-api   │               │    │
│  │  │ :80→0.0.0.0│   │ :25151/tcp │   │ :8000/tcp  │               │    │
│  │  │ :8082      │   │ (gunicorn) │   │ (gunicorn) │               │    │
│  │  └────────────┘   └────────────┘   └────────────┘               │    │
│  │         │                │                │                      │    │
│  │         └────────────────┴────────────────┘                      │    │
│  │                          │                                       │    │
│  │                  ┌───────┴────────┐                              │    │
│  │                  │   cobbler       │                              │    │
│  │                  │   bridge        │                              │    │
│  │                  │   10.17.0.0/16  │                              │    │
│  │                  └───────┬────────┘                              │    │
│  │                          │                                       │    │
│  │  ┌────────────┐  ┌──────┴──────┐  ┌────────────┐                │    │
│  │  │ web        │  │ tftp        │  │ dhcp       │                │    │
│  │  │ :8080/tcp  │  │ :6969/udp   │  │ (DHCPv4)   │                │    │
│  │  │ (nginx)    │  │             │  │            │                │    │
│  │  └────────────┘  └────────────┘  └────────────┘                │    │
│  │                                                                  │    │
│  │  ┌────────────┐                                                   │    │
│  │  │ dns         │                                                   │    │
│  │  │ (BIND9)     │                                                   │    │
│  │  └────────────┘                                                   │    │
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

### 1. Сетевой уровень (хост)

- **eth0** — физический интерфейс для PXE. Должен быть в состоянии UP, но без IP.
- **eth0.10** — macvlan-интерфейс в режиме bridge, поверх eth0. Получает `cobbler_pxe_ip` (по умолчанию `10.254.254.1/24`).
- **wlan0 / eth1** — интерфейс с интернетом. IP forwarding + NAT MASQUERADE направляет трафик PXE-клиентов в интернет.

Конфигурация — в `/etc/systemd/network/`:

- `10-eth0.link` — метаданные eth0
- `10-eth0.network` — основной конфиг eth0
- `20-eth0.10.netdev` — определение macvlan
- `20-eth0.10.network` — IP и поведение macvlan

### 2. systemd-networkd

- Включает IP forwarding (`net.ipv4.ip_forward = 1`)
- Управляет macvlan-интерфейсом
- `ConfigureWithoutCarrier=yes` — macvlan поднимается даже без линка на eth0

### 3. iptables MASQUERADE

```
-A POSTROUTING -s 10.254.254.0/24 ! -d 10.254.254.0/24 -j MASQUERADE
```

Трафик от PXE-клиентов маскарадится под IP `wlan0`.

### 4. Docker-стек

7 контейнеров, описанных в [`docker-stack.md`](docker-stack.md).

### 5. Persistent volumes

7 volumes для данных Cobbler, описанных в [`volumes.md`](volumes.md).

### 6. Patched-образы

Три образа собираются ролью с inline-патчами:

- **`cobbler/cobblerd-patched`** = upstream + `patch-remote.py` (legacy aliases) + `patch-manager.py`
- **`cobbler/cobbler-web-patched`** = upstream + `patch-nginx.sh` (port_in_redirect)
- **`cobbler/cobbler-dns-patched`** = upstream + `entrypoint.sh` + `named.conf`

### 7. Systemd-сервис

`cobbler-recover.service` запускает `cobbler-recover.sh` при старте хоста:

1. Включает IP forwarding
2. Включает promiscuous mode на eth0
3. Поднимает macvlan eth0.10
4. Восстанавливает iptables-правила
5. `docker compose up -d`

## Поток данных при PXE-загрузке

```
1. Клиент включается → DHCP-Discover (broadcast)
   │
2. cobbler-dhcp получает → назначает IP из 10.254.254.0/24
   │                          next-server: 10.254.254.4
   │                          boot_file: pxelinux.0
   │
3. Клиент скачивает pxelinux.0 по TFTP (cobbler-tftp)
   │
4. pxelinux загружает ядро Linux + initramfs
   │
5. Linux загружает preseed/kickstart (http-api → http://host/cblr/...)
   │
6. Автоматическая установка ОС
   │
7. Готовый хост с свежей ОС
```

## См. также

- [Docker Stack](docker-stack.md) — подробности о 7 контейнерах
- [Volumes](volumes.md) — что где хранится
# Пошаговое руководство

Это руководство проведёт вас через все этапы от голого хоста до
работающего Web UI Cobbler.

!!! tip "TL;DR"
    Если всё уже подготовлено, копипаста:
    ```bash
    git clone https://github.com/kprklg/ansible-cobbler.git
    cd ansible-cobbler
    ansible-playbook -i inventories/staging/hosts.yml playbooks/site.yml
    ```

## Шаг 1: Подготовка хоста

См. [Prerequisites](prerequisites.md). Убедитесь, что:

- ✅ Установлены `ansible`, `docker-ce`, `qemu-user-static`
- ✅ IP forwarding = 1
- ✅ Есть 2 сетевых интерфейса
- ✅ Docker daemon запущен

## Шаг 2: Клонирование

```bash
git clone https://github.com/kprklg/ansible-cobbler.git
cd ansible-cobbler
git checkout v1.1.0
```

## Шаг 3: Создание инвентаря

Роль **не знает** ваших IP-адресов и имён интерфейсов — их нужно задать явно.

### Структура

```
inventories/
└── myhost/                    # любое имя
    ├── hosts.yml
    └── group_vars/
        └── all.yml
```

### `inventories/myhost/hosts.yml`

```yaml
---
all:
  children:
    cobbler:
      hosts:
        rasp01:                                # любое имя
          ansible_host: 192.168.0.88           # IP для Web UI
          ansible_connection: local            # или ssh://user@host
          ansible_become: yes
```

### `inventories/myhost/group_vars/all.yml`

```yaml
---
# Сеть
cobbler_mgmt_ip: "192.168.0.88"                # IP для Web UI
cobbler_pxe_iface: "eth0"                     # PXE-интерфейс (патч-корд)
cobbler_wifi_iface: "wlan0"                   # Интернет-интерфейс (NAT)
cobbler_pxe_network: "10.254.254.0/24"        # Подсеть PXE-клиентов
cobbler_pxe_ip: "10.254.254.1/24"             # IP macvlan

# Учётные данные
cobbler_default_user: "cobbler"
cobbler_default_password: "cobbler"
```

!!! info "Пример для удалённого хоста по SSH"
    ```yaml
    rasp01:
      ansible_host: 192.168.0.88
      ansible_connection: ssh
      ansible_user: admin
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ```

## Шаг 4: Запуск плейбука

```bash
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

### Что происходит (10 этапов)

1. **preflight** (~30 сек) — проверка архитектуры, Docker, compose
2. **dependencies** (~1 мин) — apt install qemu, iptables-persistent
3. **network/macvlan** (~10 сек) — создание `eth0.10`
4. **network/nat** (~10 сек) — iptables MASQUERADE
5. **compose** (~30 сек) — генерация compose.yml, Dockerfile
6. **webroot** (~30 сек) — извлечение webroot из cobbler-web:v1.2.0
7. **images** (~15–20 мин на RPi 4) — сборка 3 patched-образов
8. **volumes** (~10 сек) — создание volumes + дефолтных конфигов
9. **stack** (~3–5 мин) — docker compose up -d
10. **systemd** (~5 сек) — установка cobbler-recover.service

**Итого: 20–40 минут.**

### Опции запуска

```bash
# Полная установка с verbose
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml -vv

# Пропустить пересборку образов (использовать кэш)
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml \
  -e cobbler_skip_builds=true

# Только сеть (macvlan + NAT)
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml \
  --tags network

# Только docker stack (без пересборки)
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml \
  --tags stack
```

## Шаг 5: Проверка

### Контейнеры

```bash
docker ps --filter name=cobbler-stack
```

Должно быть 7 контейнеров:

| Контейнер | Порт |
|---|---|
| `cobbler-stack-cobblerd-1` | 8000, 25151 |
| `cobbler-stack-http-api-1` | 8000, 25151 |
| `cobbler-stack-web-1` | 8080 |
| `cobbler-stack-traefik-1` | 0.0.0.0:80, 127.0.0.1:8082 |
| `cobbler-stack-cobbler-dhcp-1` | raw socket |
| `cobbler-stack-cobbler-dns-1` | — |
| `cobbler-stack-cobbler-tftp-1` | 6969/udp |

### Web UI

```bash
curl -sk -I http://192.168.0.88/
# → HTTP/1.1 302 Found
# → Location: http://192.168.0.88/en-US/
```

Откройте в браузере: `http://192.168.0.88/`

Логин: `cobbler`, пароль: `cobbler`.

### XML-RPC

```bash
curl -sk -X POST -H "Content-Type: text/xml" \
  -d '<?xml version="1.0"?>
<methodCall><methodName>login</methodName>
<params><param><value><string>cobbler</string></value></param>
<param><value><string>cobbler</string></value></param></params>
</methodCall>' \
  http://192.168.0.88/cobbler_api

# Должно вернуть токен:
# <string>abc123def456==</string>
```

### Systemd

```bash
systemctl status cobbler-recover
# → Active: inactive (dead) — это OK, он запускается по требованию

systemctl is-enabled cobbler-recover
# → enabled
```

## Шаг 6: Импорт дистрибутива

### Через Web UI

1. Distros → Add distro
2. Укажите URL ISO или путь к примонтированному ISO

### Через CLI

```bash
# Подключите ISO
sudo mount /dev/sr0 /mnt

# Импорт
docker exec -it cobbler-stack-cobblerd-1 cobbler import \
  --path=/mnt --name=ubuntu-22.04 --arch=x86_64
```

## Шаг 7: PXE-загрузка клиента

1. Подключите Ethernet-кабель к `eth0` хоста
2. Включите компьютер-клиент
3. Должен получить IP из `10.254.254.0/24`
4. Загрузится через PXE → iPXE → grub → установка

!!! warning "DHCP-конфликты"
    Если в сети уже есть DHCP-сервер — может конфликтовать.
    Решение — подключать PXE-клиентов через отдельный коммутатор.

## Что дальше?

- [Конфигурация → Переменные роли](../configuration/variables.md)
- [Архитектура → Общая картина](../architecture/overview.md)
- [Troubleshooting → Частые ошибки](../troubleshooting/common.md)
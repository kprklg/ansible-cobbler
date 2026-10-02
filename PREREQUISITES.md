# Подготовка хоста (Prerequisites)

Прежде чем запускать `ansible-playbook`, нужно вручную подготовить хост.
Этот документ описывает **что и зачем** нужно установить, чтобы роль
не упала на середине установки.

> ⏱ Полная подготовка занимает ~10–15 минут. Сама установка Cobbler
> занимает ещё ~25 минут на Raspberry Pi (с qemu-эмуляцией x86_64)
> и ~5 минут на x86_64.

---

## 1. Системные требования

### Минимум

| Параметр | Минимум |
|---|---|
| **Платформа** | Debian 12 / Ubuntu 22.04 |
| **Архитектура** | aarch64 / x86_64 |
| **RAM** | 2 GB |
| **Свободное место** | 5 GB |
| **Ansible** | ≥ 2.14 |
| **Python** | ≥ 3.11 |

### Рекомендуется

| Параметр | Рекомендуется |
|---|---|
| **Платформа** | Debian 13 / Ubuntu 24.04 |
| **RAM** | 4 GB (для одновременной сборки 3 образов) |
| **Свободное место** | 10 GB (Docker-образы + volumes + webroot) |
| **Ansible** | 2.19+ |
| **Коллекция `community.docker`** | ≥ 4.7 |

### Сеть (обязательно)

- **2 физических интерфейса** (или 1 физ. + 1 Wi-Fi):
  - один с **интернетом** (для apt, скачивания образов, web-трафика админки)
  - один для **PXE** (сюда воткнёте патч-корд к коммутатору)
- На хосте должен быть **статический или зарезервированный DHCP** IP
  для Web UI (`cobbler_mgmt_ip`)
- Выход в интернет (apt, ghcr.io)

### На aarch64 дополнительно

- `qemu-user-static` + `binfmt-support` — для эмуляции x86_64 (apt)
- работающее `/proc/sys/fs/binfmt_misc/qemu-x86_64` (включено)

---

## 2. Установка системных пакетов

### 2.1 Базовые зависимости

```bash
apt-get update
apt-get install -y \
  ca-certificates curl gnupg git \
  ansible ansible-core \
  qemu-user-static binfmt-support \
  iptables-persistent netfilter-persistent \
  python3 python3-yaml python3-passlib
```

### 2.2 Preseed для iptables-persistent

По умолчанию `iptables-persistent` спрашивает интерактивно, сохранять ли
правила IPv4/IPv6. Чтобы Ansible-установка не зависала, добавьте
preseed заранее:

```bash
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
```

### 2.3 Установка Docker из **официального** репозитория

> ⚠ **Не устанавливайте `docker.io` из Debian-репозитория!**
> Он конфликтует с `docker-ce` из `download.docker.com` (apt-persistent).
> Кроме того, версия 26.1 в Debian-репо устаревшая.

```bash
# GPG-ключ Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Репозиторий
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

# Установка
apt-get update
apt-get install -y docker-ce docker-ce-rootless-extras \
                   docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
```

### 2.4 На aarch64 — проверка эмуляции

```bash
# Должно быть: enabled
ls /proc/sys/fs/binfmt_misc/qemu-x86_64 && \
  head -1 /proc/sys/fs/binfmt_misc/qemu-x86_64

# Тест эмуляции x86_64 в Docker
docker run --rm --platform linux/amd64 alpine:3.20 uname -m
# Должно вернуть: x86_64
```

---

## 3. Создание инвентаря и переменных

Роль **не знает** ваших IP-адресов и имён интерфейсов — их нужно задать
явно через `group_vars`.

### 3.1 Структура директорий

```
inventories/
└── myhost/
    ├── hosts.yml
    └── group_vars/
        └── all.yml
```

### 3.2 `inventories/myhost/hosts.yml`

```yaml
---
all:
  children:
    cobbler:
      hosts:
        rasp01:                                  # любое
          ansible_host: 192.168.0.88             # IP для админки
          ansible_connection: local              # или ssh://...
          ansible_become: yes
```

### 3.3 `inventories/myhost/group_vars/all.yml`

```yaml
---
# === Сеть ===
cobbler_mgmt_ip: "192.168.0.88"                  # IP для Web UI
cobbler_pxe_iface: "eth0"                       # PXE-интерфейс
cobbler_wifi_iface: "wlan0"                     # Интернет-интерфейс (NAT)
cobbler_pxe_network: "10.254.254.0/24"          # Подсеть PXE-клиентов
cobbler_pxe_ip: "10.254.254.1/24"               # IP macvlan

# === Аутентификация ===
cobbler_default_user: "cobbler"
cobbler_default_password: "cobbler"
```

---

## 4. Проверка готовности

Перед запуском плейбука убедитесь, что:

```bash
# Версии инструментов
git --version                                    # ≥ 2.0
ansible --version | head -1                      # ≥ 2.14
docker --version                                 # ≥ 20.10
docker compose version                             # ≥ 2.0
python3 -c "import hashlib, passlib.hash"        # OK

# На aarch64: работает эмуляция
docker run --rm --platform linux/amd64 alpine:3.20 uname -m
# → x86_64

# Docker daemon запущен
systemctl is-active docker
# → active

# Права: можно запускать docker без sudo (или через become)
docker ps
```

---

## 5. Минимальная копипаста

```bash
# === Подготовка хоста ===
apt-get update
apt-get install -y ca-certificates curl gnupg git \
  ansible ansible-core qemu-user-static binfmt-support \
  iptables-persistent netfilter-persistent python3 python3-yaml python3-passlib

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update && apt-get install -y docker-ce docker-compose-plugin
systemctl enable --now docker

# === Клонирование роли ===
git clone https://github.com/kprklg/ansible-cobbler.git
cd ansible-cobbler
git checkout v1.1.0

# === Инвентарь ===
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

# === Запуск ===
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

Готово. Дальше — ждать ~25 минут.
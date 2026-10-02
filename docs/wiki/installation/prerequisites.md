# Подготовка хоста

Прежде чем запускать плейбук `cobbler`, нужно подготовить целевой хост.
Этот документ описывает, что установить руками и почему.

## Системные требования

| Параметр | Минимум | Рекомендуется |
|---|---|---|
| ОС | Debian 12 / Ubuntu 22.04 | Debian 13 / Ubuntu 24.04 |
| Архитектура | aarch64 / x86_64 | — |
| RAM | 2 GB | 4 GB |
| Диск | 10 GB | 20 GB |
| Python | 3.11 | 3.13 |
| Ansible | 2.14 | 2.19+ |

## Шаг 1: Установить системные пакеты

### Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y \
    ca-certificates curl gnupg git \
    ansible ansible-core \
    qemu-user-static binfmt-support \
    iptables-persistent netfilter-persistent \
    python3 python3-yaml python3-passlib \
    sudo
```

### RHEL / AlmaLinux / Rocky

```bash
sudo dnf install -y \
    ansible-core git qemu-user-static \
    iptables-services python3-pip python3-passlib
sudo systemctl enable --now iptables
```

## Шаг 2: Preseed для iptables-persistent

Без preseed установка iptables-persistent зависнет на интерактивном вопросе
"Сохранить ли правила IPv4/IPv6?".

```bash
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
```

## Шаг 3: Установить Docker (ОФИЦИАЛЬНЫЙ)

> ⚠️ **Не устанавливайте** `docker.io` из Debian-репозитория!
> Версия 26.1 там устаревшая и конфликтует с `docker-ce`.

```bash
# Debian
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-rootless-extras \
                        docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # чтобы запускать без sudo (потребуется logout/login)
```

Или быстрый вариант:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

## Шаг 4: Проверить эмуляцию (только на aarch64)

На Raspberry Pi qemu-эмуляция нужна для запуска x86_64 Docker-образов.

```bash
# Должно быть "enabled"
cat /proc/sys/fs/binfmt_misc/qemu-x86_64 | head -1

# Тест эмуляции
sudo docker run --rm --platform linux/amd64 alpine:3.20 uname -m
# Должно вернуть: x86_64
```

Если `cat /proc/sys/fs/binfmt_misc/qemu-x86_64` возвращает пустоту:

```bash
sudo apt-get install -y qemu-user-static binfmt-support
sudo update-binfmts --display qemu-x86_64
```

## Шаг 5: Подготовить сеть

### Проверить интерфейсы

```bash
ip -br addr show | head -10
ip route show default
```

У хоста должны быть:

- **Интернет-интерфейс** (с дефолтным маршрутом)
- **PXE-интерфейс** (может быть без кабеля на момент установки)

Пример:

```
wlan0 UP 192.168.0.88/24       ← интернет (NAT через него)
eth0  DOWN                      ← PXE (кабель не подключён, OK)
```

### Включить IP forwarding

```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-cobbler.conf
```

## Шаг 6: Клонировать роль

```bash
git clone https://github.com/kprklg/ansible-cobbler.git
cd ansible-cobbler
git checkout v1.1.0   # или main для bleeding edge
```

## Шаг 7: Установить Ansible collections

```bash
ansible-galaxy collection install -r requirements.yml
```

## Проверка готовности

Перед запуском плейбука всё должно быть ОК:

```bash
# Версии
git --version                                         # ≥ 2.0
ansible --version | head -1                            # ≥ 2.14
docker --version                                      # ≥ 20.10
docker compose version                                 # ≥ 2.0

# Ansible collections
ansible-galaxy collection list | grep community.docker

# Python
python3 -c "import hashlib, passlib.hash"             # OK# Docker daemon
sudo systemctl is-active docker
# → active

# Сеть
sudo cat /proc/sys/net/ipv4/ip_forward                # → 1

# На aarch64:
sudo docker run --rm --platform linux/amd64 alpine:3.20 uname -m
# → x86_64
```

Если всё ОК — переходите к [Step-by-step руководству](step-by-step.md).

## Что может пойти не так

### `qemu-x86_64` не enabled

```bash
sudo apt-get install --reinstall qemu-user-static binfmt-support
sudo systemctl restart systemd-binfmt
```

### `docker-ce` конфликтует с `docker.io`

```bash
sudo apt-get remove docker.io containerd.io
sudo apt-get install -y docker-ce docker-ce-rootless-extras \
                       docker-buildx-plugin docker-compose-plugin
```

### `iptables-persistent` зависает

См. шаг 2 — нужно preseed.

## Следующий шаг

[→ Пошаговое руководство](step-by-step.md)
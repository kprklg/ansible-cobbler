# Частые ошибки

Этот документ — быстрый справочник по самым распространённым проблемам.
Подробности — в [Diagnostics](diagnostics.md).

## Предустановка

### `git: command not found`

```bash
apt-get install -y git
```

### `ansible-playbook: command not found`

```bash
apt-get install -y ansible-core ansible
```

### `docker: command not found` или `Cannot connect to Docker daemon`

Установите Docker (см. [Prerequisites](../installation/prerequisites.md)):

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

### `qemu-x86_64` not enabled (только на aarch64)

```bash
apt-get install -y qemu-user-static binfmt-support
sudo systemctl restart systemd-binfmt
sudo docker run --rm --platform linux/amd64 alpine:3.20 uname -m
```

## Pre-flight

### `Syntax error in expression: Template delimiters are not supported`

Это баг в `preflight.yml` из v1.0.0. Исправлено в v1.1.0.

```bash
git checkout v1.1.0
```

### `Unsupported parameters ... ipam_options`

Баг в `stack.yml` из v1.0.0. В `community.docker 4.x` параметр переименован.

```bash
git checkout v1.1.0
```

### `value of pull must be one of: always, missing, never, policy, got: False`

`pull: no` устарел. Исправлено в v1.1.0.

```bash
git checkout v1.1.0
```

## Сеть

### `An unexpected Docker error occurred: invalid subinterface vlan name eth0-host`

macvlan-интерфейс должен называться `eth0.10` (VLAN-формат), а не `eth0-host`.

В v1.1.0 исправлено. Если у вас v1.0.0:

```bash
# Удалите старый macvlan
ip link set eth0-host down
ip link delete eth0-host

# Создайте новый
ip link add link eth0 name eth0.10 type macvlan mode bridge
ip link set eth0.10 up
```

### `connection refused` на http://127.0.0.1/ (но http://192.168.0.88/ работает)

Traefik слушал только на `cobbler_mgmt_ip`. Исправлено в v1.1.0.

```bash
# Если у вас v1.1.0 и всё ещё проблема:
sed -i 's|"192.168.0.88:80:80"|"0.0.0.0:80:80"|' /opt/cobbler-stack/compose.yml
cd /opt/cobbler-stack && docker compose up -d traefik
```

### `dpkg-deb: error: paste subprocess was killed by signal`

Конфликт `docker-ce` с `docker.io` из Debian-репо.

```bash
sudo apt-get remove docker.io containerd.io
sudo apt-get install -y docker-ce docker-compose-plugin
```

## Сборка образов

### `No filter named 'ipaddr'`

В Ansible 2.10+ фильтр `ipaddr` перенесён в `ansible.utils`. Исправлено в v1.1.0.

```bash
git checkout v1.1.0
```

### `'pxe_iface' is undefined`

Переменные шаблона без префикса `cobbler_`. Исправлено в v1.1.0.

```bash
git checkout v1.1.0
```

### `Could not find or access 'named.conf.j2'`

Отсутствующий шаблон. Исправлено в v1.1.0.

```bash
git checkout v1.1.0
```

## cobblerd

### `IndentationError: unexpected indent` в cobblerd

Патч-скрипт `patch-remote.py` несовместим с Cobbler 4 (многострочная
сигнатура функции). Исправлено в v1.1.0.

```bash
# Пересобрать образ
docker rmi -f cobbler/cobblerd-patched:latest
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags build
```

### `XML-RPC login: faultCode 1`

`users.digest` пустой или с неправильным хешем. Исправлено в v1.1.0.

```bash
# Решение для v1.1.0+ (после установки)
python3 -c "
import hashlib
h = hashlib.sha3_512('cobbler'.encode('utf-8')).hexdigest()
print(f'cobbler:Cobbler:{h}')
" > /tmp/cobbler-users.digest

docker stop cobbler-stack-cobblerd-1
docker run --rm --platform linux/amd64 \
  -v cobbler-stack_cobbler-etc:/data \
  -v /tmp:/backup:ro \
  alpine sh -c "cp /backup/cobbler-users.digest /data/users.digest && chmod 0600 /data/users.digest"
docker start cobbler-stack-cobblerd-1
```

## Docker compose

### `connection reset by peer` при открытии Web UI

Traefik не запустился. Проверьте логи:

```bash
docker logs cobbler-stack-traefik-1 --tail 30
```

### `no such image` при docker compose up

Образы не собраны. Запустите:

```bash
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags build
```

## Systemd

### `cobbler-recover.service: Unit not found`

Systemd-юнит не установлен. Запустите:

```bash
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags systemd
```

### После ребута ничего не поднимается

```bash
sudo systemctl status cobbler-recover
sudo journalctl -u cobbler-recover --no-pager -n 50
```

Частые причины:

- eth0 без линка → macvlan в LOWERLAYERDOWN
- iptables-правила потеряны → нужен iptables-persistent
- docker не запущен → нужен `systemctl enable docker`

## См. также

- [Diagnostics](diagnostics.md) — диагностические команды
- [FAQ](../faq.md) — общие вопросы
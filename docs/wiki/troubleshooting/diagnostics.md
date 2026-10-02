# Диагностика

Этот документ — справочник по командам для диагностики проблем.

## Общая проверка

```bash
# Статус всех контейнеров Cobbler
docker ps --filter name=cobbler-stack --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Статус systemd-сервиса
systemctl status cobbler-recover

# Использование диска
docker system df

# Использование памяти
docker stats --no-stream --filter name=cobbler-stack
```

## Логи

### Все контейнеры

```bash
# Все логи
cd /opt/cobbler-stack && docker compose logs -f

# Только последние 100 строк
cd /opt/cobbler-stack && docker compose logs --tail 100
```

### Конкретный сервис

```bash
docker logs cobbler-stack-cobblerd-1 --tail 100 -f
docker logs cobbler-stack-traefik-1 --tail 50
docker logs cobbler-stack-web-1 --tail 50
docker logs cobbler-stack-cobbler-dhcp-1 --tail 20
```

### Ansible-лог

```bash
# Если запускали с перенаправлением
tail -200 /tmp/cobbler-install.log

# С определённого момента
grep -E "TASK|ERROR|FAILED" /tmp/cobbler-install.log
```

## API-проверки

### XML-RPC ping

```bash
curl -sk -X POST -H "Content-Type: text/xml" \
  -d '<?xml version="1.0"?><methodCall><methodName>ping</methodName></methodCall>' \
  http://192.168.0.88/cobbler_api | head -10
```

Должен вернуть:

```xml
<?xml version='1.0'?>
<methodResponse>
<params>
<param><value><boolean>1</boolean></value></param>
</params>
</methodResponse>
```

### XML-RPC login

```bash
curl -sk -X POST -H "Content-Type: text/xml" \
  -d '<?xml version="1.0"?>
<methodCall><methodName>login</methodName>
<params><param><value><string>cobbler</string></value></param>
<param><value><string>cobbler</string></value></param></params>
</methodCall>' \
  http://192.168.0.88/cobbler_api
```

Должен вернуть токен:

```xml
<value><string>abc123def456==</string></value>
```

Если `faultCode: 1` — пользователь/пароль неверные, либо users.digest пустой.

### Web UI

```bash
# HEAD-запрос (без скачивания)
curl -skI http://192.168.0.88/

# Должен вернуть 302 Found с Location: /en-US/
```

## Сеть

### Интерфейсы

```bash
ip -br addr show | grep -E "eth|wlan|UP"
ip link show eth0
ip link show eth0.10
```

### Маршруты

```bash
ip route show
ip route get 8.8.8.8
```

### iptables

```bash
# NAT-правила
iptables -t nat -L POSTROUTING -n -v

# Должно быть что-то вроде:
# Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target   prot opt in     out source      destination
#     0     0 MASQUERADE  all  --  *   *  10.254.254.0/24 !10.254.254.0/24

# Сохранённые правила
cat /etc/iptables/rules.v4
```

### IP forwarding

```bash
cat /proc/sys/net/ipv4/ip_forward
# Должно быть: 1

# Если 0:
sudo sysctl -w net.ipv4.ip_forward=1
```

## Docker

### Информация о среде

```bash
docker info | grep -E "Server Version|Storage Driver|Cgroup"
docker compose version
```

### Volumes

```bash
# Список
docker volume ls --filter name=cobbler-stack

# Размер
docker system df -v | grep cobbler-stack

# Содержимое
docker run --rm \
  -v cobbler-stack_cobbler-etc:/data:ro \
  alpine ls -la /data
```

### Сети

```bash
docker network ls | grep cobbler-stack
docker network inspect cobbler-stack_cobbler-pxe
```

### Процессы в контейнере

```bash
# Все процессы в cobblerd
docker exec cobbler-stack-cobblerd-1 ps aux

# Сетевые соединения
docker exec cobbler-stack-cobblerd-1 ss -tlnp 2>&1 || \
  docker exec cobbler-stack-cobblerd-1 netstat -tlnp
```

## aarch64 / qemu

### Проверка эмуляции

```bash
cat /proc/sys/fs/binfmt_misc/qemu-x86_64
# Должно быть: enabled

ls /proc/sys/fs/binfmt_misc/qemu-*
```

### Тест эмуляции

```bash
docker run --rm --platform linux/amd64 alpine:3.20 uname -m
# Должно вернуть: x86_64

# Полная проверка
docker run --rm --platform linux/amd64 alpine:3.20 sh -c \
  "apk add --no-cache curl && curl --max-time 5 -sI https://google.com"
```

## Systemd

### Статус сервиса

```bash
systemctl status cobbler-recover

# Подробности
journalctl -u cobbler-recover --no-pager -n 50
```

### Перезапуск

```bash
sudo systemctl restart cobbler-recover

# Логи при перезапуске
journalctl -u cobbler-recover -f
```

### Включение

```bash
sudo systemctl enable --now cobbler-recover
```

## Что-то не нашли?

Откройте [Issue](https://github.com/kprklg/ansible-cobbler/issues/new?template=bug_report.md)
с выводом:

```bash
# Автоматический сбор диагностики
{ echo "=== OS ===" && cat /etc/os-release && \
  echo "=== Ansible ===" && ansible --version | head -2 && \
  echo "=== Docker ===" && docker --version && docker compose version && \
  echo "=== Containers ===" && docker ps --filter name=cobbler-stack --format "table {{.Names}}\t{{.Status}}" && \
  echo "=== Network ===" && ip -br addr show | grep -E "eth|wlan|UP" && \
  echo "=== Systemd ===" && systemctl is-enabled cobbler-recover && \
  echo "=== Binfmt ===" && cat /proc/sys/fs/binfmt_misc/qemu-x86_64 2>/dev/null | head -1; } | tee /tmp/cobbler-diag.txt
```

Приложите `/tmp/cobbler-diag.txt` к bug report.
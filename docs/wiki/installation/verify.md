# Проверка работоспособности

После установки выполните следующие проверки.

## Контейнеры

```bash
docker ps --filter name=cobbler-stack --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Должно быть **7 контейнеров**:

| Контейнер | Порт |
|---|---|
| `cobbler-stack-cobblerd-1` | 8000, 25151 |
| `cobbler-stack-http-api-1` | 8000, 25151 |
| `cobbler-stack-web-1` | 8080 |
| `cobbler-stack-traefik-1` | 0.0.0.0:80, 127.0.0.1:8082 |
| `cobbler-stack-cobbler-tftp-1` | 6969/udp |
| `cobbler-stack-cobbler-dhcp-1` | — |
| `cobbler-stack-cobbler-dns-1` | — |

## Web UI

```bash
curl -sk -I http://192.168.0.88/
# Должно вернуть: HTTP/1.1 302 Found
```

## XML-RPC

```bash
curl -sk -X POST -H "Content-Type: text/xml" \
  -d '<?xml version="1.0"?><methodCall><methodName>ping</methodName></methodCall>' \
  http://192.168.0.88/cobbler_api
# Должно вернуть: <boolean>1</boolean>
```

## Подробнее

См. [Quick Start руководство](../installation/step-by-step.md).

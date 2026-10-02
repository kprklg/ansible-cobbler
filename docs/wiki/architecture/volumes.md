# Persistent Volumes

Роль создаёт 7 Docker volumes для хранения данных Cobbler.

## Сводная таблица

| Volume | Монтируется в | Что внутри | Генерируется ролью? |
|---|---|---|---|
| `cobbler-stack_cobbler-etc` | `/etc/cobbler` | `settings.yaml`, `users.conf`, `users.digest`, `auth.conf` | ✅ да |
| `cobbler-stack_cobbler-var-lib` | `/var/lib/cobbler` | Объекты: distros, profiles, systems, repos | ❌ генерируется cobblerd |
| `cobbler-stack_cobbler-webdir` | `/srv/www/cobbler` | Kickstart templates, snippets | ✅ из upstream cobbler-web |
| `cobbler-stack_cobbler-tftproot` | `/srv/tftpboot` | PXE-boot файлы | ❌ генерируется cobblerd |
| `cobbler-stack_cobbler-dhcp-config` | `/etc/cobbler-dhcp` | `dhcpd.conf` | ✅ да |
| `cobbler-stack_cobbler-dns-config` | `/etc/cobbler-dns` | `named.conf` (reference) | ✅ да |
| `cobbler-stack_cobbler-dns-zones` | `/var/lib/named` | Zone files | ❌ генерируется cobblerd |

## Подробно по каждому volume

### `cobbler-stack_cobbler-etc`

Главная конфигурация Cobbler. Генерируется ролью из `templates/cobbler-settings.yaml.j2`:

```
/etc/cobbler/
├── settings.yaml      # основные настройки
├── auth.conf          # модуль авторизации (authz.configfile)
├── users.conf         # список пользователей
└── users.digest       # SHA3-512 хеши паролей
```

### `cobbler-stack_cobbler-var-lib`

Основные данные: дистрибутивы, профили, системы. Это самое важное — **бэкапьте это**:

```
/var/lib/cobbler/
├── distros/           # импортированные дистрибутивы
├── profiles/             # профили
├── systems/             # конкретные хосты
├── repos/               # локальные репозитории
├── snippets/            # kickstart snippets
├── kickstarts/          # сгенерированные kickstart-файлы
└── triggers/            # pre/post install скрипты
```

### `cobbler-stack_cobbler-webdir`

Извлекается из `cobbler-web:v1.2.0` при первом запуске:

```
/srv/www/cobbler/
├── html/
├── app-config.json
└── locales/
```

### `cobbler-stack_cobbler-tftproot`

PXE-boot файлы, генерируются cobblerd при первой синхронизации:

```
/srv/tftpboot/
├── pxelinux.0
├── pxelinux.cfg/         # конфиги для клиентов
├── grub/                 # GRUB2 EFI
├── images/               # загрузочные образы
└── esxi/                 # VMware ESXi (если импортирован)
```

### `cobbler-stack_cobbler-dhcp-config`

DHCP-конфигурация. Генерируется ролью из `templates/cobbler-dhcpd.conf.j2`:

```
/etc/cobbler-dhcp/dhcpd.conf
```

### `cobbler-stack_cobbler-dns-config`

Reference BIND-конфигурация:

```
/etc/cobbler-dns/named.conf
```

### `cobbler-stack_cobbler-dns-zones`

Zone-файлы, генерируются cobblerd:

```
/var/lib/named/
├── forward.zone
└── reverse.zone
```

## Бэкап и восстановление

### Бэкап

```bash
#!/bin/bash
# backup-cobbler.sh
BACKUP_DIR="/var/backups/cobbler-$(date +%F)"
mkdir -p "$BACKUP_DIR"

for vol in cobbler-etc cobbler-var-lib cobbler-webdir cobbler-tftproot \
           cobbler-dhcp-config cobbler-dns-config cobbler-dns-zones; do
    docker run --rm \
      -v "cobbler-stack_${vol}:/data:ro" \
      -v "$BACKUP_DIR:/backup" \
      alpine tar czf "/backup/${vol}.tar.gz" -C /data .
done

echo "Backup complete: $BACKUP_DIR"
```

### Восстановление

```bash
#!/bin/bash
# restore-cobbler.sh
BACKUP_DIR="$1"

for vol in cobbler-etc cobbler-var-lib cobbler-webdir cobbler-tftproot \
           cobbler-dhcp-config cobbler-dns-config cobbler-dns-zones; do
    docker run --rm \
      -v "cobbler-stack_${vol}:/data" \
      -v "$BACKUP_DIR:/backup:ro" \
      alpine sh -c "rm -rf /data/* && tar xzf /backup/${vol}.tar.gz -C /data"
done
```

## Где их посмотреть

```bash
# Размер каждого volume
docker system df -v

# Содержимое
docker run --rm \
  -v cobbler-stack_cobbler-etc:/data:ro \
  alpine ls -la /data

# Конкретный файл
docker run --rm \
  -v cobbler-stack_cobbler-etc:/data:ro \
  alpine cat /data/settings.yaml
```

## Очистка (осторожно!)

```bash
# Удалить ТОЛЬКО cobblerd-data (не volumes):
docker exec cobbler-stack-cobblerd-1 cobbler sync

# Удалить один volume (потеря данных!):
docker volume rm cobbler-stack_cobbler-var-lib

# Удалить всё:
docker compose down -v
```
# Troubleshooting / Решение проблем

> 🇬🇧 **English below** — see [English version](#-english)
> 🇷🇺 **Русский ниже** — см. [Русская версия](#-русский)

---

<a id="-english"></a>

# 🇬🇧 English

Common problems when running the role and how to solve them.

## Errors when running the playbook

### `Syntax error in expression: Template delimiters are not supported in expressions`

**Cause:** outdated Ansible (pre-2.14) that doesn't fully support
`{% raw %}` blocks, or syntax errors in the role's templates after a
local edit.

**Solution:** check Ansible version (`ansible --version`), upgrade to
≥ 2.14. If you edited templates locally — re-run the role with the
original files.

### `No filter named 'ipaddr'`

**Cause:** in ansible-core 2.19+, declaring `collections: [ansible.utils]`
in a playbook does not make the short name `ipaddr` available in
Jinja templates.

**Solution:** make sure `filter_plugins/ipaddr.py` exists in the
repository. In v1.1.2 it has been added.

```bash
ls filter_plugins/ipaddr.py
# Must exist
```

### `failed to enable <iface>.10 the macvlan parent link network is down`

**Cause:** the parent network interface (the one in `cobbler_pxe_iface`)
is not brought up (DOWN) — cable is not plugged in, or systemd-networkd
isn't bringing it up automatically.

**Solution (temporary):** bring the interface up manually:

```bash
sudo ip link set <cobbler_pxe_iface> up
```

**Solution (permanent):** in v1.1.2, `ConfigureWithoutCarrier=yes` is set
for the parent interface in `/etc/systemd/network/10-<iface>.network`.
If you're using v1.1.0/v1.1.1, add this line manually:

```ini
# /etc/systemd/network/10-ens19.network
[Match]
Name=ens19

[Network]
IPv6AcceptRA=no
ConfigureWithoutCarrier=yes   # ← add
```

### `No such image: traefik:v3.6`

**Cause:** the `compose.yml` has `pull: never`, but the image hasn't
been pulled.

**Manual solution (v1.1.0/v1.1.1):**

```bash
docker pull traefik:v3.6
docker pull ghcr.io/cobbler/cobbler-tftp:latest
docker pull ghcr.io/cobbler/cobbler-dhcp:latest
```

**Solution in v1.1.2:** the role itself does `docker pull` before
starting the stack.

### `Connection refused` on `http://127.0.0.1:80` (when checking Web UI)

**Cause:** in v1.1.0/v1.1.1, traefik is bound only to `{{ cobbler_mgmt_ip }}`,
not to `127.0.0.1`. The health-check in the playbook checks `127.0.0.1`
and fails.

**Solution in v1.1.2:** traefik binds `0.0.0.0:80`, health-check goes
to `http://{{ cobbler_mgmt_ip }}/`. Upgrade to v1.1.2.

### `--tags systemd` does nothing

**Cause:** in v1.1.0/v1.1.1, `include_tasks` doesn't propagate tags to
inner-tasks, and the tasks themselves have no tags.

**Solution in v1.1.2:** inner-tasks in `tasks/systemd.yml` are explicitly
marked `tags: [systemd, autostart]`.

### `volume ... already exists but was not created by Docker Compose`

**Cause:** in v1.1.0/v1.1.1, volumes are created manually via
`community.docker.docker_volume`, but in `compose.yml` they're not
marked as `external: true`.

**Solution in v1.1.2:** all volumes in `compose.yml` are marked
`external: true`.

### `mount of type volume should not define bind option`

**Cause:** short-form `name:path:z` for volume mounts gets expanded by
Docker 29 into `bind: { selinux: z }` for a volume-typed mount, which
is what Docker complains about.

**Solution in v1.1.2:** volumes are written in long-form
(`type: volume` / `type: bind`).

### `cobbler import` not found in the container

**Cause:** the upstream `cobblerd` image ships only the daemon, without
a CLI.

**Solution in v1.1.2:** a wrapper `/usr/local/bin/cobbler`
(`python3 -m cobbler.cli`) is added in `Dockerfile.cobbler.j2`.

### Web UI returns 502 Bad Gateway

**Cause:** the `web` container (nginx) hasn't started yet, or traefik
can't see it in the network.

**Solution:**

```bash
docker ps --filter name=cobbler-stack
docker logs cobbler-stack-web-1
docker logs cobbler-stack-traefik-1
```

### Can't see containers in `docker ps`

**Cause:** Docker is not installed or not running.

**Solution:**

```bash
systemctl status docker
sudo systemctl enable --now docker
```

### `Permission denied` on `docker ps` (without sudo)

**Cause:** the current user is not in the `docker` group.

**Solution:**

```bash
sudo usermod -aG docker $USER
# then re-login
```

---

<a id="-русский"></a>

# 🇷🇺 Русский

Частые проблемы при запуске роли и способы их решения.

## Ошибки при запуске плейбука

### `Syntax error in expression: Template delimiters are not supported in expressions`

**Где:** `preflight.yml` (исправлено в v1.1.0).

**Причина:** в условии `that:` модуля `ansible.builtin.assert` использовались
Jinja-разделители `{{ }}`.

**Решение:** обновиться до v1.1.0:
```bash
git checkout v1.1.0
```

### `Module failed: Unsupported parameters ... ipam_options`

**Где:** `stack.yml` (исправлено в v1.1.0).

**Причина:** в `community.docker 4.x` параметр `ipam_options` переименован
в `ipam_config`.

**Решение:** обновиться до v1.1.0.

### `value of pull must be one of: always, missing, never, policy, got: False`

**Где:** `stack.yml` (исправлено в v1.1.0).

**Причина:** `pull: no` теперь невалиден, только строки.

**Решение:** обновиться до v1.1.0.

### `invalid network config: invalid ip-range 10.254.254.0.128/25`

**Где:** `stack.yml` (исправлено в v1.1.0).

**Причина:** склейка строк дала невалидный CIDR.

**Решение:** обновиться до v1.1.0.

### `An unexpected Docker error occurred: invalid subinterface vlan name eth0-host`

**Где:** `stack.yml` (исправлено в v1.1.0).

**Причина:** Docker 25+ требует формат `<iface>.<vlan>`, а не `<iface>-<name>`.

**Решение:** обновиться до v1.1.0 — родительский интерфейс переименован в `eth0.10`.

### `dpkg-deb: error: paste subprocess was killed by signal (Broken pipe)`

**Где:** `dependencies.yml` (исправлено в v1.1.0).

**Причина:** конфликт `docker-ce` (29.x) с принудительно устанавливаемым
`docker.io` (26.1) из Debian-репо.

**Решение:** обновиться до v1.1.0 — больше не устанавливаем `docker.io`.

### `Task failed: No filter named 'ipaddr'`

**Где:** `compose.yml.j2` (исправлено в v1.1.0).

**Причина:** фильтр `ipaddr` перенесён из `community.general` в
`ansible.utils` в Ansible 2.10+.

**Решение:** обновиться до v1.1.0. Убедитесь, что в
`ansible.cfg` есть `filter_plugins = filter_plugins`.

### `Task failed: 'pxe_iface' is undefined`

**Где:** `cobbler-recover.sh.j2` (исправлено в v1.1.0).

**Причина:** в шаблоне использовались переменные без префикса `cobbler_`.

**Решение:** обновиться до v1.1.0.

### `Task failed: 'pxe_network' is undefined`

**Где:** `compose.yml.j2` (исправлено в v1.1.0).

**Причина:** в шаблоне использовались `mgmt_ip` / `pxe_network` без
префикса `cobbler_`.

**Решение:** обновиться до v1.1.0.

### `Could not find or access 'named.conf.j2'`

**Где:** `compose.yml` (исправлено в v1.1.0).

**Причина:** отсутствующий шаблон в upstream-репозитории.

**Решение:** обновиться до v1.1.0.

### `Syntax error in template: unexpected '.'`

**Где:** `volumes.yml` (исправлено в v1.1.0).

**Причина:** Go-template `{{.Name}}` в команде shell был интерпретирован
Ansible как Jinja2-переменная.

**Решение:** обновиться до v1.1.0.

---

## Ошибки при инициализации cobblerd

### `IndentationError: unexpected indent` в `cobbler-stack-cobblerd-1`

**Где:** `patch-remote.py.j2` (исправлено в v1.1.0).

**Причина:** функция `get_valid_distro_boot_loaders` в Cobbler 4 имеет
многострочную сигнатуру, а старый скрипт патча вставлял методы без
сохранения отступа.

**Решение:** обновиться до v1.1.0. Если контейнер уже не поднимается:
```bash
docker rmi -f cobbler/cobblerd-patched:latest
rm -f /opt/cobbler-stack/patches/cobbler/{patch-remote.py,patch-manager.py,Dockerfile}
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml --tags build
```

### `XML-RPC login: faultCode 1` (не удаётся войти в Web UI)

**Где:** `users.digest` (исправлено в v1.1.0).

**Причина:** Python 3.13 удалил модуль `crypt`, поэтому скрипт генерации
`users.digest` создавал пустой файл. Cobbler 4 использует `sha3_512`,
а не MD5 (`$1$`).

**Решение (после установки):**
```bash
# Вручную сгенерировать и залить правильный хеш
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
sleep 90  # cobblerd через qemu стартует медленно

# Тест логина
curl -sk -X POST -H "Content-Type: text/xml" \
  -d '<?xml version="1.0"?>
<methodCall>
<methodName>login</methodName>
<params><param><value><string>cobbler</string></value></param>
<param><value><string>cobbler</string></value></param></params>
</methodCall>' \
  http://192.168.0.88/cobbler_api
```

---

## Проблемы с сетью

### `connection refused` на http://127.0.0.1/ при работающем http://192.168.0.88/

**Где:** `stack.yml` (исправлено в v1.1.0).

**Причина:** Traefik publish `192.168.0.88:80:80` — слушал только на
внешнем IP. Ansible проверял `127.0.0.1` и 3 минуты ждал ответа.

**Решение:** в `compose.yml` должно быть `0.0.0.0:80:80`. Обновиться
до v1.1.0 или:
```bash
sed -i 's|"192.168.0.88:80:80"|"0.0.0.0:80:80"|' /opt/cobbler-stack/compose.yml
cd /opt/cobbler-stack && docker compose up -d traefik
```

### `eth0` без кабеля, нет линкаетки — PXE не раздаёт

Нормальное поведение. macvlan настроен с `ConfigureWithoutCarrier=yes`,
поэтому контейнеры запустятся, но клиенты не получат IP пока
не воткнёте кабель.

Проверка:
```bash
ip link show eth0
# Должно появиться: <NO-CARRIER,BROADCAST,MULTICAST,UP>
ip link show eth0.10
# Должно быть: <BROADCAST,MULTICAST,UP,LOWER_UP> (с кабелем) или LOWERLAYERDOWN (без)
```

---

## Проблемы с производительностью

### Сборка образов идёт очень медленно (aarch64)

На RPi 4 сборка 3 образов через qemu-эмуляцию занимает ~15–20 мин.
Это нормально.

Если хотите ускорить:
- Запускайте сборку параллельно (`forks: 5` уже включено в `ansible.cfg`)
- Или собирайте образы на x86_64-машине, затем перенесите через `docker save/load`

### `io_setup() failed` в `cobbler-stack-web-1`

**Причина:** `nginx-unprivileged` на aarch64/qemu имеет проблемы
с native aio (4 из 5 worker падают).

**Влияние:** Web UI работает (master-worker обрабатывает запросы), но
нагрузочная способность ниже.

**Workaround (опционально):**
```bash
docker exec cobbler-stack-web-1 sh -c "
    sed -i '1i aio threads;' /etc/nginx/conf.d/default.conf &&
    kill -HUP 1
  "
```

---

## Диагностические команды

```bash
# Статус всех контейнеров
docker ps --filter name=cobbler-stack

# Логи конкретного сервиса
docker logs cobbler-stack-cobblerd-1 --tail 50
docker logs cobbler-stack-traefik --tail 20
docker logs cobbler-stack-web --tail 20

# Проверка XML-RPC
curl -sk -X POST -H "Content-Type: text/xml" \
  -d '<?xml version="1.0"?><methodCall><methodName>ping</methodName></methodCall>' \
  http://192.168.0.88/cobbler_api

# Логин через XML-RPC
curl -sk -X POST -H "Content-Type: text/xml" \
  -d '<?xml version="1.0"?>
<methodCall>
<methodName>login</methodName>
<params><param><value><string>cobbler</string></value></param>
<param><value><string>cobbler</string></value></param></params>
</methodCall>' \
  http://192.168.0.88/cobbler_api

# Проверка Web UI
curl -sk -I http://192.168.0.88/
curl -sk -L -o /dev/null -w "%{http_code}\n" http://192.168.0.88/en-US/

# Проверка макадресов и сети
ip -br addr show
ip route show
ip link show eth0.10

# Проверка NAT-правил
iptables -t nat -L POSTROUTING -n -v

# Проверка systemd
systemctl status cobbler-recover
journalctl -u cobbler-recover --no-pager -n 50

# Проверка volumes
docker volume ls | grep cobbler-stack
```
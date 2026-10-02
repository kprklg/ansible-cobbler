# FAQ — Часто задаваемые вопросы

> Если ваш вопрос не здесь — откройте [Discussion](../../discussions) или [Issue](../../issues).

## Общие вопросы

### Что это за проект?

Ansible-роль для установки PXE-провижининг сервера [Cobbler 4.x](https://cobbler.github.io/)
на Raspberry Pi (aarch64) или x86_64-хост с Debian/Ubuntu. Автоматически настраивает
macvlan, NAT, Docker Compose стек из 7 контейнеров и systemd-автозапуск.

### Зачем своя роль, если есть geerlingguy.docker и community.docker?

Геерлингу не собирает кастомные Docker-образы и не настраивает PXE-сеть.
Роль `cobbler` — это полное end-to-end решение: от пустого хоста до
работающего Cobbler за одну команду `ansible-playbook`.

### Какие upstream-образы используются?

- `ghcr.io/cobbler/cobblerd:latest`
- `ghcr.io/cobbler/cobbler-dns:latest`
- `ghcr.io/cobbler/cobbler-dhcp:latest`
- `ghcr.io/cobbler/cobbler-tftp:latest`
- `ghcr.io/cobbler/cobbler-web:v1.2.0`
- `traefik:v3.6`

Эти upstream-образы **не модифицируются** — роль собирает собственные
`*-patched` образы с inline-патчами (для совместимости с `cobbler-web v1.x`).

### Можно использовать на x86_64 без Raspberry Pi?

Да. На x86_64 роль не требует qemu-эмуляции — образы запускаются нативно,
сборка в 5–10 раз быстрее.

---

## Установка и подготовка

### Можно установить одной командой?

Не совсем. Перед `ansible-playbook` нужно вручную:
- установить apt-пакеты (см. [PREREQUISITES.md](PREREQUISITES.md))
- установить Docker из официального репо
- создать инвентарь и `group_vars/all.yml` с вашими IP/интерфейсами

Сама роль — да, запускается одной строкой:
```
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

### Какие пакеты нужно поставить вручную?

Минимально:
- `ansible`, `git`, `qemu-user-static`, `binfmt-support` (на aarch64)
- `python3-passlib` (для генерации пароля)
- `docker-ce` + `docker-compose-plugin` (из официального Docker-репо)

Полный список — в [PREREQUISITES.md](PREREQUISITES.md).

### Почему нельзя установить `docker.io` из Debian-репозитория?

Потому что он конфликтует с `docker-ce` (если он уже установлен).
Кроме того, `docker.io` 26.1 в Debian-репо устаревший.

Используйте официальный Docker CE из `download.docker.com`.

### Сколько времени занимает?

- **Подготовка хоста**: ~10–15 минут
- **Сборка 3 patched-образов**: 15–20 мин на RPi 4 (qemu), 3–5 мин на x86_64
- **Запуск стека + инициализация cobblerd**: ~3–5 мин
- **Итого**: ~25–30 мин на RPi, ~10–15 мин на x86_64

---

## Сетевые вопросы

### Что если у меня только один интерфейс?

Роль требует **минимум 2 интерфейса**:
1. **PXE** (`eth0` по умолчанию) — для раздачи IP загрузчикам
2. **Internet/NAT** (`wlan0` по умолчанию) — для выхода PXE-клиентов в интернет

Можно использовать один интерфейс для обоих целей, но это требует
ручной настройки и не рекомендуется для production.

### Можно использовать Wi-Fi для PXE вместо eth0?

Технически возможно (802.11 поддерживает PXE через `iPXE`), но:
- Wi-Fi драйверы часто не поддерживают `promiscuous mode` (нужен для macvlan)
- Задержки выше, broadcast трафик менее надёжен

Лучше использовать проводной Ethernet для PXE.

### Что делать, если eth0 без кабеля (на этапе установки)?

Роль работает: macvlan создаётся с `ConfigureWithoutCarrier=yes`.
eth0.10 будет в состоянии `LOWERLAYERDOWN`, но поднимется
автоматически при подключении кабеля.

### Как сменить PXE-подсеть после установки?

Измените переменные в `group_vars/all.yml`:
- `cobbler_pxe_network`
- `cobbler_pxe_ip`

Затем перезапустите playbook с `--tags network`:
```bash
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml --tags network
```

---

## После установки

### Как зайти в Web UI?

```
http://<cobbler_mgmt_ip>/
```

Логин/пароль по умолчанию: `cobbler` / `cobbler`
(меняется в `group_vars/all.yml` через `cobbler_default_user/password`).

### Как импортировать дистрибутив?

Через CLI:
```bash
docker exec -it cobbler-stack-cobblerd-1 cobbler import \
  --path=/mnt --name=ubuntu-22.04 --arch=x86_64
```

Или через Web UI: Distros → Add distro → укажите ISO или URL.

### Как пересобрать patched-образы?

```bash
make rebuild
# или
ansible-playbook -i inventories/myhost/hosts.yml playbooks/rebuild.yml
```

### Где хранятся данные Cobbler (distros, профили)?

В `cobbler-stack_cobbler-var-lib` Docker volume
(`/var/lib/cobbler` внутри контейнера `cobblerd`).

Бэкап:
```bash
docker run --rm -v cobbler-stack_cobbler-var-lib:/data \
  -v $(pwd)/backup:/backup alpine \
  tar czf /backup/cobbler-var-lib-$(date +%F).tar.gz -C /data .
```

---

## Безопасность

### Где хранятся пароли?

- **Web UI пароль** (`cobbler_default_password`) → в `/etc/cobbler/users.digest`
  внутри volume `cobbler-stack_cobbler-etc` (SHA3-512 хеш)
- **API ключи** → в `/etc/cobbler/auth.conf`

Нигде не хранятся в открытом виде.

### Как сменить пароль?

1. Сгенерируйте новый SHA3-512 хеш:
 ```bash
   python3 -c "import hashlib; print(f'cobbler:Cobbler:{hashlib.sha3_512(b\"newpass\".hexdigest()}')"
   ```
2. Положите его в volume:
 ```bash
   echo "cobbler:Cobbler:<hash>" > /tmp/users.digest
   docker stop cobbler-stack-cobblerd-1
   docker run --rm --platform linux/amd64 \
     -v cobbler-stack_cobbler-etc:/data \
     -v /tmp:/backup:ro \
     alpine sh -c "cp /backup/users.digest /data/users.digest"
   docker start cobbler-stack-cobblerd-1
   ```

### Безопасно ли использовать дефолтный пароль `cobbler/cobbler`?

**Нет.** Перед использованием в production:
1. Смените пароль (см. выше)
2. Закройте Traefik dashboard (`127.0.0.1:8082`) если не нужен
3. Используйте firewall для ограничения доступа к `cobbler_mgmt_ip:80`

### Поддерживается ли HTTPS?

Нет, в текущей версии. Traefik слушает на `0.0.0.0:80` (без TLS).
Для HTTPS добавьте перед Traefik reverse-proxy с Let's Encrypt
(caddy, nginx-certbot, и т.п.).

---

## Производительность

### Сборка образов на RPi 4 занимает 20 минут — можно быстрее?

Варианты ускорения:
- **Собирайте на x86_64** и переносите через `docker save/load`
- **Используйте BuildKit cache**: `--cache-from type=local,src=/tmp/buildkit`
- **Соберите один раз**, дальше `cobbler_skip_builds: true`

### nginx `io_setup() failed` — что делать?

Это особенность qemu-эмуляции x86_64 на aarch64. 4 из 5 worker
падают, но master-worker (PID 1) обслуживает все запросы. Web UI работает,
но с пониженной производительностью.

Workaround:
```bash
docker exec cobbler-stack-web-1 sh -c \
  "sed -i '1i aio threads;' /etc/nginx/conf.d/default.conf && kill -HUP 1"
```

### Можно ли использовать более лёгкий web-сервер вместо nginx?

Теоретически можно (caddy, например). Но это потребует изменения
`patch-nginx.sh.j2` и `Dockerfile.cobbler-web.j2` — выходит за рамки
данной роли.

---

## Troubleshooting

### Где смотреть логи?

```bash
# Все контейнеры
cd /opt/cobbler-stack && docker compose logs -f

# Конкретный сервис
docker logs cobbler-stack-cobblerd-1 --tail 50
docker logs cobbler-stack-traefik-1 --tail 20

# Systemd
journalctl -u cobbler-recover --no-pager -n 50

# Ansible
cat /tmp/cobbler-install.log
```

### Плейбук зависает на "Ожидание готовности Web UI"

Скорее всего, Traefik слушает только на `cobbler_mgmt_ip`, а Ansible
проверяет `127.0.0.1`. В `compose.yml` должно быть `0.0.0.0:80:80`.
Исправлено в v1.1.0.

См. [TROUBLESHOOTING.md](TROUBLESHOOTING.md#an-unexpected-docker-error-occurred-invalid-subinterface-vlan-name-eth0-host).

### Web UI отвечает, но логин не работает (`faultCode 1`)

Файл `/etc/cobbler/users.digest` пустой. Скорее всего использовался Python 3.13,
где нет модуля `crypt`.

См. раздел "Безопасность" выше или [TROUBLESHOOTING.md](TROUBLESHOOTING.md#xml-rpc-login-faultcode-1-не-удаётся-войти-в-web-ui).

### Как полностью удалить?

```bash
ansible-playbook -i inventories/myhost/hosts.yml playbooks/uninstall.yml

# Вручную удалить volumes (содержат данные Cobbler):
```bash
docker volume rm cobbler-stack_cobbler-var-lib \
               cobbler-stack_cobbler-etc \
               cobbler-stack_cobbler-tftproot \
               cobbler-stack_cobbler-webdir \
               cobbler-stack_cobbler-dns-zones \
               cobbler-stack_cobbler-dns-config \
               cobbler-stack_cobbler-dhcp-config

# Удалить macvlan
ip link set eth0.10 down
ip link delete eth0.10
rm /etc/systemd/network/20-eth0.10.netdev /etc/systemd/network/20-eth0.10.network
```

---

## Разработка

### Как добавить новую переменную?

1. Добавьте в `roles/cobbler/defaults/main.yml` с комментарием
2. Обновите README (секция "Переменные роли")
3. Обновите CHANGELOG
4. Добавьте тест в `molecule/default/verify.yml`

### Как протестировать локально?

```bash
make lint
make syntax-check
make molecule     # нужен Docker daemon с systemd
```

### Как обновить версию?

1. Измените версию в `CHANGELOG.md`
2. Сделайте `git tag -a vX.Y.Z -m "..."`
4. `git push --tags` — workflow `release.yml` автоматически создаст GitHub Release

---

## Где задать ещё вопрос?

- 🐛 [Bug Report](../../issues/new?template=bug_report.md)
- 💡 [Feature Request](../../issues/new?template=feature_request.md)
- 💬 [Discussions](../../discussions) (общие вопросы)
- 📖 Документация: [README](README.md) · [PREREQUISITES](PREREQUISITES.md) · [ARCHITECTURE](ARCHITECTURE.md) · [TROUBLESHOOTING](TROUBLESHOOTING.md)
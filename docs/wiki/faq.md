# FAQ

Полный FAQ с ~30 вопросами — в [`docs/FAQ.md`](https://github.com/kprklg/ansible-cobbler/blob/main/docs/FAQ.md).

## Топ-10 самых частых

### Можно установить одной командой?

Не совсем. Перед `ansible-playbook` нужно вручную:
- установить apt-пакеты
- поставить Docker из официального репо
- создать инвентарь и `group_vars/all.yml`

Сама роль — да, одной командой:
```
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

### Почему нельзя использовать `docker.io` из Debian?

Конфликтует с `docker-ce` и устаревший. Используйте официальный `download.docker.com`.

### Сколько времени занимает?

20-30 мин на RPi 4 (с qemu), 10-15 мин на x86_64.

### Что делать, если eth0 без кабеля?

Работает! macvlan с `ConfigureWithoutCarrier=yes` поднимется автоматически
при подключении кабеля.

### Как зайти в Web UI?

`http://<cobbler_mgmt_ip>/`, логин `cobbler`, пароль `cobbler`.

### Как импортировать ISO?

```bash
docker exec -it cobbler-stack-cobblerd-1 cobbler import \
  --path=/mnt --name=ubuntu-22.04 --arch=x86_64
```

### Не работает логин (`faultCode 1`)

Скорее всего, `users.digest` пустой. См. [Troubleshooting → cobblerd](troubleshooting/common.md#cobblerd).

### Как пересобрать образы?

```bash
docker rmi -f cobbler/cobblerd-patched:latest cobbler/cobbler-web-patched:latest cobbler/cobbler-dns-patched:latest
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags build
```

### Как сделать HTTPS?

В текущей версии нет. Traefik слушает на `0.0.0.0:80` без TLS.
Добавьте reverse-proxy с Let's Encrypt (caddy, nginx-certbot).

### Как удалить?

```bash
ansible-playbook -i inventory/myhost/hosts.yml playbooks/uninstall.yml

# Volumes (содержат данные):
docker volume rm cobbler-stack_cobbler-var-lib \
               cobbler-stack_cobbler-etc \
               cobbler-stack_cobbler-tftproot \
               cobbler-stack_cobbler-webdir \
               cobbler-stack_cobbler-dns-zones \
               cobbler-stack_cobbler-dns-config \
               cobbler-stack_cobbler-dhcp-config

# macvlan:
ip link set eth0.10 down
ip link delete eth0.10
rm /etc/systemd/network/20-eth0.10.*
```

## Полный FAQ

См. [`docs/FAQ.md`](https://github.com/kprklg/ansible-cobbler/blob/main/docs/FAQ.md) —
30+ вопросов в 8 секциях.
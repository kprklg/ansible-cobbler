# Переменные роли

Полный список переменных `roles/cobbler/defaults/main.yml`.

## Сеть

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_mgmt_ip` | `ansible_host` | IP хоста для Web UI |
| `cobbler_pxe_iface` | `eth0` | Физический интерфейс для PXE |
| `cobbler_wifi_iface` | `wlan0` | Интерфейс для NAT в интернет |
| `cobbler_pxe_network` | `10.254.254.0/24` | Подсеть PXE-клиентов |
| `cobbler_pxe_ip` | `10.254.254.1/24` | IP macvlan-интерфейса |
| `cobbler_mgmt_network` | `10.17.0.0/16` | Внутренняя docker-сеть для cobbler |
| `cobbler_macvlan_configure_without_carrier` | `true` | Работать даже без кабеля в eth0 |

### Offsets для IP в compose

Эти переменные управляют тем, какие IP получат контейнеры в PXE-сетке:

| Переменная | Default | Контейнер | Сеть |
|---|---|---|---|
| `cobbler_tftp_ip_offset` | 4 | cobbler-tftp | pxe_network |
| `cobbler_dhcp_ip_offset` | 2 | cobbler-dhcp | pxe_network |
| `cobbler_dns_ip_offset` | 3 | cobbler-dns | pxe_network |
| `cobbler_tftp_mgmt_ip_offset` | 20 | cobbler-tftp | mgmt_network |
| `cobbler_dhcp_mgmt_ip_offset` | 21 | cobbler-dhcp | mgmt_network |
| `cobbler_dns_mgmt_ip_offset` | 22 | cobbler-dns | mgmt_network |

!!! info "Как считается"
    `ipaddr('net')` берёт подсеть, `ipaddr('+N')` добавляет N к последнему октету.

## Аутентификация

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_default_user` | `cobbler` | Web UI логин |
| `cobbler_default_password` | `cobbler` | Web UI пароль |

!!! warning "Смените перед production!"
    Дефолтный пароль — только для тестирования.

## Установка

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_workdir` | `/opt/cobbler-stack` | Рабочая директория |
| `cobbler_web_image_version` | `v1.2.0` | Версия `cobbler-web` |
| `cobbler_dhcp_image` | `ghcr.io/cobbler/cobbler-dhcp:latest` | Upstream DHCP |
| `cobbler_dns_image` | `ghcr.io/cobbler/cobbler-dns:latest` | Upstream DNS |
| `cobbler_tftp_image` | `ghcr.io/cobbler/cobbler-tftp:latest` | Upstream TFTP |
| `cobbler_web_image` | `ghcr.io/cobbler/cobbler-web:{{ cobbler_web_image_version }}` | Web |
| `cobbler_traefik_image` | `traefik:v3.6` | Traefik |

### Поведение

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_skip_builds` | `false` | Не пересобирать образы (использовать кэш) |
| `cobbler_skip_webroot` | `false` | Не извлекать webroot из upstream |
| `cobbler_rebuild_images` | `false` | Принудительная пересборка |
| `cobbler_skip_stack` | `false` | Не запускать `docker compose up` |
| `cobbler_qemu_emulation` | `auto` | Когда ставить qemu: `always`, `auto`, `never` |
| `cobbler_supported_archs` | `[aarch64, x86_64]` | Поддерживаемые архитектуры |

## Systemd

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_systemd_service_name` | `cobbler-recover` | Имя systemd-сервиса |
| `cobbler_systemd_timeout` | `300` | Таймаут systemd (сек) |

## Traefik (отладка)

| Переменная | Default | Описание |
|---|---|---|
| `cobbler_traefik_dashboard_port` | `8082` | Порт dashboard Traefik |

## Примеры

### Изменить PXE-подсеть

```yaml
# group_vars/all.yml
cobbler_pxe_network: "192.168.100.0/24"
cobbler_pxe_ip: "192.168.100.1/24"
```

### Использовать другой порт Web UI

```yaml
cobbler_traefik_dashboard_port: 8443
```

После изменения — перезапустить:

```bash
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags stack
```

### Сменить дефолтные offsets

```yaml
cobbler_tftp_ip_offset: 10
cobbler_dhcp_ip_offset: 11
cobbler_dns_ip_offset: 12
```

### Использовать x86_64 образ Cobbler

```yaml
cobbler_supported_archs: ["x86_64"]
cobbler_qemu_emulation: "never"
```

!!! warning "На aarch64 это сломает установку"
    Cobbler-образы — только x86_64, эмуляция обязательна.
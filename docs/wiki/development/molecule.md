# Molecule-сценарии

[Molecule](https://github.com/ansible-community/molecule) — стандартный
способ тестирования Ansible-ролей. Использует Docker для прогона роли в
чистой среде.

## Структура

```
molecule/
└── default/
    ├── molecule.yml      # описание платформ + lifecycle
    ├── converge.yml      # что запускать (обычно роль)
    ├── verify.yml        # проверки после converge
    └── prepare.yml       # подготовка хоста перед converge
```

## Запуск

```bash
make molecule
# или
molecule test -s default
```

## Что проверяется

### 1. dependency

`ansible-galaxy collection install community.docker` — устанавливает
зависимости.

### 2. syntax

Синтакс-проверка всех плейбуков и роли.

### 3. create

Создаёт 2 Docker-контейнера:

- `cobbler-test-x86_64` (нативный x86_64)
- `cobbler-test-aarch64` (через qemu-user-static)

Оба основаны на `debian:13-slim` с systemd.

### 4. prepare

Устанавливает apt-пакеты, которые ожидает роль:
- `qemu-user-static`, `binfmt-support`
- `iptables-persistent` (с preseed)
- `python3-passlib`

Также создаёт фейковый `/usr/local/bin/docker` для preflight-проверок.

### 5. converge

Запускает роль `cobbler` с пропуском тяжёлых шагов:

```yaml
cobbler_skip_builds: true
cobbler_skip_webroot: true
cobbler_skip_stack: true
```

Это позволяет проверить:

- preflight
- dependencies
- macvlan (eth0.10)
- nat (iptables MASQUERADE)

Без реального Docker-демона.

### 6. idempotence

Повторный прогон должен вернуть `ok=0 changed=0` (никаких изменений).

### 7. verify

Проверки:

- `/etc/systemd/network/20-eth0.10.netdev` существует
- `/etc/systemd/network/20-eth0.10.network` существует
- `iptables -t nat -L POSTROUTING` содержит `MASQUERADE`
- `/proc/sys/net/ipv4/ip_forward == 1`
- `ip link show eth0.10` показывает интерфейс

### 8. destroy

Удаляет Docker-контейнеры.

## Написание своих сценариев

Пример — сценарий для проверки docker compose стека:

```yaml
# molecule/stack/molecule.yml
---
dependency:
  name: galaxy

driver:
  name: docker

platforms:
  - name: cobbler-test
    image: debian:13-slim
    privileged: true
    command: /lib/systemd/systemd

provisioner:
  name: ansible
  inventory:
    group_vars:
      all:
        cobbler_mgmt_ip: "192.168.0.88"
        cobbler_skip_builds: false
        cobbler_skip_webroot: false

verifier:
  name: ansible

scenario:
  name: stack
  test_sequence:
    - dependency
    - syntax
    - create
    - prepare
    - converge
    - verify
    - destroy
```

## Полезные команды

```bash
# Прогнать только до prepare (без converge)
molecule converge -s default -- --check --diff

# Зайти в контейнер вручную
molecule login -s default -h cobbler-test-x86_64

# Пересоздать контейнеры
molecule reset -s default

# Подробный вывод
molecule test -s default -vvv

# Только verify
molecule verify -s default
```

## Известные ограничения

1. **qemu-user-static** на хосте должен быть установлен (для aarch64 платформы)
2. **systemd** в контейнерах — нужны `--privileged` и `command: /lib/systemd/systemd`
3. **docker-in-docker** не реализован — поэтому тестируем без реального стека

## См. также

- [Molecule documentation](https://ansible.readthedocs.io/projects/molecule/)
- [Local Testing](local-testing.md)
# Поддерживаемые архитектуры

## Сводная таблица

| Arch | Cobbler | Эмуляция | qemu-user-static | Производительность |
|---|---|---|---|---|
| **aarch64** (RPi 3/4/5) | через qemu-user-static | ✅ требуется | устанавливается автоматически | ~5-10× медленнее |
| **x86_64** (Intel/AMD) | нативно | ❌ не нужна | НЕ устанавливается | нативная скорость |

## aarch64 (Raspberry Pi)

### Что происходит

На RPi 4 Docker-образы Cobbler запускаются через **qemu-user-static** —
эмулятор x86_64 в userspace, который прозрачно запускает x86_64-бинарники
на aarch64-хостe через binfmt_misc.

```bash
# Эмуляция включена:
cat /proc/sys/fs/binfmt_misc/qemu-x86_64
# → enabled
# → interpreter /usr/libexec/qemu-binfmt/x86_64-binfmt-P
```

### Производительность

Сборка 3 patched-образов (cobblerd, cobbler-web, cobbler-dns) на RPi 4:

- **Без эмуляции (на x86_64)**: 3-5 мин
- **С эмуляцией (на RPi 4)**: 15-20 мин

Инициализация cobblerd через qemu после старта контейнера: ~3-5 мин.

### Известные ограничения

- **nginx в web-контейнере**: `io_setup() failed (Function not implemented)`
  на 4/5 worker-процессов на aarch64. Master-worker работает, но нагрузочная способность ниже.

### Установка qemu

Роль устанавливает `qemu-user-static` и `binfmt-support` автоматически, **только** на aarch64 хостах.

На хосте **заранее** должен быть установлен один из пакетов (apt):

```bash
apt-get install -y qemu-user-static binfmt-support
```

Это нужно сделать до запуска плейбука.

## x86_64

### Что происходит

Docker-образы Cobbler запускаются **нативно**, без эмуляции.
Производительность — максимальная.

### Использование на x86_64

Роль автоматически определяет архитектуру через `ansible_architecture` и
переключается между режимами:

```yaml
# Не нужно менять ничего! Роль сама:
# 1. На aarch64 → устанавливает qemu, использует --platform linux/amd64
# 2. На x86_64 → НЕ устанавливает qemu, использует нативный режим
```

## Проверка поддержки

```bash
# Локально
ansible localhost -m debug -a "msg={{ ansible_architecture }}"

# В playbook
ansible-playbook -i inventory/... playbooks/site.yml --tags preflight
```

Если архитектура не в `cobbler_supported_archs` (по умолчанию `[aarch64, x86_64]`),
плейбук завершится с ошибкой.

## Изменение списка поддерживаемых архитектур

```yaml
# Только x86_64
cobbler_supported_archs: ["x86_64"]
cobbler_qemu_emulation: "never"

# Только aarch64
cobbler_supported_archs: ["aarch64"]
cobbler_qemu_emulation: "always"

# Обе (по умолчанию)
cobbler_supported_archs: ["aarch64", "x86_64"]
cobbler_qemu_emulation: "auto"
```

## См. также

- [Architecture → Overview](../architecture/overview.md)
- [Prerequisites → qemu](../installation/prerequisites.md#шаг-4-проверить-эмуляцию-только-на-aarch64)
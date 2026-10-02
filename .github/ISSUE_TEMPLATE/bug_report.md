---
name: Bug Report
about: Сообщить об ошибке в установке или работе роли
title: '[BUG] '
labels: bug
assignees: ''
---

## Описание

<!-- Краткое описание проблемы -->

## Шаги для воспроизведения

```bash
# Команды, которые приводят к ошибке
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

## Ожидание

<!-- Что должно произойти -->

## Реальность

<!-- Что происходит на самом деле -->

## Окружение

- **Версия роли**: (`git describe --tags` или `git log -1 --oneline`)
- **Платформа**: (Debian 13 / Ubuntu 24.04 / ...)
- **Архитектура**: (aarch64 / x86_64)
- **Модель**: (Raspberry Pi 4 / Intel NUC / ...)
- **Ansible**: (`ansible --version | head -2`)
- **Python**: (`python3 --version`)
- **Docker**: (`docker --version`)
- **Версия upstream cobbler**:
  ```bash
  docker inspect ghcr.io/cobbler/cobblerd:latest --format '{{ index .Config.Labels "org.opencontainers.image.version" }}'
  ```

## Логи

<!-- Вставьте сюда вывод `ansible-playbook ... -vvv` или `docker logs cobbler-stack-...` -->

```text
PASTE LOGS HERE
```

## Что уже пробовали

<!-- Какие шаги уже предпринимали для решения -->

## Чек-лист

- [ ] Использую последнюю версию роли (`git pull && git checkout v1.1.0`)
- [ ] Прочитал `TROUBLESHOOTING.md`
- [ ] Поискал в существующих issues
- [ ] Установка прерышена `==` на конкретном таске (не доходит до конца)
- [ ] Установка завершается, но сервис не работает
---
name: Bug Report
about: Сообщить об ошибке / Report a bug
title: '[BUG] '
labels: bug
assignees: ''
---

<!--
🇷🇺 Если удобнее — заполните только секцию «Русский» ниже.
🇬🇧 If easier — fill in only the «English» section below.
-->

## 🇷🇺 Русский

### Описание

<!-- Краткое описание проблемы -->

### Шаги для воспроизведения

```bash
# Команды, которые приводят к ошибке
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

### Ожидание

<!-- Что должно произойти -->

### Реальность

<!-- Что происходит на самом деле -->

### Окружение

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

### Логи

<!-- Вставьте вывод `ansible-playbook ... -vvv` или `docker logs cobbler-stack-...` -->

```text
PASTE LOGS HERE
```

### Что уже пробовали

<!-- Какие шаги уже предпринимали для решения -->

### Чек-лист

- [ ] Использую последнюю версию роли (`git pull && git checkout v1.1.1`)
- [ ] Прочитал `TROUBLESHOOTING.md`
- [ ] Поискал в существующих issues
- [ ] Установка обрывается на конкретном таске (не доходит до конца)
- [ ] Установка завершается, но сервис не работает

---

## 🇬🇧 English

### Description

<!-- Brief description of the issue -->

### Steps to reproduce

```bash
# Commands that trigger the bug
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

### Expected behaviour

<!-- What should happen -->

### Actual behaviour

<!-- What actually happens -->

### Environment

- **Role version**: (`git describe --tags` or `git log -1 --oneline`)
- **Platform**: (Debian 13 / Ubuntu 24.04 / ...)
- **Architecture**: (aarch64 / x86_64)
- **Model**: (Raspberry Pi 4 / Intel NUC / ...)
- **Ansible**: (`ansible --version | head -2`)
- **Python**: (`python3 --version`)
- **Docker**: (`docker --version`)
- **Upstream cobbler version**:
  ```bash
  docker inspect ghcr.io/cobbler/cobblerd:latest --format '{{ index .Config.Labels "org.opencontainers.image.version" }}'
  ```

### Logs

<!-- Paste the output of `ansible-playbook ... -vvv` or `docker logs cobbler-stack-...` -->

```text
PASTE LOGS HERE
```

### What you tried

<!-- What steps you already took to resolve -->

### Checklist

- [ ] I am on the latest role version (`git pull && git checkout v1.1.1`)
- [ ] I have read `TROUBLESHOOTING.md`
- [ ] I have searched existing issues
- [ ] The install aborts at a specific task (does not reach the end)
- [ ] The install completes but the service does not work
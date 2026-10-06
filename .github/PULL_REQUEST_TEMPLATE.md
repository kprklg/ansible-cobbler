<!--
🇷🇺 Если удобнее — заполните только секцию «Русский» ниже.
🇬🇧 If easier — fill in only the «English» section below.
-->

## 🇷🇺 Русский

### Что сделано

<!-- Краткое описание изменений -->

### Тип PR

- [ ] Bug fix (non-breaking change, исправляет ошибку)
- [ ] New feature (non-breaking change, добавляет функциональность)
- [ ] Breaking change (ломает существующее поведение — опишите в разделе миграции)
- [ ] Documentation (только документация)

### Связанные issue

<!-- Closes #N, Fixes #N -->

### Тестирование

<!-- Как тестировали изменения -->

- [ ] Прошёл syntax-check (`ansible-playbook --syntax-check`)
- [ ] Установка с нуля прошла полностью на RPi 4 (aarch64)
- [ ] Установка с нуля прошла полностью на x86_64
- [ ] Web UI доступен, логин работает
- [ ] `docker compose ps` показывает все 7 контейнеров `healthy`/`Up`
- [ ] Systemd-сервис `cobbler-recover` включён

### Чек-лист

- [ ] Code follows the style guidelines (`yamllint` без warnings)
- [ ] Self-review пройден
- [ ] Comments добавлены в сложных местах
- [ ] `CHANGELOG.md` обновлён (если значимо)
- [ ] `README.md` / `PREREQUISITES.md` / `TROUBLESHOOTING.md` обновлены (если нужно)
- [ ] Нет новых warnings от ansible-playbook (deprecation и т.п.)
- [ ] Все коммиты в этой ветке подписаны осмысленными сообщениями

### Логи тестовой установки

```text
PASTE ansible-playbook OUTPUT (только PLAY RECAP строка)
```

### Скриншоты / логи

<!-- Если есть, приложите -->

### Дополнительный контекст

<!-- Что угодно ещё, что поможет reviewer'у понять PR -->

---

## 🇬🇧 English

### What changed

<!-- Brief description of the changes -->

### Type of PR

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing
      functionality to not work as expected — describe in migration)
- [ ] Documentation (docs-only changes)

### Related issues

<!-- Closes #N, Fixes #N -->

### Testing

<!-- How did you test the changes -->

- [ ] `ansible-playbook --syntax-check` passes
- [ ] Fresh install completes on RPi 4 (aarch64)
- [ ] Fresh install completes on x86_64
- [ ] Web UI is reachable, login works
- [ ] `docker compose ps` shows all 7 containers as `healthy`/`Up`
- [ ] Systemd unit `cobbler-recover` is enabled

### Checklist

- [ ] Code follows the style guidelines (`yamllint` no warnings)
- [ ] Self-reviewed
- [ ] Comments added in non-trivial areas
- [ ] `CHANGELOG.md` updated (if relevant)
- [ ] `README.md` / `PREREQUISITES.md` / `TROUBLESHOOTING.md` updated (if relevant)
- [ ] No new ansible-playbook warnings (deprecation etc.)
- [ ] All commits in this branch have meaningful messages

### Test install logs

```text
PASTE ansible-playbook OUTPUT (PLAY RECAP line only)
```

### Screenshots / logs

<!-- If applicable, attach here -->

### Additional context

<!-- Anything else that helps the reviewer understand the PR -->
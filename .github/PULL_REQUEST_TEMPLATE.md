## Что сделано

<!-- Краткое описание изменений -->

## Тип PR

- [ ] Bug fix (non-breaking change, исправляет ошибку)
- [ ] New feature (non-breaking change, добавляет функциональность)
- [ ] Breaking change (ломает существующее поведение — опишите в разделе миграции)
- [ ] Documentation (только документация)

## Связанные issue

<!-- Closes #N, Fixes #N -->

## Тестирование

<!-- Как тестировали изменения -->

- [ ] Прошёл syntax-check (`ansible-playbook --syntax-check`)
- [ ] Установка с нуля прошла полностью на RPi 4 (aarch64)
- [ ] Установка с нуля прошла полностью на x86_64
- [ ] Web UI доступен, логин работает
- [ ] `docker compose ps` показывает все 7 контейнеров `healthy`/`Up`
- [ ] Systemd-сервис `cobbler-recover` включён

## Чек-лист

- [ ] Code follows the style guidelines (`yamllint` без warnings)
- [ ] Self-review пройден
- [ ] Comments добавлены в сложных местах
- [ ] `CHANGELOG.md` обновлён (если значимо)
- [ ] `README.md` / `PREREQUISITES.md` / `TROUBLESHOOTING.md` обновлены (если нужно)
- [ ] Нет новых warnings от ansible-playbook (deprecation и т.п.)
- [ ] Все коммиты в этой ветке подписаны осмысленными сообщениями

## Логи тестовой установки

```text
PASTE ansible-playbook OUTPUT (только PLAY RECAP строка)
```

## Скриншоты / логи

<!-- Если есть, приложите -->

## Дополнительный контекст

<!-- Что угодно ещё, что поможет reviewer'у понять PR -->
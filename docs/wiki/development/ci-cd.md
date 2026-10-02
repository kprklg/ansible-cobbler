# CI/CD

Проект использует GitHub Actions для непрерывной интеграции.

## Workflows

### `lint.yml`

**Триггер:** push в main, push тега v*, pull_request в main

**Что делает:**

1. **yamllint** — проверка YAML-файлов на соответствие `.yamllint`
2. **ansible-lint** — проверка роли, плейбуков и инвентарей

### `syntax-check.yml`

**Триггер:** push в main, push тега v*, pull_request в main

**Что делает:**

Матрица Ansible 2.14, 2.15, 2.16, 2.17, 2.18, 2.19 × 4 плейбука:

- `playbooks/site.yml`
- `playbooks/deploy.yml`
- `playbooks/rebuild.yml`
- `playbooks/uninstall.yml`

Для каждой комбинации запускается `ansible-playbook --syntax-check`.

### `aarch64-smoke.yml`

**Триггер:** push в main, push тега v*, pull_request в main

**Runner:** `ubuntu-24.04-arm` (реальный ARM, не эмуляция)

**Что делает:**

1. Рендерит `compose.yml.j2` с реальными group_vars
2. Проверяет, что в финальном compose нет IPv4-адресов с CIDR-маской
   (регрессия из v1.0.0)

### `release.yml`

**Триггер:** push тега `v*.*.*`

**Что делает:**

1. Извлекает секцию из `CHANGELOG.md` для текущей версии
2. Создаёт GitHub Release с этой changelog-секцией
3. Помечает как prerelease, если в теге есть `-`

### `galaxy-publish.yml`

**Триггер:** push тега `v*.*.*`

**Что делает:**

1. Устанавливает Ansible
2. Запускает `ansible-galaxy role import kprklg.cobbler`
3. Роль появляется в [Ansible Galaxy](https://galaxy.ansible.com/kprklg/cobbler)

### `pre-commit.yml`

**Триггер:** push в main, push тега v*, pull_request в main

**Что делает:**

Запускает pre-commit хуки (yamllint, ansible-lint, commitizen, shellcheck)
на всех файлах.

## Status checks

PR не может быть смержен, пока не пройдут все обязательные checks:

- ✅ `lint` — yamllint + ansible-lint
- ✅ `syntax-check` — все 4 плейбука на Ansible 2.14-2.19
- ✅ `aarch64-smoke` — рендеринг на ARM
- ✅ `pre-commit` — pre-commit хуки

`release` и `galaxy-publish` запускаются только при push тега.

## Badges в README

```markdown
[![lint](https://github.com/kprklg/ansible-cobbler/actions/workflows/lint.yml/badge.svg)](...)
[![syntax-check](https://github.com/kprklg/ansible-cobbler/actions/workflows/syntax-check.yml/badge.svg)](...)
[![aarch64-smoke](https://github.com/kprklg/ansible-cobbler/actions/workflows/aarch64-smoke.yml/badge.svg)](...)
```

## Конфигурация secrets

| Secret | Где используется | Как получить |
|---|---|---|
| `GALAXY_API_KEY` | `galaxy-publish.yml` | https://galaxy.ansible.com/me/preferences |

Для добавления: Settings → Secrets and variables → Actions → New repository secret.

## Локальный запуск workflows

Некоторые workflow можно запустить локально:

```bash
# yamllint + ansible-lint = lint.yml
make lint

# syntax-check = syntax-check.yml
make syntax-check

# aarch64-smoke (частично) = aarch64-smoke.yml
# Требует настоящего aarch64 хоста

# release (частично) = release.yml
make release-patch   # создаёт patch-файлы для передачи
```

## Конфигурация Dependabot

`.github/dependabot.yml` автоматически создаёт PR для обновления:

- GitHub Actions (еженедельно, понедельник)
- Docker base images (еженедельно)

PR от Dependabot проходят через те же CI checks.

## Метрики

После каждого PR на dashboard GitHub Actions видно:

- Время выполнения каждого workflow
- Количество обнаруженных проблем
- Историю runs

## См. также

- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Molecule](molecule.md) — аналог для Ansible-тестов
- [Ansible Galaxy publishing](https://galaxy.ansible.com/docs/using/installing/)
# Conventional Commits

Этот проект использует [Conventional Commits](https://www.conventionalcommits.org/)
для сообщений коммитов.

## Зачем?

- Автоматическая генерация CHANGELOG
- Автоматическое определение версии (semver)
- Чёткая история изменений
- Возможность фильтровать коммиты по типу

## Формат

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Type

| Type | Описание | Пример |
|---|---|---|
| `feat` | Новая функциональность | `feat(compose): add support for custom DHCP lease time` |
| `fix` | Исправление бага | `fix(preflight): remove invalid Jinja delimiters in assert` |
| `docs` | Только документация | `docs: add FAQ section to README` |
| `style` | Форматирование без изменения логики | `style: fix trailing whitespace` |
| `refactor` | Рефакторинг кода | `refactor(stack): split into separate tasks` |
| `test` | Добавление тестов | `test: add Molecule scenarios for aarch64` |
| `ci` | Изменения в CI/CD | `ci: split monolithic test.yml` |
| `build` | Изменения в build-системе | `build: add Dockerfile.test` |
| `chore` | Прочие изменения | `chore: update .gitignore` |
| `perf` | Оптимизация | `perf(images): cache base layers` |

### Scope (опционально)

Соответствует директории/файлу:

- `preflight`, `dependencies`, `macvlan`, `nat`, `compose`, `webroot`,
  `images`, `volumes`, `stack`, `systemd` — для tasks
- `playbook` — для playbooks
- `docs`, `wiki` — для документации
- `ci`, `cd` — для workflows
- `meta` — для meta/main.yml

### Subject

- Не более 72 символов
- Строчные буквы (кроме имён)
- Без точки в конце
- Повелительное наклонение ("add", не "added")

### Body

- Объясните *что* и *почему*, а не *как*
- Ссылайтесь на issue/обсуждение, если есть
- Может быть в несколько абзацев

### Footer

```
Closes #42
Fixes #17

BREAKING CHANGE: <описание breaking change>
```

## Примеры

### Хорошие коммиты

```
fix(preflight): remove invalid Jinja delimiters in assert condition

The 'that' parameter expects a Jinja expression, not a template string.
Wrapping cobbler_supported_archs in {{ }} caused:
  Syntax error in template: Template delimiters are not supported
  in expressions
```

```
feat(compose): add cobbler_dhcp_lease_time variable

Allows configuring DHCP lease time per environment. Defaults to 86400
(24 hours) for production, can be set to 3600 (1 hour) for testing.

Closes #42
```

```
ci: split monolithic test.yml into focused workflows

The old test.yml had three sequential jobs and only ran on push,
with no PR feedback. Replace with four narrow workflows.
```

### Плохие коммиты

```
fix bug                    # слишком короткое, нет scope
Fixed thing                # прошедшее время
feat: Added feature        # capital A
fix: stuff.                # точка в конце
WIP                        # не descriptive
```

## BREAKING CHANGE

Для breaking changes добавляйте `BREAKING CHANGE:` в footer:

```
feat(stack): change default pull policy to 'missing'

BREAKING CHANGE: docker_compose_v2.pull now defaults to 'missing'
instead of 'never'. Run-once images will no longer be auto-updated.

Closes #99
```

## Инструменты

### Локальная проверка

```bash
# Установить commitizen
pip install commitizen

# Проверить последний коммит
cz check

# Создать коммит через commitizen (поможет с форматом)
cz commit
```

### Pre-commit хук

После `pre-commit install` при каждом коммите автоматически
проверяется формат сообщения.

## Автогенерация версии

Conventional Commits → SemVer:

| Commit | Bump |
|---|---|
| `BREAKING CHANGE: ...` | Major (1.0.0 → 2.0.0) |
| `feat:` | Minor (1.0.0 → 1.1.0) |
| `fix:`, `perf:`, `refactor:` | Patch (1.0.0 → 1.0.1) |

Для автоматического определения версии можно использовать
[release-please](https://github.com/googleapis/release-please)
или [python-semantic-release](https://github.com/python-semantic-release/python-semantic-release).

## См. также

- [Conventional Commits specification](https://www.conventionalcommits.org/)
- [CONTRIBUTING.md](https://github.com/kprklg/ansible-cobbler/blob/main/CONTRIBUTING.md)
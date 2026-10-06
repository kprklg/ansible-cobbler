# Contributing to ansible-cobbler / Участие в проекте

> 🇬🇧 **English below** — see [English version](#english-version)
> 🇷🇺 **Русский ниже** — см. [Русская версия](#русская-версия)

---

<a id="english-version"></a>

# 🇬🇧 English

Thanks for your interest in the project! Any contribution is welcome
— from bugfixes to new features to documentation improvements.

## 📋 Contents

- [Code of Conduct](#code-of-conduct)
- [How to contribute](#how-to-contribute)
- [Report a bug](#report-a-bug)
- [Request a feature](#request-a-feature)
- [Pull Requests](#pull-requests)
- [Code style](#code-style)
- [Commit messages](#commit-messages)
- [Local testing](#local-testing)

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
By participating, you agree to abide by its rules.

## How to contribute

There are several ways:

- 🐛 [Report a bug](../../issues/new?template=bug_report.md)
- 💡 [Request a feature](../../issues/new?template=feature_request.md)
- 📝 Improve documentation (this file, README, TROUBLESHOOTING, etc.)
- 🔧 Fix a bug or add a feature (via Pull Request)
- 💬 Answer questions in [Discussions](../../discussions)

## Report a bug

Use the [bug report template](../../issues/new?template=bug_report.md).

Include:

- Role version (`git describe --tags` or `git log -1 --oneline`)
- Platform, architecture, Ansible/Python versions
- Exact error (including the `=== TASK ===` line at which the playbook failed)
- Output of `ansible-playbook -vvv` (if possible)

## Request a feature

Use the [feature request template](../../issues/new?template=feature_request.md).

Before opening an issue, check that something similar has not
already been proposed.

## Pull Requests

1. **Fork** the repository and create a branch from `main`:
 ```bash
   git checkout -b fix/my-bug
   # or
   git checkout -b feat/my-feature
   ```

2. **Make your changes** in accordance with the code style (see below).

3. **Add tests** (if applicable) — for the role this is mostly
   syntax-check and yamllint.

4. **Update documentation** if behaviour changes:
 - `README.md` — if the role interface changes
 - `PREREQUISITES.md` — if dependencies change
 - `TROUBLESHOOTING.md` — if you fix a known issue
 - `CHANGELOG.md` — add an entry in the next-version section
 - `defaults/main.yml` — comment any new variable

5. **Make sure CI is green**. Each push and PR runs:
 - `lint.yml` — yamllint + ansible-lint
 - `syntax-check.yml` — syntax-check on Ansible 2.14-2.19
 - `aarch64-smoke.yml` — Jinja rendering on a real ARM runner

6. **Use the PR template** — it appears automatically when you create a PR.

7. **Link the PR to an issue** if it closes one:
 ```
   Closes #42
   Fixes #17
   ```

8. **Be ready for review** — the maintainer may ask for changes.

## Code style

### YAML

- 2-space indents
- Maximum line length: 300 characters (warning, not error)
- Variable names start with the role prefix (`cobbler_*`)
- Add comments to non-trivial tasks

See `.yamllint` for the configuration.

### Jinja2

- `{{ var }}` with spaces
- `{% if condition %}` with spaces
- Avoid complex one-liners — prefer `set_fact` + `{{ var }}`
- `{% raw %}` blocks for Go-template syntax inside shell commands

### Python (patch scripts in `templates/`)

- Python 3.11+ (patches run in upstream images with Python 3.13)
- No third-party dependencies (use `hashlib`/`crypt`/`os`)
- Docstring at the top of each script

### Commit messages

See next section.

## Commit messages

We use [Conventional Commits](https://www.conventionalcommits.org/)
(simplified):

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

**Types:**

- `feat` — new feature
- `fix` — bug fix
- `docs` — docs only
- `style` — formatting, no logic change
- `refactor` — code refactor
- `test` — adding tests
- `ci` — CI/CD changes
- `build` — build system changes
- `chore` — other changes (deps, build, etc.)
- `perf` — performance

**Scope (optional):**

Matches the directory/file:

- `preflight`, `dependencies`, `macvlan`, `nat`, `compose`, `webroot`,
  `images`, `volumes`, `stack`, `systemd` — for tasks
- `playbook` — for playbooks
- `docs`, `wiki` — for documentation
- `ci`, `cd` — for workflows
- `meta` — for meta/main.yml

**Subject:**

- Max 72 chars
- Lowercase
- No trailing period
- Imperative ("add", not "added")

**Body:**

- Explain *what* and *why*, not *how* (visible from the diff)
- Reference issues/discussions when relevant
- May be multiple paragraphs

**Footer:**

```
Closes #42
Fixes #17

BREAKING CHANGE: <description>
```

## Local testing

### 1. Install prerequisites

```bash
make install-deps
make collections
pip install pre-commit
pre-commit install
```

After this, every commit runs `yamllint` and commit-message format
checks automatically.

### 2. Run all tests

```bash
make test
```

This is equivalent to:

```bash
make lint         # yamllint + ansible-lint
make syntax-check # --syntax-check for all playbooks
make molecule     # Molecule tests in Docker
```

### 3. Test specific tags

```bash
# Network only
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags network

# Image builds only
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags images

# Docker stack only
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags stack
```

### 4. Pre-PR checklist

- [ ] `make lint` passes
- [ ] `make syntax-check` passes
- [ ] `make molecule` passes (if you touched tasks/templates)
- [ ] `make pre-commit` passes
- [ ] If behaviour changed — README updated
- [ ] If you added a variable — `defaults/main.yml` + docs updated
- [ ] If you fixed a bug — entry added to CHANGELOG
- [ ] Commit message follows Conventional Commits

## See also

- [Molecule documentation](https://ansible.readthedocs.io/projects/molecule/)
- [Local Testing](development/local-testing.md)
- [Conventional Commits spec](https://www.conventionalcommits.org/)

---

<a id="русская-версия"></a>

# 🇷🇺 Русский

Спасибо за интерес к проекту! Любой вклад приветствуется — от багфиксов
до новых фич и улучшения документации.

## 📋 Содержание

- [Кодекс поведения](#кодекс-поведения)
- [Как внести вклад](#как-внести-вклад)
- [Сообщить о баге](#сообщить-о-баге)
- [Предложить улучшение](#предложить-улучшение)
- [Pull Requests](#pull-requests)
- [Стиль кода](#стиль-кода)
- [Сообщения коммитов](#сообщения-коммитов)
- [Локальное тестирование](#локальное-тестирование)

## Кодекс поведения

Этот проект следует [Contributor Covenant](CODE_OF_CONDUCT.md).
Участвуя, вы соглашаетесь следовать этим правилам.

## Как внести вклад

Есть несколько способов:

- 🐛 [Сообщить о баге](../../issues/new?template=bug_report.md)
- 💡 [Предложить улучшение](../../issues/new?template=feature_request.md)
- 📝 Улучшить документацию (этот файл, README, TROUBLESHOOTING и т.д.)
- 🔧 Исправить баг или добавить фичу (через Pull Request)
- 💬 Ответить на вопросы в [Discussions](../../discussions)

## Сообщить о баге

Используйте [bug report template](../../issues/new?template=bug_report.md).

Укажите:

- Версию роли (`git describe --tags` или `git log -1 --oneline`)
- Платформу, архитектуру, Ansible/Python версии
- Точную ошибку (включая `=== TASK ===` строку, на которой упал плейбук)
- Вывод `ansible-playbook -vvv` (если возможно)

## Предложить улучшение

Используйте [feature request template](../../issues/new?template=feature_request.md).

Перед созданием issue проверьте, что подобное ещё не предлагалось.

## Pull Requests

1. **Форкните** репозиторий и создайте ветку от `main`:
 ```bash
   git checkout -b fix/my-bug
   # или
   git checkout -b feat/my-feature
   ```

2. **Сделайте изменения** в соответствии со стилем кода (см. ниже).

3. **Добавьте тесты** (если применимо) — для роли это в основном
   syntax-check и yamllint.

4. **Обновите документацию**, если меняется поведение:
 - `README.md` — если меняется интерфейс роли
 - `PREREQUISITES.md` — если меняются зависимости
 - `TROUBLESHOOTING.md` — если фиксите известную проблему
 - `CHANGELOG.md` — добавьте запись в секцию следующей версии
 - `defaults/main.yml` — комментарий к новой переменной

5. **Убедитесь, что CI зелёный**. На каждом PR запустятся:
 - `lint.yml` — yamllint + ansible-lint
 - `syntax-check.yml` — syntax-check на Ansible 2.14-2.19
 - `aarch64-smoke.yml` — рендеринг на реальном ARM

6. **Используйте PR template** — он появится автоматически при создании PR.

7. **Свяжите PR с issue**, если он его закрывает:
 ```
   Closes #42
   Fixes #17
   ```

8. **Будьте готовы к review** — мейнтейнер может попросить доработки.

## Стиль кода

### YAML

- Используйте 2 пробела для отступа
- Максимальная длина строки: 300 символов (warning, не error)
- Имена переменных начинаются с префикса роли (`cobbler_*`)
- Добавляйте комментарии к нетривиальным task-ам

Конфигурация в `.yamllint`.

### Jinja2

- `{{ var }}` с пробелами
- `{% if condition %}` с пробелами
- Избегайте сложных выражений в одну строку — лучше `set_fact` + `{{ var }}`
- `{% raw %}` блоки для Go-template синтаксиса внутри shell команд

### Python (патч-скрипты в `templates/`)

- Python 3.11+ (патчи работают в upstream-образах с Python 3.13)
- Без сторонних зависимостей (используйте `hashlib`/`crypt`/`os`)
- Docstring в начале каждого скрипта

### Сообщения коммитов

См. следующий раздел.

## Сообщения коммитов

Используем [Conventional Commits](https://www.conventionalcommits.org/)
(упрощённый):

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

**Типы:**

- `feat` — новая функциональность
- `fix` — исправление бага
- `docs` — только документация
- `style` — форматирование, без изменения логики
- `refactor` — рефакторинг кода
- `test` — добавление тестов
- `ci` — изменения в CI/CD
- `build` — изменения в build-системе
- `chore` — прочие изменения (deps, build и т.п.)
- `perf` — оптимизация

**Scope (опционально):**

Соответствует директории/файлу:

- `preflight`, `dependencies`, `macvlan`, `nat`, `compose`, `webroot`,
  `images`, `volumes`, `stack`, `systemd` — для tasks
- `playbook` — для playbooks
- `docs`, `wiki` — для документации
- `ci`, `cd` — для workflows
- `meta` — для meta/main.yml

**Subject:**

- Не более 72 символов
- Строчные буквы
- Без точки в конце
- Повелительное наклонение ("add", не "added")

**Body:**

- Объясните *что* и *почему*, а не *как* (видно из diff)
- Ссылайтесь на issue/обсуждение, если есть
- Может быть в несколько абзацев

**Footer:**

```
Closes #42
Fixes #17

BREAKING CHANGE: <описание breaking change>
```

## Локальное тестирование

### 1. Подготовка окружения

```bash
make install-deps
make collections
pip install pre-commit
pre-commit install
```

После этого при каждом коммите автоматически:

- Запускается yamllint на изменённых файлах
- Проверяется формат Conventional Commits

### 2. Запуск тестов

```bash
make test
```

Это эквивалентно:

```bash
make lint         # yamllint + ansible-lint
make syntax-check # ansible-playbook --syntax-check для всех плейбуков
make molecule     # Molecule-тесты в Docker
```

### 3. Проверка конкретного тега

```bash
# Только сеть (macvlan + NAT)
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags network

# Только сборка образов
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags images

# Только docker compose up
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml --tags stack
```

### 4. Чек-лист перед PR

- [ ] `make lint` проходит без ошибок
- [ ] `make syntax-check` проходит
- [ ] `make molecule` проходит (если меняли tasks/templates)
- [ ] `make pre-commit` проходит
- [ ] Если менялось поведение — обновлён README
- [ ] Если добавляли переменную — обновлён `defaults/main.yml` + документация
- [ ] Если фиксите баг — добавлена запись в CHANGELOG
- [ ] Commit message в формате Conventional Commits

## См. также

- [Molecule documentation](https://ansible.readthedocs.io/projects/molecule/)
- [Local Testing](development/local-testing.md)
- [Conventional Commits specification](https://www.conventionalcommits.org/)

---

Спасибо за ваш вклад! 🙏 / Thank you for your contribution! 🙏
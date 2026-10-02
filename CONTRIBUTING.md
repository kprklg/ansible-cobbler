# Contributing to ansible-cobbler

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

---

## Кодекс поведения

Этот проект следует [Contributor Covenant](CODE_OF_CONDUCT.md). Участвуя,
вы соглашаетесь следовать этим правилам.

---

## Как внести вклад

Есть несколько способов:

- 🐛 [Сообщить о баге](../../issues/new?template=bug_report.md)
- 💡 [Предложить улучшение](../../issues/new?template=feature_request.md)
- 📝 Улучшить документацию (этот файл, README, TROUBLESHOOTING и т.д.)
- 🔧 Исправить баг или добавить фичу (через Pull Request)
- 💬 Ответить на вопросы в [Discussions](../../discussions)

---

## Сообщить о баге

Используйте [bug report template](../../issues/new?template=bug_report.md).

Укажите:
- Версию роли (`git describe --tags` или `git log -1 --oneline`)
- Платформу, архитектуру, Ansible/Python версии
- Точную ошибку (включая `=== TASK ===` строку, на которой упал плейбук)
- Вывод `ansible-playbook -vvv` (если возможно)

---

## Предложить улучшение

Используйте [feature request template](../../issues/new?template=feature_request.md).

Перед созданием issue проверьте, что подобное ещё не предлагалось.

---

## Pull Requests

1. **Форкните** репозиторий и создайте ветку от `main`:
 ```bash
   git checkout -b fix/my-bug
   # или
   git checkout -b feat/my-feature
   ```

2. **Сделайте изменения** в соответствии со стилем кода (см. ниже).

3. **Добавьте тесты** (если применимо) — для роли это в основном syntax-check и yamllint.

4. **Обновите документацию**, если меняется поведение:
 - `README.md` — если меняется интерфейс роли
 - `PREREQUISITES.md` — если меняются зависимости
 - `TROUBLESHOOTING.md` — если фиксите известную проблему
 - `CHANGELOG.md` — добавьте запись в секцию следующей версии
 - `defaults/main.yml` — комментарий к новой переменной

5. **Убедитесь, что CI зелёный**. На PR запустятся:
 - `lint.yml` — yamllint + ansible-lint
 - `syntax-check.yml` — syntax-check на Ansible 2.14–2.19
 - `aarch64-smoke.yml` — Jinja-рендеринг на реальном ARM

6. **Используйте PR template** — он появится автоматически при создании PR.

7. **Свяжите PR с issue**, если он его закрывает:
 ```
   Closes #42
   Fixes #17
   ```

8. **Будьте готовы к review** — мейнтейнер может попросить доработки.

---

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
- Тестовые операторы (`{% raw %}`) — для Go-templates в shell командах

### Python (патч-скрипты в `templates/`)

- Python 3.11+ (патчи работают в upstream-образах с Python 3.13)
- Без сторонних зависимостей (используйте `hashlib`/`crypt`/`os`)
- Docstring в начале каждого скрипта

### Commit messages

См. следующий раздел.

---

## Сообщения коммитов

Используем [Conventional Commits](https://www.conventionalcommits.org/) (упрощённый):

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

**Types:**
- `feat` — новая функциональность
- `fix` — исправление бага
- `docs` — только документация
- `style` — форматирование, без изменения логики
- `refactor` — рефакторинг кода
- `test` — добавление тестов
- `ci` — изменения в CI/CD
- `chore` — прочие изменения (deps, build и т.п.)

**Scope (опционально):**
- `preflight` — `tasks/preflight.yml`
- `dependencies` — `tasks/dependencies.yml`
- `macvlan` — `tasks/macvlan.yml`
- `nat` — `tasks/nat.yml`
- `compose` — `tasks/compose.yml` или `templates/compose.yml.j2`
- `webroot` — `tasks/webroot.yml`
- `images` — `tasks/images.yml`
- `volumes` — `tasks/volumes.yml`
- `stack` — `tasks/stack.yml`
- `systemd` — `tasks/systemd.yml`
- `playbook` — `playbooks/*.yml`
- `playbooks` — `ansible.cfg`, `requirements.yml`

**Примеры:**

```
fix(preflight): remove invalid Jinja delimiters in assert condition
feat(compose): add support for custom DHCP lease time
docs: add FAQ section to README
ci: split monolithic test.yml into focused workflows
```

**Subject:**
- Не более 72 символов
- Строчные буквы
- Без точки в конце
- Повелительное наклонение ("add", не "added")

**Body:**
- Объясните *что* и *почему*, а не *как* (как видно из diff)
- Ссылайтесь на issue/обсуждение, если есть

**Footer:**
- `Closes #N`, `Fixes #N` — для закрытия issue
- `BREAKING CHANGE: <описание>` — для breaking changes

---

## Локальное тестирование

### 1. Установить pre-commit (опционально)

```bash
pip install pre-commit
pre-commit install
```

После этого при каждом коммите автоматически запустятся `yamllint`
и проверка формата сообщений.

### 2. Запустить тесты локально

```bash
# Линтер
yamllint .
ansible-lint roles/cobbler/ playbooks/

# Syntax-check
ansible-galaxy collection install community.docker --no-cache-dir
ansible-playbook playbooks/site.yml -i inventories/staging/hosts.yml --syntax-check
ansible-playbook playbooks/deploy.yml -i inventories/staging/hosts.yml --syntax-check
ansible-playbook playbooks/rebuild.yml -i inventories/staging/hosts.yml --syntax-check
ansible-playbook playbooks/uninstall.yml -i inventories/staging/hosts.yml --syntax-check
```

### 3. Полная установка в Docker (опционально, продвинутый)

Для тестирования полной установки можно использовать `docker-in-docker` или
выделенную виртуальную машину. **Не запускайте** на production-хосте.

---

## Контакты

Вопросы? Откройте [Discussion](../../discussions) или Issue.

---

Спасибо за ваш вклад! 🙏
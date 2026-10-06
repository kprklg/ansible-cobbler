# Шаблон RU-секции для GitHub Releases

Этот файл используется workflow `.github/workflows/release.yml` для
автоматической генерации двуязычных релизов (🇬🇧 EN + 🇷🇺 RU).

EN-секция берётся из CHANGELOG.md, RU — из этого файла.

## Перед каждым релизом

1. Добавьте секцию в `CHANGELOG.md` (на английском)
2. **Обновите секцию ниже** — вручную переведите ключевые пункты на русский
3. Закоммитьте оба файла, создайте тег, запушьте

---

## Что нового в v1.1.1

### Исправлено

- **`patch-remote.py` — Web UI ошибка:** `internal error, collection name "file"/"package" not supported`
  После v1.1.0 страница manage/dashboard вызывала code-path'ы в `remote.py` (find, get_item_resolved_value, extended lookup), которые обходили патч v1.1.0. В v1.1.1 **все** вызовы `self.api.get_items(...)` идут через обёртку `self._safe_get_items(...)`, а сам патч стал идемпотентным (повторный запуск сначала откатывает старые изменения, потом применяет текущие).

- **`patch-remote.py` — `TypeError: takes 2 positional arguments but 3 were given`**
  `get_items` и `get_item_names` теперь принимают `(*args, **kwargs)` и извлекают `what` из последнего позиционного аргумента. Благодаря этому форма вызова cobbler-web `get_item_names(token, what)` больше не падает.

- **`patch-remote.py` — `IndentationError` при повторном применении**
  Скрипт стал идемпотентным: при наличии маркера `__kprklg_patched__` он сначала откатывает все предыдущие изменения, затем применяет текущую версию. Сломанный образ можно починить простым перезапуском роли.

### Добавлено

- **Molecule регрессионный тест** в `molecule/default/verify.yml` — запускается на собранном образе `cobbler/cobblerd-patched` и падает, если любое из legacy-имён коллекций снова начнёт вызывать ошибку.

### Проверено

```text
cobbler_api get_items('file')     -> 15+ встроенных шаблонов
cobbler_api get_items('package')  -> []  (legacy коллекция удалена)
cobbler_api get_items('mgmtclass') -> []  (legacy коллекция удалена)
cobbler_api get_distros(token)     -> []  (дистрибутивов нет, это OK)
Web UI страница manage             -> ошибки нет
```

---

## Шаблон для следующих релизов

Скопируйте и адаптируйте:

```markdown
### Исправлено
- **патч-remote.py** — <краткое описание>

### Добавлено
- **новая фича** — <краткое описание>

### Изменено
- **что-то** — <краткое описание>

### Проверено
```text
<вывод cobbler_api>
```
```
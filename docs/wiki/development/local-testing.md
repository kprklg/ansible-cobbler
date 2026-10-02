# Локальное тестирование

Это руководство для контрибьюторов, которые хотят проверить свои изменения
перед созданием PR.

## 1. Подготовка окружения

```bash
# Клонировать форк
git clone https://github.com/<your-username>/ansible-cobbler.git
cd ansible-cobbler

# Установить инструменты
make install-deps
make collections
pip install pre-commit
pre-commit install
```

## 2. Запуск тестов

### Все тесты одной командой

```bash
make test
```

Это эквивалентно:

```bash
make lint         # yamllint + ansible-lint
make syntax-check # ansible-playbook --syntax-check для всех плейбуков
make molecule     # Molecule-тесты в Docker
```

### По отдельности

```bash
# Только yamllint
make yamllint

# Только ansible-lint
make ansible-lint

# Только syntax-check
make syntax-check

# Только Molecule
make molecule
```

## 3. Pre-commit хуки

После `pre-commit install` при каждом коммите автоматически:

- Запускается yamllint на изменённых файлах
- Запускается ansible-lint на изменённых файлах
- Проверяется формат Conventional Commits
- Проверяется отсутствие trailing whitespace
- Проверяется EOF (newline at end of file)

Чтобы запустить на всех файлах:

```bash
make pre-commit
```

## 4. Проверка на реальном Debian-хосте

### Быстрая проверка через Docker

```bash
make docker-build-test
make docker-run-test
# внутри контейнера:
make lint
make syntax-check
```

### Полная установка в изолированной VM

!!! warning "Не запускайте на production-хосте"
    Создайте отдельную VM/VPS с 2-мя сетевыми интерфейсами:

    - eth0 — пустой (PXE)
    - eth1 — с интернетом

```bash
# На VM
vagrant ssh
cd /vagrant/ansible-cobbler
make install    # полная установка (~25 мин на RPi)
```

### Установка в Docker-in-Docker (продвинутый)

```bash
docker run --rm -it \
  --privileged \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):/workspace \
  -w /workspace \
  ansible-cobbler:test \
  bash
```

Это позволяет запустить установку Cobbler внутри контейнера.

## 5. Запуск конкретного тега

```bash
# Только сеть (macvlan + NAT)
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml \
  --tags network

# Только сборка образов
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml \
  --tags images

# Только docker compose up
ansible-playbook -i inventory/myhost/hosts.yml playbooks/site.yml \
  --tags stack
```

## 6. Чек-лист перед PR

- [ ] `make lint` проходит без ошибок
- [ ] `make syntax-check` проходит
- [ ] `make molecule` проходит (если меняли tasks/templates)
- [ ] `make pre-commit` проходит
- [ ] Если меняли поведение — обновлён README
- [ ] Если добавляли переменную — обновлён `defaults/main.yml` + документация
- [ ] Если фиксите баг — добавлена запись в CHANGELOG
- [ ] Commit message в формате Conventional Commits

## См. также

- [Molecule](molecule.md) — детали Molecule-сценариев
- [Commits](commits.md) — формат сообщений
- [CI/CD](ci-cd.md) — что проверяется в GitHub Actions
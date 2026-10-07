# Changelog / История изменений

All notable changes to this project are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> 🇬🇧 **English below** — see [English version](#-english)
> 🇷🇺 **Русский ниже** — см. [Русская версия](#-русский)

> ℹ Разделы для версий **v1.1.0 / v1.1.1** переведены только на английский
> (translation TBD). Полностью двуязычно оформлен только **v1.1.2**.

---

<a id="-english"></a>

# 🇬🇧 English

## [v1.1.2] — 2026-10-07

> ⚠ **This release includes [v1.1.1](#v111--2026-10-05) (i.e. it's based on v1.1.1, not v1.1.0).**
> When upgrading from v1.1.0 → v1.1.2 in one step, the playbook is idempotent —
> a re-run won't break your current installation.

### 🚀 Highlights

- **Traefik finally binds `0.0.0.0:80`** — what the v1.1.0 changelog promised
  but the code never implemented. Without this fix the playbook **always** failed
  on the health-check timeout (3 minutes after `docker compose up -d`).
- **macvlan auto-up without a patch cord** — installation previously required
  a physically plugged-in Ethernet cable. Now systemd-networkd brings up the
  parent interface via `ConfigureWithoutCarrier=yes`.
- **`filter_plugins/ipaddr.py` in the repo** — without it, the role's templates
  don't render on ansible-core 2.19+ (a bug CI didn't catch, because CI only
  does `--syntax-check` without Jinja rendering).
- **CLI `cobbler` in the patched image** — previously `docker exec ... cobbler import`
  returned `executable file not found`, because the upstream `cobblerd` image
  ships only the daemon.
- **Full docs overhaul**: README with prominent «Quick Start» (git clone as
  step 0), PREREQUISITES with the correct order (clone → apt → docker →
  ansible-galaxy), v1.1.2 release notes here.

### Fixed

#### `fix(stack)` — Traefik bind `0.0.0.0:80` and health-check URL

Changelog v1.1.0 promised this fix, but the code still had `{{ cobbler_mgmt_ip }}`.
The health-check at `http://127.0.0.1/` always failed with `Connection refused`
after a 3-minute timeout. Now:
- `ports: 0.0.0.0:80:80` (instead of `{{ cobbler_mgmt_ip }}:80:80`)
- health-check in `tasks/stack.yml` goes to `http://{{ cobbler_mgmt_ip }}/`
- health-check in `templates/cobbler-recover.sh.j2` uses `MGMT_IP`

**Files affected:** `roles/cobbler/templates/compose.yml.j2`,
`roles/cobbler/templates/cobbler-recover.sh.j2`, `roles/cobbler/tasks/stack.yml`.

#### `fix(macvlan)` — `ConfigureWithoutCarrier=yes` for parent interface

Without a patch cord, systemd-networkd didn't bring up the parent interface
(e.g. `ens19`), and Docker couldn't create the macvlan → playbook failed with
`failed to enable ens19.10 the macvlan parent link network is down`.
Now the PXE interface comes up even without a link.

**Files affected:** `roles/cobbler/tasks/macvlan.yml`.

#### `fix(images)` — `docker pull` upstream images before stack start

`docker compose up -d` failed with `No such image: traefik:v3.6` because the
compose file has `pull: never`. Added a task in `tasks/images.yml` that explicitly
pulls `traefik`, `cobbler-tftp`, `cobbler-dhcp`.

**Files affected:** `roles/cobbler/tasks/images.yml`.

#### `fix(systemd)` — `systemd, autostart` tags on inner-tasks

`include_tasks` doesn't propagate tags to child tasks, and the tasks in
`systemd.yml` had no tags. `ansible-playbook --tags systemd` did nothing.
Now each task is explicitly tagged.

**Files affected:** `roles/cobbler/tasks/systemd.yml`.

#### `fix(compose)` — `external: true` for volumes + long-form syntax

Docker 29 complained with two warnings:
- `volume ... already exists but was not created by Docker Compose`
  (volumes are created manually in `tasks/volumes.yml`, but weren't marked
  as `external: true` in compose)
- `mount of type volume should not define bind option` (short-form
  `name:path:z` for volume mounts gets expanded by Docker 29 to
  `bind: { selinux: z }`, which is invalid for volume-typed mounts)

Now volumes are marked `external: true` and written in long-form
(`type: volume` / `type: bind`).

**Files affected:** `roles/cobbler/templates/compose.yml.j2`.

#### `fix(dockerfile)` — CLI wrapper `cobbler` in the patched image

Upstream `ghcr.io/cobbler/cobblerd` ships only the `cobblerd` daemon, without
a CLI. The README suggested `docker exec ... cobbler import ...`, but the
command wasn't found. Added a wrapper at `/usr/local/bin/cobbler`
(`python3 -m cobbler.cli`).

**Files affected:** `roles/cobbler/templates/Dockerfile.cobbler.j2`.

#### `fix(filter)` — `filter_plugins/ipaddr.py` (wrapper for `ansible.utils.ipaddr`)

In ansible-core 2.19+, declaring `collections: [ansible.utils]` in a playbook
**does not** make the short name `ipaddr` available in Jinja templates. The
v1.1.0 changelog wrote "wired filter_plugins folder" but forgot to actually
create the folder. In v1.1.2 the folder is created and contains a re-export
of `ansible.utils.ipaddr`.

**Files affected:** `filter_plugins/ipaddr.py` (new), `.gitignore`.

#### `fix(cobbler-recover)` — health-check URL via `MGMT_IP`

In `templates/cobbler-recover.sh.j2` the health-check also looked at
`http://127.0.0.1/` (which doesn't work with traefik on `0.0.0.0:80` if
the host listens only on the management IP). Now it uses `cobbler_mgmt_ip`
from the inventory.

**Files affected:** `roles/cobbler/templates/cobbler-recover.sh.j2`.

### Changed

- **README.md** — added the «🚀 Quick Start (TL;DR)» section with `git clone`
  as **step 0**. Explicit note: the role must be cloned on the **target
  machine**, not on a separate controller (`ansible_connection: local` is used).
- **PREREQUISITES.md** — in the «Minimal copy-paste», `git clone` is moved
  to the first place (previously it came after the apt install, which is
  logically incorrect — you can't `ansible-galaxy collection install -r
  requirements.yml` without first cloning).
- **`.gitignore`** — removed `filter_plugins/` (there's a live file there now).
- **meta/main.yml** — added `version: "1.1.2"`.

### Migration notes

When upgrading from v1.1.0 or v1.1.1:

```bash
cd ~/ansible-cobbler
git fetch
git checkout v1.1.2
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

The playbook is idempotent. None of our fixes will break a current installation
(in particular, moving `ports` from `{{ cobbler_mgmt_ip }}:80` to `0.0.0.0:80`
makes traefik reachable on all interfaces — if you had a firewall allowing only
the management IP, double-check your rules).

### Contributors

- MiniMax-M3 (rasp01 team) — maintainer
- goose — v1.1.2 (runtime fixes + docs overhaul)

---

## [v1.1.1] — 2026-10-05

### Fixed

- **`patch-remote.py` — legacy collection names in Cobbler 4.** ([details](https://github.com/kprklg/ansible-cobbler/compare/v1.1.0...v1.1.1))

## [v1.1.0] — 2026-10-02

### Fixed

- aarch64 / Ansible 2.19 / Cobbler 4 compatibility (see [release notes](https://github.com/kprklg/ansible-cobbler/releases/tag/v1.1.0))

## [v1.0.0] — initial release

- Initial version (x86_64 only)

---

<a id="-русский"></a>

# 🇷🇺 Русский

## [v1.1.2] — 2026-10-07

> ⚠ **Этот релиз включает в себя [v1.1.1](#v111--2026-10-05) (т.е. базируется на v1.1.1, а не на v1.1.0).**
> При обновлении с v1.1.0 → v1.1.2 в один шаг, плейбук идемпотентен — повторный
> запуск не сломает текущую установку.

### 🚀 Главное

- **Traefik наконец-то bind `0.0.0.0:80`** — то, что обещал changelog v1.1.0,
  но в коде так и не было реализовано. Без этого фикса плейбук **всегда** падал
  по таймауту на health-check (через 3 минуты после `docker compose up -d`).
- **macvlan auto-up без патч-корда** — раньше установка требовала физически
  воткнутого Ethernet-кабеля. Теперь systemd-networkd поднимает parent-интерфейс
  сам через `ConfigureWithoutCarrier=yes`.
- **`filter_plugins/ipaddr.py` в репо** — без него шаблоны роли не рендерились
  на ansible-core 2.19+ (баг, который CI не ловил, потому что делал только
  `--syntax-check` без рендера Jinja).
- **CLI `cobbler` в patched-образе** — раньше `docker exec ... cobbler import`
  возвращал `executable file not found`, потому что upstream-образ `cobblerd`
  поставляет только демон.
- **Полная переработка доки**: README с prominent «Быстрый старт» (git clone
  как шаг 0), PREREQUISITES с правильным порядком (clone → apt → docker →
  ansible-galaxy), release notes v1.1.2 здесь.

### Fixed (Исправлено)

#### `fix(stack)` — Traefik bind `0.0.0.0:80` и URL health-check

Changelog v1.1.0 обещал этот фикс, но в коде остался `{{ cobbler_mgmt_ip }}`.
Health-check по `http://127.0.0.1/` всегда падал с `Connection refused` через
3 минуты таймаута. Теперь:
- `ports: 0.0.0.0:80:80` (а не `{{ cobbler_mgmt_ip }}:80:80`)
- health-check в `tasks/stack.yml` ходит на `http://{{ cobbler_mgmt_ip }}/`
- health-check в `templates/cobbler-recover.sh.j2` использует `MGMT_IP`

**Затронутые файлы:** `roles/cobbler/templates/compose.yml.j2`,
`roles/cobbler/templates/cobbler-recover.sh.j2`, `roles/cobbler/tasks/stack.yml`.

#### `fix(macvlan)` — `ConfigureWithoutCarrier=yes` для parent-интерфейса

Без патч-корда systemd-networkd не поднимал родительский интерфейс
(например, `ens19`), и Docker не мог создать macvlan → плейбук падал на
`failed to enable ens19.10 the macvlan parent link network is down`.
Теперь PXE-интерфейс поднимается даже без линка.

**Затронутые файлы:** `roles/cobbler/tasks/macvlan.yml`.

#### `fix(images)` — `docker pull` upstream-образов перед запуском стека

`docker compose up -d` падал с `No such image: traefik:v3.6`, потому что в
compose стоит `pull: never`. Добавлена задача в `tasks/images.yml`, которая
явно подтягивает `traefik`, `cobbler-tftp`, `cobbler-dhcp`.

**Затронутые файлы:** `roles/cobbler/tasks/images.yml`.

#### `fix(systemd)` — теги `systemd, autostart` на inner-tasks

`include_tasks` не пробрасывает теги на дочерние tasks, а у самих задач в
`systemd.yml` тегов не было. `ansible-playbook --tags systemd` ничего не
делал. Теперь каждая задача помечена явно.

**Затронутые файлы:** `roles/cobbler/tasks/systemd.yml`.

#### `fix(compose)` — `external: true` для volumes + long-form синтаксис

Docker 29 ругался двумя warning'ами:
- `volume ... already exists but was not created by Docker Compose`
  (volumes создаются вручную в `tasks/volumes.yml`, но в compose не были
  помечены `external: true`)
- `mount of type volume should not define bind option` (short-form
  `name:path:z` для volume-монта Docker 29 раскрывает в
  `bind: { selinux: z }`, что невалидно для volume-типа)

Теперь volumes помечены `external: true` и записаны в long-form
(`type: volume` / `type: bind`).

**Затронутые файлы:** `roles/cobbler/templates/compose.yml.j2`.

#### `fix(dockerfile)` — CLI-обёртка `cobbler` в patched-образе

Upstream `ghcr.io/cobbler/cobblerd` поставляет только демон `cobblerd`,
без CLI. README советует `docker exec ... cobbler import ...`, но команда
не находилась. Добавлен wrapper `/usr/local/bin/cobbler`
(`python3 -m cobbler.cli`).

**Затронутые файлы:** `roles/cobbler/templates/Dockerfile.cobbler.j2`.

#### `fix(filter)` — `filter_plugins/ipaddr.py` (обёртка `ansible.utils.ipaddr`)

В ansible-core 2.19+ объявление `collections: [ansible.utils]` в плейбуке
**не** делает короткое имя `ipaddr` доступным в шаблонах Jinja. Changelog
v1.1.0 писал «подключена папка filter_plugins», но саму папку забыли
создать. В v1.1.2 она создана и содержит реэкспорт `ansible.utils.ipaddr`.

**Затронутые файлы:** `filter_plugins/ipaddr.py` (новый), `.gitignore`.

#### `fix(cobbler-recover)` — health-check URL через `MGMT_IP`

В `templates/cobbler-recover.sh.j2` health-check тоже смотрел
`http://127.0.0.1/` (что не работает с traefik на `0.0.0.0:80`, если хост
слушает только на management IP). Теперь использует `cobbler_mgmt_ip` из
инвентаря.

**Затронутые файлы:** `roles/cobbler/templates/cobbler-recover.sh.j2`.

### Changed (Изменено)

- **README.md** — добавлена секция «🚀 Быстрый старт (TL;DR)» с `git clone`
  как **шагом 0**. Явное указание: клонировать роль нужно **на целевую
  машину**, а не на отдельный controller (используется `ansible_connection: local`).
- **PREREQUISITES.md** — в «Минимальной копипасте» `git clone` переставлен
  на первое место (раньше был после установки apt, что логически
  некорректно — `ansible-galaxy collection install -r requirements.yml`
  невозможен без клонирования).
- **`.gitignore`** — убран `filter_plugins/` (там теперь живой файл).
- **meta/main.yml** — добавлено `version: "1.1.2"`.

### Migration notes (Заметки по миграции)

При обновлении с v1.1.0 или v1.1.1:

```bash
cd ~/ansible-cobbler
git fetch
git checkout v1.1.2
ansible-playbook -i inventories/myhost/hosts.yml playbooks/site.yml
```

Плейбук идемпотентен. Все наши фиксы не ломают текущую установку
(в частности, перенос `ports` с `{{ cobbler_mgmt_ip }}:80` на `0.0.0.0:80`
сделает traefik доступным на всех интерфейсах — если у вас был файрвол
только на mgmt IP, проверьте правила).

### Contributors (Участники)

- MiniMax-M3 (rasp01 team) — maintainer
- goose — v1.1.2 (runtime-фиксы + docs overhaul)

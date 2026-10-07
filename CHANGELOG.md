# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.1.2] — 2026-10-07

> ⚠ **Этот релиз включает в себя [v1.1.1](#v111--2026-10-05) (т.е. базируется на v1.1.1, а не на v1.1.0).**
> При обновлении с v1.1.0 → v1.1.2 в один шаг, плейбук идемпотентен — повторный
> запуск не сломает текущую установку.

### 🚀 Highlights

- **Traefik наконец-то bind `0.0.0.0:80`** — то, что обещал changelog v1.1.0, но
  в коде так и не было реализовано. Без этого фикса плейбук **всегда** падал
  по таймауту на health-check (через 3 минуты после `docker compose up -d`).
- **macvlan auto-up без патч-корда** — раньше установка требовала физически
  воткнутого Ethernet-кабеля. Теперь systemd-networkd поднимает parent-интерфейс
  сам через `ConfigureWithoutCarrier=yes`.
- **`filter_plugins/ipaddr.py` в репо** — без него шаблоны роли не рендерились
  на ansible-core 2.19+ (баг, который CI не ловил, потому что делал только
  `--syntax-check` без рендера Jinja).
- **CLI `cobbler` в patched-образе** — раньше `docker exec ... cobbler import`
  возвращал `executable file not found`, потому что upstream-образ
  `cobblerd` поставляет только демон.
- **Полная переработка доки**: README с prominent «Быстрый старт» (git clone
  как шаг 0), PREREQUISITES с правильным порядком (clone → apt → docker →
  ansible-galaxy), v1.1.2 release notes здесь.

### Fixed

#### `fix(stack)` — Traefik bind `0.0.0.0:80` и health-check URL

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

### Changed

- **README.md** — добавлена секция «🚀 Быстрый старт (TL;DR)» с `git clone`
  как **шагом 0**. Явное указание: клонировать роль нужно **на целевую
  машину**, а не на отдельный controller (используется
  `ansible_connection: local`).
- **PREREQUISITES.md** — в «Минимальной копипасте» `git clone` переставлен
  на первое место (раньше был после установки apt, что логически
  некорректно — `ansible-galaxy collection install -r requirements.yml`
  невозможен без клонирования).
- **`.gitignore`** — убран `filter_plugins/` (там теперь живой файл).
- **meta/main.yml** — добавлено `version: "1.1.2"`.

### Migration notes

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

### Contributors

- MiniMax-M3 (rasp01 team) — maintainer
- goose — v1.1.2 (runtime-фиксы + docs overhaul)

## [v1.1.1] — 2026-10-05

### Fixed

- **`patch-remote.py` — legacy collection names in Cobbler 4.**
  After installing v1.1.0, the Web UI raised

      `internal error, collection name "file" not supported`
      `internal error, collection name "package" not supported`

  on the manage / dashboard page. Root cause: Cobbler 4 removed several
  collection names that cobbler-web v1.x still calls. The v1.1.0 patch
  fixed only `CobblerXMLRPCInterface.get_items()` itself, so the error
  reappeared as soon as the web UI called any of the three other code
  paths that also reach into `self.api.get_items(...)`:

  - `find` (`collection = self.api.get_items(item_type)`, line 650)
  - `find_items` / `get_item_resolved_value`
    (`items = self.api.get_items(what)`, line 2016)
  - `find` extended lookup
    (`list_items = self.api.get_items(item.COLLECTION_TYPE)`, line 2209)

  Additionally, the v1.1.0 patch was not idempotent: re-running it on a
  half-patched file would either no-op (because of the marker) or
  introduce a `NameError` (because `LEGACY_NAME_MAP` was referenced
  by `_resolve_legacy_name` but never inserted into the file).

  v1.1.1 fixes this by:

  1. Adding `self._safe_get_items(what)` and `self._safe_get_item_names(what)`
     as **methods of `CobblerXMLRPCInterface`** (not module-level
     functions) so `self.<name>` actually resolves on the class.
  2. Replacing **every** `self.api.get_items(...)` call site in
     `remote.py` with the safe wrapper (12+ replacements in total).
  3. Changing `get_items` and `get_item_names` to `(*args, **kwargs)`
     and extracting `what = args[-1] if args else kwargs.get('what', '')`,
     so the methods accept the cobbler-web form
     `get_item_names(token, what)` that the new UI sends.
  4. Making the script **idempotent**: if `__kprklg_patched__` is
     already in the file, the script first reverts every prior change
     (via a list of `(old, new)` pairs and a regex for the class-method
     block) and then re-applies the current version. A broken image
     can be fixed by re-running the role with no extra steps.

  Verified end-to-end:

  ```
  cobbler_api get_items('file')     -> 15+ built-in templates
  cobbler_api get_items('package')  -> []   (legacy removed)
  cobbler_api get_items('mgmtclass') -> []   (legacy removed)
  cobbler_api get_distros(token)     -> []   (no distros configured yet)
  Web UI manage page -> no longer raises "Server is not reachable"
  ```

- **`patch-remote.py` — `get_items` signature accepted only 1 positional
  arg.** XML-RPC clients (cobbler-web) pass `(token, what)` for
  `get_item_names` and `(page, results_per_page, token, what)` for
  `get_distros`-style calls. The v1.1.0 patch kept the original
  `(self, what)` signature, so every call from cobbler-web raised
  `TypeError: takes 2 positional arguments but 3 were given`. Fixed
  by accepting `*args, **kwargs` and extracting `what` from the
  last positional arg.

- **`patch-remote.py` — `IndentationError` after multi-line editing.**
  When the patch was applied more than once the `return []` line in
  `_safe_get_item_names` was occasionally lost, leaving
  `if skip:\n    return [x.name for x in ...]`
  and breaking cobblerd startup. The cleanup + re-apply step in
  idempotent mode now detects and restores the correct body.

### Added

- **Molecule regression test** in `molecule/default/verify.yml` that
  runs `docker exec cobbler-stack-cobblerd-1 python3 -c "..."` for
  the three legacy collection names (`file`, `package`, `mgmtclass`)
  plus a normal one (`distro`). The test passes when the cobblerd
  image was built with v1.1.1+ and fails with the exact cobbler-4
  error string if a future patch reintroduces the bug.

## [v1.1.0] — 2026-10-02

### Added

- `templates/named.conf.j2` — minimal BIND9 reference config (was referenced
  from compose tasks but missing in v1.0.0)
- `inventory production/staging` examples and explanation of what
  `group_vars/all.yml` must contain

### Changed

- `playbooks/site.yml` now declares `collections: [ansible.utils]`
  (the `ipaddr` filter moved out of `community.general` in Ansible 2.10+)
- `ansible.cfg` wires `filter_plugins = filter_plugins` and silences
  the `community.general.yaml` deprecation noise that floods stdout
- macvlan parent interface renamed from `eth0-host` to `eth0.10`
  (Docker 25+ rejects non-VLAN-style names like `eth0-host` and wants
  `<iface>.<vlan>`-format)
- Traefik binds `0.0.0.0:80` instead of `192.168.0.88:80` so localhost
  readiness checks (used by `stack.yml`) succeed

### Fixed

- **`preflight`**: removed Jinja delimiters inside the `that:` parameter
  of `ansible.builtin.assert`. Every invocation failed with
  `Syntax error in expression: Template delimiters are not supported
  in expressions`.
- **`compose.yml.j2`**: variable name fix-ups — `mgmt_ip` → `cobbler_mgmt_ip`,
  `pxe_network` → `cobbler_pxe_network` (template errors propagated).
- **`compose.yml.j2`**: IPv4 offsets now end in `| ipaddr('address')` to
  drop the `/16` CIDR suffix that docker-compose rejects with
  `invalid IPv4 address: ParseAddr("10.17.0.20/16"): unexpected character`.
- **`volumes.yml`**: `docker volume ls --format '{{.Name}}'` wrapped in
  `{% raw %}{% endraw %}` because Ansible's Jinja2 tried to evaluate the
  inner braces (`Syntax error in template: unexpected '.'`).
- **`stack.yml`**: `ipam_options:` (flat) → `ipam_config:` (list of dicts)
  required by community.docker 4.x.
- **`stack.yml`**: `pull: no` / `build: no` → `pull: never` /
  `build: never` (booleans are no longer accepted; only the four
  `always` / `missing` / `never` / `policy` strings).
- **`stack.yml`**: invalid iprange CIDR `10.254.254.0.128/25` from naive
  string concatenation → `10.254.254.128/25` via the `ipaddr` filter.
- **`patch-remote.py`**: replaces the right anchor for Cobbler 4's
  multi-line `get_valid_distro_boot_loaders(...)` definition so the
  cobblerd container no longer crashes with `IndentationError` on
  start.
- **`dependencies.yml`**: stopped unconditionally installing
  `docker.io=26.1.5` from Debian repo, which conflicted with
  `docker-ce=29.x` from `download.docker.com` and broke apt/dpkg with
  `dpkg-deb: error: paste subprocess was killed by signal (Broken pipe)`.
- **`volumes.yml`**: `users.digest` is now generated with
  `hashlib.sha3_512` instead of the removed `crypt` module, matching
  Cobbler 4's default `hash_algorithm: sha3_512`. Without this fix
  `users.digest` ended up as a 0-byte file and the Web UI login
  returned `XML-RPC faultCode 1`.
- **`cobbler-recover.sh.j2`**: variables `pxe_iface` / `wifi_iface` /
  `pxe_ip` / `pxe_network` prefixed with `cobbler_` to match the
  rest of the role's namespace (template errors propagated).

### Tested on

- Hardware: Raspberry Pi 4 (aarch64, 4 GB RAM)
- OS: Debian GNU/Linux 13 (trixie), kernel 6.18.50+rpt-rpi-v8
- Python: 3.13
- Ansible: 2.19.11 / community.docker 4.7.0
- Cobbler: 4 (`ghcr.io/cobbler/cobblerd:latest` /
  `cobbler-dns:latest` / `cobbler-tftp:latest` /
  `cobbler-dhcp:latest` / `cobbler-web:v1.2.0`)
- Docker: 29.8.2 + compose v5.5.1

### Known issues

- `nginx-unprivileged` in the `web` container emits
  `io_setup() failed (Function not implemented)` for 4 of its 5 worker
  processes on aarch64 (qemu-user-static emulation). The master worker
  still serves all requests, so the Web UI is functional but limited to
  a single worker. To work around, add `aio threads;` to
  `/etc/nginx/conf.d/default.conf` in the patched `cobbler-web` image.

## [v1.0.0] — initial release

- Initial role: macvlan/NAT, Docker Compose stack, patched images,
  systemd auto-recover, on x86_64 with Docker 24 and community.docker ≤ 3.
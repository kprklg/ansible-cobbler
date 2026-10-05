# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
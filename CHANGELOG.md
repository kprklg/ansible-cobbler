# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
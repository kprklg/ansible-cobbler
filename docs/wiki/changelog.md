# Changelog

Полная история изменений — в [`CHANGELOG.md`](https://github.com/kprklg/ansible-cobbler/blob/main/CHANGELOG.md)
на GitHub.

## Краткая история

### v1.1.0 — 2026-10-02

14 исправлений для работы на Raspberry Pi (aarch64) с Ansible 2.19 и Cobbler 4:

- `fix(preflight)`: Jinja-разделители в условии assert
- `fix(macvlan)`: eth0-host → eth0.10 (требование Docker VLAN)
- `fix(stack)`: ipam_config, pull/build=never, iprange CIDR
- `fix(stack)`: Traefik bind 0.0.0.0:80
- `fix(compose)`: добавил named.conf.j2
- `fix(compose)`: переменные → cobbler_* префикс, | ipaddr('address')
- `fix(volumes)`: {% raw %} для Go-template
- `fix(patch-remote)`: многострочная сигнатура в Cobbler 4
- `fix(deps)`: больше не устанавливает docker.io поверх docker-ce
- `fix(volumes)`: SHA3-512 для users.digest (Cobbler 4 default)
- `fix(cobbler-recover)`: префикс cobbler_
- `chore(playbook)`: ansible.utils collection
- `chore(ansible.cfg)`: filter_plugins + deprecation_warnings=False

### v1.0.0 — initial release

Начальная версия. Работала только на x86_64 с Docker 24 и старым community.docker.

## См. также

- [Релизы на GitHub](https://github.com/kprklg/ansible-cobbler/releases)
- [Полный CHANGELOG](https://github.com/kprklg/ansible-cobbler/blob/main/CHANGELOG.md)
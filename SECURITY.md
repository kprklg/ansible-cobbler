# Security Policy / Политика безопасности

> 🇬🇧 **English below** — see [English version](#english-version)
> 🇷🇺 **Русский ниже** — см. [Русская версия](#русская-версия)

---

<a id="english-version"></a>

# 🇬🇧 English

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| v1.1.x  | ✅ actively         |
| v1.0.x  | ❌ deprecated       |

## Reporting a Vulnerability

If you find a vulnerability in this Ansible role or in the Docker
images it builds, please **do not file a public issue** — that may
expose users to risk.

Send a description privately through one of the channels below.

### Channels

- GitHub Security Advisories: https://github.com/kprklg/ansible-cobbler/security/advisories/new
- Email: see the author's GitHub profile

### What to include

- Description of the vulnerability
- Steps to reproduce
- Role version (`git rev-parse HEAD`)
- Cobbler version (`docker inspect cobbler/ghcr.io/cobbler/cobblerd:latest`)
- Ansible version (`ansible --version`)
- Possible impact (what an attacker could do)

### What to expect

- Acknowledgement within **3 business days**
- Severity assessment within **7 business days**
- Patch within **30 days** (sooner for critical issues)
- Coordinated disclosure date by mutual agreement

## Security posture of this role

### What the role does

- ✅ Creates a hashed password in `users.digest` (SHA3-512 — Cobbler 4 default)
- ✅ Uses `iptables` MASQUERADE (no external access to PXE subnet)
- ✅ Uses `no-new-privileges` + `label:disable` for traefik
- ✅ Mounts `/var/run/docker.sock` **only in traefik** (read-only)

### What you must verify yourself

- ⚠️ Change the default password (`cobbler` / `cobbler`) before production
- ⚠️ Lock down the Traefik dashboard (`127.0.0.1:8082`) if not needed
- ⚠️ Don't expose macvlan `eth0.10` to the internet without firewall rules
- ⚠️ HTTPS is not implemented — add a reverse-proxy with Let's Encrypt

### Known CVEs in dependencies

| Package | CVE | Effect on this role |
|---|---|---|
| — | — | No known critical vulnerabilities |

Track updates:
- https://github.com/cobbler/cobbler/releases
- https://hub.docker.com/_/traefik
- https://github.com/docker/compose/releases

---

<a id="русская-версия"></a>

# 🇷🇺 Русский

## Поддерживаемые версии

| Версия | Поддержка |
|---|---|
| v1.1.x | ✅ активно |
| v1.0.x | ❌ устаревшая |

## Сообщить об уязвимости

Если вы нашли уязвимость в этой Ansible-роли или в собираемых ею
Docker-образах, **не создавайте публичный issue** — это может
подвергнуть пользователей риску.

Отправьте описание в **приватном порядке** через один из каналов ниже.

### Каналы

- GitHub Security Advisories: https://github.com/kprklg/ansible-cobbler/security/advisories/new
- Email: см. профиль автора на GitHub

### Что включить

- Описание уязвимости
- Шаги для воспроизведения
- Версия роли (`git rev-parse HEAD`)
- Версия Cobbler (`docker inspect cobbler/ghcr.io/cobbler/cobblerd:latest`)
- Версия Ansible (`ansible --version`)
- Возможные последствия (что атакующий может сделать)

### Чего ожидать

- Подтверждение получения в течение **3 рабочих дней**
- Оценка серьёзности в течение **7 рабочих дней**
- Патч в течение **30 дней** (для критических — быстрее)
- Координация раскрытия (disclosure date) по договорённости

## Безопасность роли

### Что делает роль

- ✅ Создаёт пароль через SHA3-512 (Cobbler 4 default)
- ✅ Использует `iptables` для NAT (без внешнего доступа к PXE)
- ✅ `no-new-privileges` + `label:disable` для traefik
- ✅ Монтирует `/var/run/docker.sock` **только в traefik** (read-only)

### Что нужно проверить самостоятельно

- ⚠️ Смените дефолтный пароль (`cobbler/cobbler`) перед production
- ⚠️ Закройте Traefik dashboard (`127.0.0.1:8082`) если не нужен
- ⚠️ Не выставляйте macvlan `eth0.10` в интернет без firewall
- ⚠️ HTTPS не реализован — добавьте reverse-proxy с Let's Encrypt

### Известные CVE в зависимостях

| Пакет | CVE | Влияние на роль |
|---|---|---|
| — | — | Нет известных критических уязвимостей |

Следите за обновлениями:
- https://github.com/cobbler/cobbler/releases
- https://hub.docker.com/_/traefik
- https://github.com/docker/compose/releases

---

🔐 **English:** If you found a security issue, please report it
privately through [GitHub Security Advisories](https://github.com/kprklg/ansible-cobbler/security/advisories/new).

🔐 **Русский:** Если нашли уязвимость — сообщите приватно через
[GitHub Security Advisories](https://github.com/kprklg/ansible-cobbler/security/advisories/new).
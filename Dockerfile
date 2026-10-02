# Dockerfile — финальный образ для запуска роли ansible-cobbler в CI/CD.
#
# Использование:
#   docker build -t kprklg/ansible-cobbler:latest .
#   docker run --rm -it \
#     -v /var/run/docker.sock:/var/run/docker.sock \
#     -v $(pwd)/inventories:/opt/role/inventories \
#     -e COBBLER_MGMT_IP=192.168.0.88 \
#     kprklg/ansible-cobbler:latest
#
# Или через docker-compose:
#   docker compose -f docker-compose.yml up
#
# Особенности:
#   - Включает в себя все зависимости (ansible + collections)
#   - Содержит копию роли и всех шаблонов
#   - Поддерживает entrypoint как Ansible runner
#   - Может быть опубликован в ghcr.io через CI

FROM debian:13-slim

LABEL org.opencontainers.image.title="ansible-cobbler" \
  org.opencontainers.image.description="Ansible role runner for PXE provisioning server Cobbler 4.x" \
  org.opencontainers.image.source="https://github.com/kprklg/ansible-cobbler" \
  org.opencontainers.image.url="https://github.com/kprklg/ansible-cobbler" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.vendor="rasp01 team" \
  org.opencontainers.image.authors="kprklg"

ENV DEBIAN_FRONTEND=noninteractive \
  ANSIBLE_HOME=/opt/ansible-cobbler \
  ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections \
  PYTHONUNBUFFERED=1

# Системные зависимости
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg git \
    python3 python3-pip python3-yaml python3-passlib python3-jinja2 \
    sudo \
    iptables iptables-persistent netfilter-persistent \
    qemu-user-static binfmt-support \
    systemd systemd-sysv dbus \
    && \
  rm -rf /var/lib/apt/lists/*

# Preseed для неинтерактивной установки iptables-persistent
RUN echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections && \
    echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections

# Ansible
RUN apt-get update && apt-get install -y --no-install-recommends \
    ansible-core ansible \
    && \
    rm -rf /var/lib/apt/lists/*

# Ansible collections
RUN ansible-galaxy collection install community.docker --no-cache-dir

# Копируем роль
WORKDIR ${ANSIBLE_HOME}
COPY . ${ANSIBLE_HOME}/

# entrypoint скрипт
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Неинтерактивный режим для Ansible
ENV ANSIBLE_HOST_KEY_CHECKING=False \
    ANSIBLE_RETRY_FILES_ENABLED=False \
    ANSIBLE_STDOUT_CALLBACK=yaml

# Точка входа
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Дефолтная команда — показать помощь
CMD ["help"]

# Healthcheck
HEALTHCHECK --interval=60s --timeout=10s --start-period=5s --retries=3 \
  CMD ansible --version > /dev/null || exit 1
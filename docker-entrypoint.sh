#!/usr/bin/env bash
# docker-entrypoint.sh — точка входа для ansible-cobbler образа.
#
# Использование:
#   docker run kprklg/ansible-cobbler install        # запуск установки
#   docker run kprklg/ansible-cobbler test          # запуск тестов
#   docker run kprklg/ansible-cobbler help          # помощь
#
# Переменные окружения для настройки:
#   INVENTORY           путь к инвентарю (по умолчанию inventories/local/hosts.yml)
#   PLAYBOOK            путь к плейбуку (по умолчанию playbooks/site.yml)
#   EXTRA_ARGS          дополнительные аргументы ansible-playbook
#   COBBLER_MGMT_IP     IP для Web UI (default: 192.168.0.88)
#   COBBLER_PXE_IFACE   PXE-интерфейс (default: eth0)
#   COBBLER_WIFI_IFACE  NAT-интерфейс (default: eth1)
#   COBBLER_PXE_NETWORK подсеть PXE (default: 10.254.254.0/24)
#   COBBLER_PXE_IP      IP macvlan (default: 10.254.254.1/24)
#   COBBLER_SKIP_BUILDS пропустить сборку образов (default: false)

set -euo pipefail

INVENTORY="${INVENTORY:-inventories/local/hosts.yml}"
PLAYBOOK="${PLAYBOOK:-playbooks/site.yml}"
EXTRA_ARGS="${EXTRA_ARGS:-}"

# Функция: создать inventory из env vars, если его нет
create_default_inventory() {
    local inv_dir="${ANSIBLE_HOME}/inventories/local"
    local inv_file="${inv_dir}/hosts.yml"
    local gv_file="${inv_dir}/group_vars/all.yml"

    mkdir -p "${inv_dir}/group_vars"

    cat > "${inv_file}" <<EOF
---
all:
  vars:
    ansible_python_interpreter: /usr/bin/python3
  children:
    cobbler:
      hosts:
        localhost:
          ansible_connection: local
          ansible_become: yes
EOF

    cat > "${gv_file}" <<EOF
---
# Сеть
cobbler_mgmt_ip: "${COBBLER_MGMT_IP:-192.168.0.88}"
cobbler_pxe_iface: "${COBBLER_PXE_IFACE:-eth0}"
cobbler_wifi_iface: "${COBBLER_WIFI_IFACE:-eth1}"
cobbler_pxe_network: "${COBBLER_PXE_NETWORK:-10.254.254.0/24}"
cobbler_pxe_ip: "${COBBLER_PXE_IP:-10.254.254.1/24}"

# Аутентификация
cobbler_default_user: "${COBBLER_DEFAULT_USER:-cobbler}"
cobbler_default_password: "${COBBLER_DEFAULT_PASSWORD:-cobbler}"

# Поведение
cobbler_skip_builds: ${COBBLER_SKIP_BUILDS:-false}
EOF

    echo "✓ Default inventory created at ${inv_file}"
}

# Функция: вывод помощи
show_help() {
    cat <<EOF
ansible-cobbler Docker image

Usage:
  docker run [OPTIONS] kprklg/ansible-cobbler <COMMAND>

Commands:
  install      Run the full installation (default)
  test         Run local tests (lint + syntax-check)
  rebuild      Rebuild cobbler images only
  uninstall    Remove cobbler stack
  shell        Open a bash shell in the container
  version      Show ansible-cobbler version
  help         Show this help

Environment variables:
  INVENTORY           Inventory path (default: inventories/local/hosts.yml)
  PLAYBOOK            Playbook path (default: playbooks/site.yml)
  COBBLER_MGMT_IP     IP for Web UI (default: 192.168.0.88)
  COBBLER_PXE_IFACE   PXE interface (default: eth0)
  COBBLER_WIFI_IFACE  NAT interface (default: eth1)
  COBBLER_PXE_NETWORK PXE subnet (default: 10.254.254.0/24)
  COBBLER_PXE_IP      macvlan IP (default: 10.254.254.1/24)
  COBBLER_SKIP_BUILDS Skip image builds (default: false)
  EXTRA_ARGS          Extra ansible-playbook arguments

Examples:
  # Default installation (localhost, all env defaults)
  docker run --rm -it --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    kprklg/ansible-cobbler install

  # Custom config via env vars
  docker run --rm -it --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e COBBLER_MGMT_IP=10.0.0.1 \
    -e COBBLER_PXE_IFACE=ens192 \
    kprklg/ansible-cobbler install

  # Mount custom inventory
  docker run --rm -it --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v \$(pwd)/inventories:/opt/ansible-cobbler/inventories \
    kprklg/ansible-cobbler install

  # Run tests only (no install)
  docker run --rm kprklg/ansible-cobbler test

EOF
}

# Функция: запустить ansible-playbook
run_playbook() {
    local pb="$1"
    shift

    # Проверить/создать inventory
    if [[ ! -f "${ANSIBLE_HOME}/${INVENTORY}" ]]; then
        echo "Inventory ${INVENTORY} not found, creating default..."
        create_default_inventory
    fi

    echo "=== Running: ansible-playbook ${pb} -i ${INVENTORY} $* ${EXTRA_ARGS} ==="
    cd "${ANSIBLE_HOME}"
    exec ansible-playbook "${pb}" -i "${INVENTORY}" "$@" ${EXTRA_ARGS}
}

# Функция: запустить тесты
run_tests() {
    cd "${ANSIBLE_HOME}"
    echo "=== yamllint ==="
    yamllint --strict . || true

    echo "=== ansible-lint ==="
    ansible-galaxy collection install -r requirements.yml --force > /dev/null 2>&1 || true
    ansible-lint roles/cobbler/ playbooks/ || true

    echo "=== syntax-check ==="
    for pb in playbooks/*.yml; do
        echo ">>> ${pb}"
        ansible-playbook "${pb}" -i inventories/local/hosts.yml --syntax-check || true
    done
}

# Main
CMD="${1:-help}"
shift || true

case "${CMD}" in
    install)
        run_playbook "${PLAYBOOK}" "$@"
        ;;
    test)
        run_tests
        ;;
    rebuild)
        run_playbook "playbooks/rebuild.yml" "$@"
        ;;
    uninstall)
        run_playbook "playbooks/uninstall.yml" "$@"
        ;;
    shell)
        exec /bin/bash
        ;;
    version)
        git describe --tags --always 2>/dev/null || echo "unknown"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: ${CMD}"
        show_help
        exit 1
        ;;
esac
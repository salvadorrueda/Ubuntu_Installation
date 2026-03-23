#!/usr/bin/env bash

set -euo pipefail

KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="${KEYRING_DIR}/antigravity-repo-key.gpg"
SOURCES_FILE="/etc/apt/sources.list.d/antigravity.list"
REPO_GPG_URL="https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg"
REPO_ENTRY="deb [signed-by=${KEYRING_FILE}] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main"

usage() {
    cat <<'EOF'
Ús:
  sudo ./install_antigravity.sh

Aquest script instal·la Antigravity per Ubuntu seguint les instruccions oficials:
https://antigravity.google/download/linux
EOF
}

require_root() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "Aquest script s'ha d'executar com a root. Fes servir sudo." >&2
        exit 1
    fi
}

require_commands() {
    local command
    for command in curl gpg tee apt-get mkdir; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $command" >&2
            exit 1
        fi
    done
}

setup_antigravity_repository() {
    echo "Configurant el repositori d'Antigravity..."
    mkdir -p "${KEYRING_DIR}"

    curl -fsSL "${REPO_GPG_URL}" | gpg --dearmor --yes -o "${KEYRING_FILE}"
    echo "${REPO_ENTRY}" | tee "${SOURCES_FILE}" >/dev/null
}

install_antigravity() {
    echo "Actualitzant index de paquets..."
    apt-get update

    echo "Instal·lant Antigravity..."
    apt-get install -y antigravity
}

main() {
    if [[ $# -ne 0 ]]; then
        usage
        exit 1
    fi

    require_root
    require_commands
    setup_antigravity_repository
    install_antigravity

    echo "Antigravity s'ha instal·lat correctament."
}

main "$@"

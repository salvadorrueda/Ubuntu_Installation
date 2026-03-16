#!/usr/bin/env bash

set -euo pipefail

KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="${KEYRING_DIR}/packages.microsoft.gpg"
SOURCES_FILE="/etc/apt/sources.list.d/vscode.list"
MICROSOFT_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_REPO="https://packages.microsoft.com/repos/code"

usage() {
    cat <<'EOF'
Ús:
  sudo ./install_vscode.sh

Aquest script instal·la Visual Studio Code en Ubuntu Desktop afegint el
repositori oficial de Microsoft i instal·lant el paquet 'code' via apt.
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
    for command in wget gpg apt-get; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $command" >&2
            exit 1
        fi
    done
}

install_dependencies() {
    echo "Instal·lant dependències..."
    apt-get install -y apt-transport-https ca-certificates curl
}

add_microsoft_key() {
    echo "Afegint la clau GPG de Microsoft..."
    install -d -m 0755 "${KEYRING_DIR}"
    wget -qO- "${MICROSOFT_KEY_URL}" \
        | gpg --dearmor \
        | install -o root -g root -m 644 /dev/stdin "${KEYRING_FILE}"
}

add_vscode_repository() {
    echo "Afegint el repositori de Visual Studio Code..."
    echo "deb [arch=amd64,arm64,armhf signed-by=${KEYRING_FILE}] ${VSCODE_REPO} stable main" \
        > "${SOURCES_FILE}"
}

install_vscode() {
    echo "Actualitzant la llista de paquets i instal·lant Visual Studio Code..."
    apt-get update
    apt-get install -y code
}

main() {
    if [[ $# -ne 0 ]]; then
        usage
        exit 1
    fi

    require_root
    require_commands
    install_dependencies
    add_microsoft_key
    add_vscode_repository
    install_vscode

    echo "Visual Studio Code s'ha instal·lat correctament."
    echo "Pots iniciar-lo executant 'code' o buscant-lo al menú d'aplicacions."
}

main "$@"

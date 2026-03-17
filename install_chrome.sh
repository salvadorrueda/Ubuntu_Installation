#!/usr/bin/env bash

set -euo pipefail

CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
TMP_DEB="$(mktemp --suffix=-google-chrome.deb)"

usage() {
    cat <<'EOF'
Ús:
  sudo ./install_chrome.sh

Aquest script instal·la Google Chrome en Ubuntu Desktop 24.04 descarregant el
paquet .deb oficial de Google i instal·lant-lo via apt.
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
    for command in wget apt-get; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $command" >&2
            exit 1
        fi
    done
}

install_dependencies() {
    echo "Instal·lant dependències..."
    apt-get install -y ca-certificates
}

download_chrome() {
    echo "Descarregant el paquet de Google Chrome..."
    wget -q --show-progress -O "${TMP_DEB}" "${CHROME_URL}"
}

install_chrome() {
    echo "Instal·lant Google Chrome..."
    apt-get install -y "${TMP_DEB}"
}

cleanup() {
    rm -f "${TMP_DEB}"
}

main() {
    if [[ $# -ne 0 ]]; then
        usage
        exit 1
    fi

    trap cleanup EXIT

    require_root
    require_commands
    install_dependencies
    download_chrome
    install_chrome

    echo "Google Chrome s'ha instal·lat correctament."
    echo "Pots iniciar-lo executant 'google-chrome' o buscant-lo al menú d'aplicacions."
}

main "$@"

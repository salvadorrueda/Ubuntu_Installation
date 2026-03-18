#!/usr/bin/env bash

set -euo pipefail

KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="${KEYRING_DIR}/docker.asc"
SOURCES_FILE="/etc/apt/sources.list.d/docker.sources"
DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"

usage() {
    cat <<'EOF'
Ús:
  sudo ./install_docker.sh [--skip-hello-world]

Aquest script instal·la Docker Engine a Ubuntu seguint la documentació oficial:
https://docs.docker.com/engine/install/ubuntu/

Opcions:
  --skip-hello-world   Omet la verificació final amb 'docker run hello-world'.
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
    for command in apt-get curl install chmod tee dpkg cut sed systemctl; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $command" >&2
            exit 1
        fi
    done
}

install_dependencies() {
    echo "Instal·lant dependències bàsiques..."
    apt-get update
    apt-get install -y ca-certificates curl
}

remove_conflicting_packages() {
    local -a packages

    echo "Eliminant possibles paquets conflictius..."
    mapfile -t packages < <(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null | cut -f1)

    if [[ ${#packages[@]} -gt 0 ]]; then
        apt-get remove -y "${packages[@]}"
    else
        echo "No s'han trobat paquets conflictius instal·lats."
    fi
}

setup_docker_keyring() {
    echo "Configurant la clau GPG oficial de Docker..."
    install -m 0755 -d "${KEYRING_DIR}"
    curl -fsSL "${DOCKER_GPG_URL}" -o "${KEYRING_FILE}"
    chmod a+r "${KEYRING_FILE}"
}

setup_docker_repository() {
    local ubuntu_codename

    ubuntu_codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"

    echo "Afegint el repositori oficial de Docker (${ubuntu_codename})..."
    tee "${SOURCES_FILE}" >/dev/null <<EOF
Types: deb
URIs: ${DOCKER_REPO_URL}
Suites: ${ubuntu_codename}
Components: stable
Signed-By: ${KEYRING_FILE}
EOF

    apt-get update
}

install_docker_packages() {
    echo "Instal·lant Docker Engine i plugins oficials..."
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

verify_service() {
    echo "Comprovant l'estat del servei Docker..."
    if ! systemctl is-active --quiet docker; then
        echo "El servei Docker no està actiu. Intentant iniciar-lo..."
        systemctl start docker
    fi

    systemctl --no-pager --full status docker | sed -n '1,10p'
}

verify_hello_world() {
    echo "Executant prova de verificació amb hello-world..."
    docker run hello-world
}

main() {
    local run_hello_world="true"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-hello-world)
                run_hello_world="false"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Opció desconeguda: $1" >&2
                usage
                exit 1
                ;;
        esac
    done

    require_root
    require_commands
    install_dependencies
    remove_conflicting_packages
    setup_docker_keyring
    setup_docker_repository
    install_docker_packages
    verify_service

    if [[ "${run_hello_world}" == "true" ]]; then
        verify_hello_world
    fi

    echo "Docker s'ha instal·lat correctament."
    echo "Per executar Docker sense sudo, segueix: https://docs.docker.com/engine/install/linux-postinstall/"
}

main "$@"

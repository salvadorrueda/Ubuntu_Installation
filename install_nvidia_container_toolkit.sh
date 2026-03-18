#!/usr/bin/env bash

set -euo pipefail

KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="${KEYRING_DIR}/nvidia-container-toolkit.gpg"
SOURCES_FILE="/etc/apt/sources.list.d/nvidia-container-toolkit.sources"
NVIDIA_GPG_URL="https://nvidia.github.io/libnvidia-container/gpgkey"
NVIDIA_REPO_URL="https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH)"

usage() {
    cat <<'EOF'
Ús:
  sudo ./install_nvidia_container_toolkit.sh [--runtime ENGINE] [--skip-test]

Aquest script instal·la el NVIDIA Container Toolkit seguint la documentació oficial:
https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

Opcions:
  --runtime ENGINE   Motor de contenidors a configurar: docker (per defecte), containerd o crio.
  --skip-test        Omet la verificació final amb 'nvidia-smi' dins un contenidor CUDA.
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
    for command in apt-get curl install chmod tee gpg systemctl; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $command" >&2
            exit 1
        fi
    done
}

require_nvidia_gpu() {
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        echo "Advertència: no s'ha detectat 'nvidia-smi'. Assegura't que els drivers NVIDIA estan instal·lats." >&2
    else
        echo "Driver NVIDIA detectat:"
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
    fi
}

install_dependencies() {
    echo "Instal·lant dependències bàsiques..."
    apt-get update
    apt-get install -y ca-certificates curl gpg
}

setup_nvidia_keyring() {
    echo "Configurant la clau GPG oficial de NVIDIA..."
    install -m 0755 -d "${KEYRING_DIR}"
    curl -fsSL "${NVIDIA_GPG_URL}" | gpg --dearmor -o "${KEYRING_FILE}"
    chmod a+r "${KEYRING_FILE}"
}

setup_nvidia_repository() {
    echo "Afegint el repositori oficial del NVIDIA Container Toolkit..."
    tee "${SOURCES_FILE}" >/dev/null <<EOF
Types: deb
URIs: ${NVIDIA_REPO_URL}
Suites: /
Signed-By: ${KEYRING_FILE}
EOF

    apt-get update
}

install_nvidia_container_toolkit() {
    echo "Instal·lant nvidia-container-toolkit..."
    apt-get install -y nvidia-container-toolkit
}

configure_runtime() {
    local runtime="$1"

    case "${runtime}" in
        docker)
            echo "Configurant el runtime Docker..."
            nvidia-ctk runtime configure --runtime=docker
            systemctl restart docker
            ;;
        containerd)
            echo "Configurant el runtime containerd..."
            nvidia-ctk runtime configure --runtime=containerd
            systemctl restart containerd
            ;;
        crio)
            echo "Configurant el runtime CRI-O..."
            nvidia-ctk runtime configure --runtime=crio
            systemctl restart crio
            ;;
        *)
            echo "Runtime desconegut: ${runtime}. Valors vàlids: docker, containerd, crio." >&2
            exit 1
            ;;
    esac
}

verify_installation() {
    local runtime="$1"

    echo "Verificant la instal·lació amb nvidia-smi dins un contenidor CUDA..."

    case "${runtime}" in
        docker)
            docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
            ;;
        containerd)
            echo "Verificació automàtica no disponible per a containerd. Executa manualment:"
            echo "  ctr run --rm --gpus 0 --runtime io.containerd.runc.v2 docker.io/nvidia/cuda:12.0-base-ubuntu22.04 test nvidia-smi"
            ;;
        crio)
            echo "Verificació automàtica no disponible per a CRI-O. Consulta la documentació oficial."
            ;;
    esac
}

main() {
    local runtime="docker"
    local run_test="true"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --runtime)
                runtime="${2:?Falta el valor per a --runtime}"
                shift 2
                ;;
            --skip-test)
                run_test="false"
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
    require_nvidia_gpu
    install_dependencies
    setup_nvidia_keyring
    setup_nvidia_repository
    install_nvidia_container_toolkit
    configure_runtime "${runtime}"

    if [[ "${run_test}" == "true" ]]; then
        verify_installation "${runtime}"
    fi

    echo "NVIDIA Container Toolkit instal·lat i configurat correctament per a '${runtime}'."
}

main "$@"

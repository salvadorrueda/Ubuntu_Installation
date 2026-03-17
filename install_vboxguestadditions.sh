#!/usr/bin/env bash

set -euo pipefail

CDROM_DEVICE="/dev/cdrom"
MOUNT_POINT="/mnt/vboxga"
INSTALLER="VBoxLinuxAdditions.run"

usage() {
    cat <<'EOF'
Ús:
  sudo ./install_vboxguestadditions.sh

Aquest script instal·la les VirtualBox Guest Additions en Ubuntu Desktop 24.04.
Abans d'executar-lo, assegura't que el CD de les Guest Additions estigui inserit
a la màquina virtual: al menú de VirtualBox, ves a
  Dispositius → Inserir imatge de CD de les Guest Additions…
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
    for command in mount umount uname apt-get; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $command" >&2
            exit 1
        fi
    done
}

install_dependencies() {
    echo "Instal·lant les dependències del nucli i les eines de compilació..."
    apt-get update
    apt-get install -y \
        "linux-headers-$(uname -r)" \
        build-essential \
        dkms \
        perl
}

mount_cdrom() {
    echo "Muntant el CD de les Guest Additions a ${MOUNT_POINT}..."
    if [[ ! -b "${CDROM_DEVICE}" ]]; then
        echo "No s'ha trobat el dispositiu ${CDROM_DEVICE}." >&2
        echo "Comprova que el CD de les Guest Additions estigui inserit a la màquina virtual." >&2
        exit 1
    fi
    mkdir -p "${MOUNT_POINT}"
    mount -o ro "${CDROM_DEVICE}" "${MOUNT_POINT}"
}

run_installer() {
    local installer_path="${MOUNT_POINT}/${INSTALLER}"

    if [[ ! -f "${installer_path}" ]]; then
        echo "No s'ha trobat l'instal·lador: ${installer_path}" >&2
        echo "Comprova que el CD inserit és el de les VirtualBox Guest Additions." >&2
        umount "${MOUNT_POINT}" 2>/dev/null || true
        exit 1
    fi

    echo "Executant l'instal·lador de les Guest Additions..."
    bash "${installer_path}"
}

unmount_cdrom() {
    echo "Desmuntant el CD..."
    umount "${MOUNT_POINT}" 2>/dev/null || true
    rmdir "${MOUNT_POINT}" 2>/dev/null || true
}

main() {
    if [[ $# -ne 0 ]]; then
        usage
        exit 1
    fi

    require_root
    require_commands
    install_dependencies
    mount_cdrom
    run_installer
    unmount_cdrom

    echo
    echo "Les VirtualBox Guest Additions s'han instal·lat correctament."
    echo "Reinicia la màquina virtual perquè els canvis tinguin efecte:"
    echo "  sudo reboot"
}

main "$@"

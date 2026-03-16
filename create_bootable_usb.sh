#!/usr/bin/env bash

set -euo pipefail

ISO_PATH="/home/usuari/Downloads/ISO/ubuntu-24.04.4-desktop-amd64.iso"

usage() {
    cat <<'EOF'
Uso:
  sudo ./create_bootable_usb.sh /dev/sdX
  sudo ./create_bootable_usb.sh /dev/nvmeXn1

Este script grabara la ISO configurada en el dispositivo indicado.
ATENCION: todo el contenido del dispositivo de destino sera eliminado.
EOF
}

require_root() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "Este script debe ejecutarse como root. Usa sudo." >&2
        exit 1
    fi
}

require_commands() {
    local command
    for command in dd lsblk findmnt umount sync; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comando requerido: $command" >&2
            exit 1
        fi
    done
}

validate_iso() {
    if [[ ! -f "$ISO_PATH" ]]; then
        echo "No se encuentra la ISO: $ISO_PATH" >&2
        exit 1
    fi
}

validate_target() {
    local target="$1"
    local root_source
    local root_parent
    local type

    if [[ ! -b "$target" ]]; then
        echo "El destino no es un dispositivo de bloque valido: $target" >&2
        exit 1
    fi

    type=$(lsblk -ndo TYPE "$target")
    if [[ "$type" != "disk" ]]; then
        echo "El destino debe ser el disco completo, no una particion: $target" >&2
        exit 1
    fi

    root_source=$(findmnt -n -o SOURCE / || true)
    if [[ -n "$root_source" && -b "$root_source" ]]; then
        root_parent=$(lsblk -ndo PKNAME "$root_source" 2>/dev/null || true)
        if [[ -n "$root_parent" && "$target" == "/dev/$root_parent" ]]; then
            echo "El destino coincide con el disco del sistema: $target" >&2
            exit 1
        fi
    fi

    if findmnt -rn -S "$target" >/dev/null 2>&1; then
        echo "El disco de destino parece estar montado directamente: $target" >&2
        exit 1
    fi
}

show_target_info() {
    local target="$1"

    echo "ISO origen : $ISO_PATH"
    echo "Destino    : $target"
    echo
    lsblk -o NAME,SIZE,MODEL,TRAN,HOTPLUG,MOUNTPOINT "$target"
    echo
}

confirm_target() {
    local target="$1"
    local confirmation

    read -r -p "Escribe exactamente '$target' para continuar: " confirmation
    if [[ "$confirmation" != "$target" ]]; then
        echo "Confirmacion incorrecta. Operacion cancelada."
        exit 1
    fi
}

unmount_partitions() {
    local target="$1"
    local partition

    while IFS= read -r partition; do
        if findmnt -rn -S "$partition" >/dev/null 2>&1; then
            echo "Desmontando $partition"
            umount "$partition"
        fi
    done < <(lsblk -lnpo NAME "$target" | tail -n +2)
}

write_image() {
    local target="$1"

    echo "Grabando imagen. Esto puede tardar varios minutos..."
    dd if="$ISO_PATH" of="$target" bs=4M status=progress conv=fsync
    sync
    echo "Proceso completado. Ya puedes retirar el USB de forma segura."
}

main() {
    if [[ $# -ne 1 ]]; then
        usage
        exit 1
    fi

    require_root
    require_commands
    validate_iso
    validate_target "$1"
    show_target_info "$1"
    confirm_target "$1"
    unmount_partitions "$1"
    write_image "$1"
}

main "$@"

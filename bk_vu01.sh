#!/usr/bin/env bash

set -euo pipefail

VM_NAME="vu01"
DEFAULT_OUTPUT_DIR="${HOME}/VirtualBox_Backups"

usage() {
    cat <<'EOF'
Ús:
  ./bk_vu01.sh [--output-dir <directori>]

Aquest script exporta la màquina virtual "vu01" en format OVA al directori
de còpies de seguretat. El fitxer resultant inclou la data en el nom.

Opcions:
  --output-dir <directori>   Directori on es desarà el fitxer OVA.
                              Per defecte: ~/VirtualBox_Backups
EOF
}

require_commands() {
    local command
    for command in VBoxManage date mkdir; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $command" >&2
            exit 1
        fi
    done
}

check_vm_exists() {
    if ! VBoxManage showvminfo "${VM_NAME}" >/dev/null 2>&1; then
        echo "Error: no s'ha trobat cap màquina virtual amb el nom '${VM_NAME}'." >&2
        exit 1
    fi
}

warn_if_running() {
    local state
    state=$(VBoxManage showvminfo "${VM_NAME}" --machinereadable | grep '^VMState=' | cut -d'"' -f2)
    if [[ "${state}" == "running" ]]; then
        echo "Avís: la màquina virtual '${VM_NAME}' està en execució." >&2
        echo "      S'exportarà en calent; es recomana aturar-la abans per garantir" >&2
        echo "      la consistència de les dades." >&2
    fi
}

export_vm() {
    local output_dir="${1}"
    local timestamp output_file

    timestamp=$(date +%Y%m%d_%H%M%S)
    output_file="${output_dir}/${VM_NAME}_${timestamp}.ova"

    mkdir -p "${output_dir}"

    echo "Exportant '${VM_NAME}' a: ${output_file}"
    VBoxManage export "${VM_NAME}" \
        --output "${output_file}" \
        --ovf20

    echo "Exportació completada: ${output_file}"
    echo "Mida del fitxer: $(du -sh "${output_file}" | cut -f1)"
}

main() {
    local output_dir="${DEFAULT_OUTPUT_DIR}"

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --output-dir)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --output-dir requereix un valor." >&2
                    usage >&2
                    exit 1
                fi
                output_dir="${2}"
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Opció desconeguda: ${1}" >&2
                usage >&2
                exit 1
                ;;
        esac
    done

    require_commands
    check_vm_exists
    warn_if_running
    export_vm "${output_dir}"
}

main "$@"

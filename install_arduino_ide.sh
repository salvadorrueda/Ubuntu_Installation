#!/usr/bin/env bash

set -euo pipefail

GITHUB_API_URL="https://api.github.com/repos/arduino/arduino-ide/releases/latest"

usage() {
    cat <<'EOF'
Ús:
  sudo ./install_arduino_ide.sh [--skip-dialout]

Aquest script instal·la Arduino IDE 2 en Ubuntu Desktop descarregant el
paquet .deb oficial des de GitHub Releases i instal·lant-lo via apt.

Opcions:
  --skip-dialout   Omet l'addició de l'usuari al grup 'dialout' (accés al port sèrie).
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
    for command in curl apt-get; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $command" >&2
            exit 1
        fi
    done
}

get_latest_version() {
    echo "Obtenint la versió més recent d'Arduino IDE..." >&2
    local version
    version=$(curl -fsSL "${GITHUB_API_URL}" \
        | grep '"tag_name"' \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

    if [[ -z "${version}" ]]; then
        echo "No s'ha pogut obtenir la versió més recent d'Arduino IDE." >&2
        exit 1
    fi

    echo "${version}"

}

download_arduino_ide() {
    local version="$1"
    local tmp_deb="$2"
    local url="https://github.com/arduino/arduino-ide/releases/download/${version}/arduino-ide_${version}_Linux_64bit.deb"

    echo "Descarregant Arduino IDE ${version}..."
    curl -fsSL --progress-bar -o "${tmp_deb}" "${url}"
}

install_arduino_ide() {
    local tmp_deb="$1"

    echo "Instal·lant Arduino IDE..."
    apt-get install -y "${tmp_deb}"
}

add_user_to_dialout() {
    local target_user="${SUDO_USER:-}"

    if [[ -z "${target_user}" ]]; then
        echo "Advertència: no s'ha pogut determinar l'usuari original. Afegeix-te manualment al grup 'dialout':" >&2
        echo "  sudo usermod -aG dialout \$USER" >&2
        return
    fi

    if id -nG "${target_user}" | grep -qw "dialout"; then
        echo "L'usuari '${target_user}' ja pertany al grup 'dialout'."
    else
        echo "Afegint '${target_user}' al grup 'dialout' per accedir al port sèrie..."
        usermod -aG dialout "${target_user}"
        echo "Tanca la sessió i torna a entrar perquè el canvi de grup tingui efecte."
    fi
}

main() {
    local skip_dialout="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-dialout)
                skip_dialout="true"
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

    local tmp_deb
    tmp_deb="$(mktemp --suffix=-arduino-ide.deb)"
    trap 'rm -f "${tmp_deb}"' EXIT

    require_root
    require_commands

    local version
    version="$(get_latest_version)"

    download_arduino_ide "${version}" "${tmp_deb}"
    install_arduino_ide "${tmp_deb}"

    if [[ "${skip_dialout}" == "false" ]]; then
        add_user_to_dialout
    fi

    echo "Arduino IDE ${version} s'ha instal·lat correctament."
    echo "Pots iniciar-lo buscant 'Arduino IDE' al menú d'aplicacions."
}

main "$@"

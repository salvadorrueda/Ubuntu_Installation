#!/usr/bin/env bash

set -euo pipefail

GITHUB_API_URL="https://api.github.com/repos/arduino/arduino-ide/releases/latest"
INSTALL_DIR="/opt/arduino-ide"
BIN_LINK="/usr/local/bin/arduino-ide"
DESKTOP_FILE="/usr/share/applications/arduino-ide.desktop"

usage() {
    cat <<'EOF'
Ús:
  sudo ./install_arduino_ide.sh [--skip-dialout]

Aquest script instal·la Arduino IDE 2 en Ubuntu Desktop descarregant el
paquet zip oficial des de GitHub Releases i instal·lant-lo a /opt/arduino-ide.

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
    for command in curl unzip; do
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
    local tmp_zip="$2"
    local url="https://github.com/arduino/arduino-ide/releases/download/${version}/arduino-ide_${version}_Linux_64bit.zip"

    echo "Descarregant Arduino IDE ${version}..."
    curl -fsSL --progress-bar -o "${tmp_zip}" "${url}"
}

install_arduino_ide() {
    local tmp_zip="$1"
    local version="$2"

    [[ -n "${INSTALL_DIR}" ]] || { echo "INSTALL_DIR no està definit." >&2; exit 1; }

    echo "Instal·lant Arduino IDE a ${INSTALL_DIR}..."
    rm -rf "${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}"
    unzip -q "${tmp_zip}" -d "${INSTALL_DIR}"

    if [[ ! -f "${INSTALL_DIR}/arduino-ide" ]]; then
        echo "No s'ha trobat l'executable arduino-ide a ${INSTALL_DIR}." >&2
        exit 1
    fi

    chmod +x "${INSTALL_DIR}/arduino-ide"

    ln -sf "${INSTALL_DIR}/arduino-ide" "${BIN_LINK}"

    local icon
    icon="$(find "${INSTALL_DIR}" -name "512x512.png" -type f 2>/dev/null | head -1)"

    cat > "${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Type=Application
Name=Arduino IDE
Comment=Arduino IDE ${version}
Exec=${INSTALL_DIR}/arduino-ide
Icon=${icon}
Terminal=false
Categories=Development;Electronics;
MimeType=text/x-arduino;
EOF

    update-desktop-database /usr/share/applications 2>/dev/null || true
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

    local tmp_zip
    tmp_zip="$(mktemp --suffix=-arduino-ide.zip)"
    trap 'rm -f "${tmp_zip}"' EXIT

    require_root
    require_commands

    local version
    version="$(get_latest_version)"

    download_arduino_ide "${version}" "${tmp_zip}"
    install_arduino_ide "${tmp_zip}" "${version}"

    if [[ "${skip_dialout}" == "false" ]]; then
        add_user_to_dialout
    fi

    echo "Arduino IDE ${version} s'ha instal·lat correctament."
    echo "Pots iniciar-lo buscant 'Arduino IDE' al menú d'aplicacions."
}

main "$@"

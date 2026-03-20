#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SOURCE_SCRIPT="${SCRIPT_DIR}/scripts/open-terminal-on-login.sh"
SOURCE_DESKTOP="${SCRIPT_DIR}/autostart/open-terminal.desktop"

TARGET_SCRIPT_DIR="${HOME}/.local/bin"
TARGET_AUTOSTART_DIR="${HOME}/.config/autostart"
TARGET_SCRIPT="${TARGET_SCRIPT_DIR}/open-terminal-on-login.sh"
TARGET_DESKTOP="${TARGET_AUTOSTART_DIR}/open-terminal.desktop"

if [[ ! -f "${SOURCE_SCRIPT}" ]]; then
    echo "No s'ha trobat el script origen: ${SOURCE_SCRIPT}" >&2
    exit 1
fi

if [[ ! -f "${SOURCE_DESKTOP}" ]]; then
    echo "No s'ha trobat el fitxer .desktop origen: ${SOURCE_DESKTOP}" >&2
    exit 1
fi

mkdir -p "${TARGET_SCRIPT_DIR}" "${TARGET_AUTOSTART_DIR}"

install -m 0755 "${SOURCE_SCRIPT}" "${TARGET_SCRIPT}"
install -m 0644 "${SOURCE_DESKTOP}" "${TARGET_DESKTOP}"

echo "Configuracio instal·lada correctament."
echo "Script: ${TARGET_SCRIPT}"
echo "Autostart: ${TARGET_DESKTOP}"
echo
echo "Tanca sessio i torna a entrar per provar-ho."
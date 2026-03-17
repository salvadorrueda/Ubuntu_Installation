#!/usr/bin/env bash

set -euo pipefail

# JetBrainsMono Nerd Font – font monoespaciada popular amb cobertura completa
# dels glifs de Nerd Fonts, incloent la icona d'Ubuntu (U+F31B, ).
FONT_NAME="JetBrainsMono"
FONT_VERSION="3.3.0"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.tar.xz"
FONT_DIR="${HOME}/.local/share/fonts/NerdFonts/${FONT_NAME}"

BASHRC="${HOME}/.bashrc"
MARKER_BEGIN="# BEGIN: PS1 personalitzada amb icona d'Ubuntu"
MARKER_END="# END: PS1 personalitzada amb icona d'Ubuntu"

usage() {
    cat <<'EOF'
Ús:
  ./setup_ps1_ubuntu.sh

Aquest script personalitza el prompt del terminal ($PS1) substituint el símbol
'@' de 'usuari@host' per la icona d'Ubuntu (). Per a que la icona es vegi
correctament s'instal·la JetBrainsMono Nerd Font per a l'usuari actual.

El script:
  1. Descarrega i instal·la JetBrainsMono Nerd Font (~/.local/share/fonts).
  2. Afegeix la PS1 personalitzada a ~/.bashrc.
  3. Recorda a l'usuari que cal seleccionar la font al terminal.

No requereix permisos de root.
EOF
}

require_commands() {
    local command
    for command in wget tar fc-cache; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $command" >&2
            exit 1
        fi
    done
}

install_nerd_font() {
    echo "Instal·lant ${FONT_NAME} Nerd Font a ${FONT_DIR}..."
    mkdir -p "${FONT_DIR}"

    local tmp_archive
    tmp_archive="$(mktemp --suffix=.tar.xz)"

    wget -q --show-progress -O "${tmp_archive}" "${FONT_URL}"
    tar -xJf "${tmp_archive}" -C "${FONT_DIR}"
    rm -f "${tmp_archive}"

    fc-cache -f "${FONT_DIR}"
    echo "Font ${FONT_NAME} Nerd Font instal·lada correctament."
}

apply_ps1() {
    echo "Aplicant la PS1 personalitzada a ${BASHRC}..."

    # Icona d'Ubuntu de Nerd Fonts (nf-linux-ubuntu, U+F31B)
    local ubuntu_icon=$'\uf31b'

    # Elimina el bloc anterior si existeix
    if grep -qF "${MARKER_BEGIN}" "${BASHRC}" 2>/dev/null; then
        sed -i "/${MARKER_BEGIN}/,/${MARKER_END}/d" "${BASHRC}"
    fi

    # Construeix el valor de PS1 amb la icona incrustada com a caràcter literal.
    # \033 = ESC en octal (processat per l'expansió de PS1 de bash).
    # \[ i \] = delimitadors de seqüències no imprimibles en PS1.
    # \u, \h, \w, \$ = seqüències especials de PS1 (usuari, host, directori, prompt).
    # Colors: usuari i host en verd brillant, icona en taronja (ANSI 202),
    # directori en blau brillant; coincideix amb el tema per defecte d'Ubuntu.
    local ps1_value
    ps1_value='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]\[\033[38;5;202m\] '"${ubuntu_icon}"'\[\033[00m\]  \[\033[01;32m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

    # Afegeix el nou bloc de PS1 a ~/.bashrc.
    # S'usa 'printf ... %s' per a preservar les barres invertides literals (\033,
    # \[, \u, etc.) sense que printf les interprete com a seqüències d'escapament.
    {
        printf '\n%s\n' "${MARKER_BEGIN}"
        printf '# Icona d'"'"'Ubuntu de Nerd Fonts (U+F31B, %s)\n' "${ubuntu_icon}"
        printf "PS1='%s'\n" "${ps1_value}"
        printf '%s\n' "${MARKER_END}"
    } >> "${BASHRC}"

    echo "PS1 personalitzada afegida a ${BASHRC}."
}

main() {
    if [[ $# -ne 0 ]]; then
        usage
        exit 1
    fi

    require_commands
    install_nerd_font
    apply_ps1

    echo
    echo "Configuració completada."
    echo "Per aplicar els canvis a la sessió actual, executa:"
    echo "  source ~/.bashrc"
    echo
    echo "IMPORTANT: Per veure la icona d'Ubuntu () correctament, cal configurar"
    echo "el terminal perquè faci servir la font '${FONT_NAME} Nerd Font'."
    echo "A GNOME Terminal: Edita → Preferències → Perfil → Text → Font personalitzada."
}

main "$@"

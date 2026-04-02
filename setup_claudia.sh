#!/usr/bin/env bash
# Instal·la la comanda 'claudia': un wrapper de claude amb --dangerously-skip-permissions
# i control remot habilitat (--remote-control).

set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────
WRAPPER_NAME="claudia"
INSTALL_DIR="${HOME}/.local/bin"
WRAPPER_PATH="${INSTALL_DIR}/${WRAPPER_NAME}"
BASHRC="${HOME}/.bashrc"
MARKER_BEGIN="# BEGIN: ${WRAPPER_NAME} PATH"
MARKER_END="# END: ${WRAPPER_NAME} PATH"

# ── Ús ───────────────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
Ús:
  ./setup_claudia.sh [--project NOM] [--uninstall]

Opcions:
  --uninstall     Elimina el wrapper i les entrades a ~/.bashrc
  -h, --help      Mostra aquest missatge

Descripció:
  Instal·la la comanda '${WRAPPER_NAME}' a ${INSTALL_DIR}/.
  En executar '${WRAPPER_NAME}' s'inicia:
    claude --dangerously-skip-permissions --remote-control "NOM_CARPETA"

  El nom del projecte s'agafa automàticament del nom de la carpeta on
  s'executa 'claudia'. Per exemple, a /home/user/Developer/fac el projecte
  serà "fac".

  Amb --remote-control la sessió és accessible des de claude.ai o l'app de Claude.

No requereix permisos de root.
EOF
}

# ── Precondicions ─────────────────────────────────────────────────────────────
require_commands() {
    local cmd
    for cmd in claude; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Falta el comandament requerit: $cmd" >&2
            echo "Instal·la Claude Code amb: npm install -g @anthropic-ai/claude-code" >&2
            exit 1
        fi
    done
}

# ── Instal·lació ──────────────────────────────────────────────────────────────
install_wrapper() {
    echo "Creant directori ${INSTALL_DIR}..."
    mkdir -p "${INSTALL_DIR}"

    echo "Escrivint wrapper ${WRAPPER_PATH}..."
    # El nom del projecte pot arribar com a argument posicional al wrapper ($1),
    # o s'usa el valor configurat en temps d'instal·lació com a valor per defecte.
    cat > "${WRAPPER_PATH}" <<'WRAPPER'
#!/usr/bin/env bash
# Wrapper generat per setup_claudia.sh
# Inicia Claude Code amb permisos ampliats i control remot habilitat.
# Usa el nom de la carpeta actual com a nom del projecte.
PROJECT="$(basename "$PWD")"
exec claude --dangerously-skip-permissions --remote-control "${PROJECT}"
WRAPPER
    chmod +x "${WRAPPER_PATH}"
    echo "Wrapper instal·lat a ${WRAPPER_PATH}."
}

add_to_path() {
    # Afegeix ~/.local/bin al PATH de ~/.bashrc (idempotent via marcadors)
    if echo "${PATH}" | grep -q "${INSTALL_DIR}"; then
        echo "${INSTALL_DIR} ja és al PATH actiu."
    fi

    if grep -qF "${MARKER_BEGIN}" "${BASHRC}" 2>/dev/null; then
        echo "Entrada de PATH ja present a ${BASHRC}, s'actualitza..."
        sed -i "/${MARKER_BEGIN}/,/${MARKER_END}/d" "${BASHRC}"
    fi

    {
        printf '\n%s\n' "${MARKER_BEGIN}"
        printf 'export PATH="%s:${PATH}"\n' "${INSTALL_DIR}"
        printf '%s\n' "${MARKER_END}"
    } >> "${BASHRC}"

    echo "PATH actualitzat a ${BASHRC}."
}

# ── Desinstal·lació ───────────────────────────────────────────────────────────
uninstall_wrapper() {
    if [[ -f "${WRAPPER_PATH}" ]]; then
        rm -f "${WRAPPER_PATH}"
        echo "Wrapper eliminat: ${WRAPPER_PATH}"
    else
        echo "Wrapper no trobat: ${WRAPPER_PATH}"
    fi

    if grep -qF "${MARKER_BEGIN}" "${BASHRC}" 2>/dev/null; then
        sed -i "/${MARKER_BEGIN}/,/${MARKER_END}/d" "${BASHRC}"
        echo "Entrada de PATH eliminada de ${BASHRC}."
    fi

    echo "Desinstal·lació completada."
}

# ── Verificació ───────────────────────────────────────────────────────────────
verify_install() {
    echo
    echo "Verificació:"
    if [[ -x "${WRAPPER_PATH}" ]]; then
        echo "  [OK] ${WRAPPER_PATH} existeix i és executable."
    else
        echo "  [ERROR] ${WRAPPER_PATH} no trobat o no executable." >&2
        exit 1
    fi
    echo
    echo "Instal·lació completada."
    echo "Per aplicar els canvis a la sessió actual, executa:"
    echo "  source ~/.bashrc"
    echo
    echo "Llavors, des de qualsevol carpeta de projecte:"
    echo "  cd /home/user/Developer/fac"
    echo "  ${WRAPPER_NAME}   # inicia amb --remote-control \"fac\""
    echo
    echo "La sessió serà accessible via control remot des de claude.ai o l'app de Claude."
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    local uninstall=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall)
                uninstall=true
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

    if "${uninstall}"; then
        uninstall_wrapper
        exit 0
    fi

    require_commands
    install_wrapper
    add_to_path
    verify_install
}

main "$@"

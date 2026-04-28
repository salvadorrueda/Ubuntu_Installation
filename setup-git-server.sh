#!/bin/bash
# setup-git-server.sh — instala un servidor Git con acceso por SSH
# Uso: sudo bash setup-git-server.sh

set -euo pipefail

GIT_USER="git"
GIT_HOME="/home/git"
AUTHORIZED_KEYS_FILE="$GIT_HOME/.ssh/authorized_keys"

# ── colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── verificaciones ────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Ejecuta este script como root (sudo)."

# ── instalar git y openssh-server ─────────────────────────────────────────────
info "Instalando git y openssh-server..."
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y git openssh-server
elif command -v dnf &>/dev/null; then
    dnf install -y git openssh-server
    systemctl enable --now sshd
elif command -v yum &>/dev/null; then
    yum install -y git openssh-server
    systemctl enable --now sshd
else
    error "Gestor de paquetes no soportado. Instala git y openssh-server manualmente."
fi

# ── crear usuario git con git-shell ───────────────────────────────────────────
if id "$GIT_USER" &>/dev/null; then
    warn "El usuario '$GIT_USER' ya existe. Se omite la creación."
else
    info "Creando usuario '$GIT_USER'..."
    useradd -m -d "$GIT_HOME" -s "$(command -v git-shell)" "$GIT_USER"
    passwd -l "$GIT_USER"   # bloquea contraseña (solo SSH)
fi

# Asegurar que usa git-shell (por si el usuario ya existía con otra shell)
GIT_SHELL_PATH="$(command -v git-shell)"
usermod -s "$GIT_SHELL_PATH" "$GIT_USER"

# ── directorio SSH y authorized_keys ─────────────────────────────────────────
info "Configurando directorio SSH..."
mkdir -p "$GIT_HOME/.ssh"
touch "$AUTHORIZED_KEYS_FILE"
chmod 700 "$GIT_HOME/.ssh"
chmod 600 "$AUTHORIZED_KEYS_FILE"
chown -R "$GIT_USER:$GIT_USER" "$GIT_HOME/.ssh"

# ── directorio de repositorios ───────────────────────────────────────────────
REPOS_DIR="$GIT_HOME/repos"
mkdir -p "$REPOS_DIR"
chown "$GIT_USER:$GIT_USER" "$REPOS_DIR"
info "Los repositorios se crearán en: $REPOS_DIR"

# ── habilitar git-shell-commands (opcional: permite listar repos) ─────────────
GIT_SHELL_CMDS="$GIT_HOME/git-shell-commands"
mkdir -p "$GIT_SHELL_CMDS"
chown "$GIT_USER:$GIT_USER" "$GIT_SHELL_CMDS"

# ── asegurar que sshd está activo ────────────────────────────────────────────
if systemctl is-active sshd &>/dev/null || systemctl is-active ssh &>/dev/null; then
    info "SSH está activo."
else
    warn "Intentando iniciar SSH..."
    systemctl start sshd 2>/dev/null || systemctl start ssh 2>/dev/null || \
        warn "No se pudo iniciar SSH. Comprueba el servicio manualmente."
fi

# ── resumen ──────────────────────────────────────────────────────────────────
SERVER_IP="$(hostname -I | awk '{print $1}')"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  Servidor Git instalado correctamente${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Usuario git:    $GIT_USER (shell: $GIT_SHELL_PATH)"
echo "  Repos en:       $REPOS_DIR"
echo "  Claves SSH en:  $AUTHORIZED_KEYS_FILE"
echo "  IP del servidor: $SERVER_IP"
echo ""
echo "  PRÓXIMOS PASOS:"
echo ""
echo "  1. Añade claves SSH de los usuarios:"
echo "     cat ~/.ssh/id_ed25519.pub | sudo tee -a $AUTHORIZED_KEYS_FILE"
echo ""
echo "  2. Crea un repositorio bare en el servidor:"
echo "     sudo -u git git init --bare $REPOS_DIR/mi-proyecto.git"
echo ""
echo "  3. Clona desde tu máquina cliente:"
echo "     git clone git@$SERVER_IP:repos/mi-proyecto.git"
echo ""
echo "  4. O añade como remote a un repo existente:"
echo "     git remote add origin git@$SERVER_IP:repos/mi-proyecto.git"
echo "     git push -u origin main"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

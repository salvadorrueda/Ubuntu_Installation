Script creado en `setup-git-server.sh`. Lo que hace:

**Instalación**
- Detecta el gestor de paquetes (apt/dnf/yum) e instala `git` y `openssh-server`
- Crea el usuario `git` con `git-shell` como shell (acceso solo a repos, no a bash)
- Bloquea el login por contraseña (solo SSH keys)

**Uso**
```bash
sudo bash setup-git-server.sh
```

**Flujo de trabajo después de instalarlo:**

```bash
# 1. Añadir clave pública de cada usuario
cat ~/.ssh/id_ed25519.pub | sudo tee -a /home/git/.ssh/authorized_keys

# 2. Crear un repo bare en el servidor
sudo -u git git init --bare /home/git/repos/mi-proyecto.git

# 3. Clonar desde el cliente
git clone git@<ip-servidor>:repos/mi-proyecto.git
```

**Seguridad incluida:**
- `git-shell` impide que los usuarios abran una sesión bash real
- Autenticación solo por clave SSH (contraseña bloqueada)
- Los permisos de `.ssh/` son los correctos (700/600)

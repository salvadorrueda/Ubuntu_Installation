# Ubuntu_Installation
Scripts que automatitzen la instal·lació i configuració de Ubuntu Desktop

## Crear un USB bootable

El script [create_bootable_usb.sh](./create_bootable_usb.sh) grava la ISO:

`/home/usuari/Downloads/ISO/ubuntu-24.04.4-desktop-amd64.iso`

Uso:

```bash
sudo ./create_bootable_usb.sh /dev/sdX
```

Substitueix `/dev/sdX` pel disc complet del USB, per exemple `/dev/sdb`.
El script mostra la informació del dispositiu, demana confirmació explícita i després executa `dd`.

## Instal·lar VirtualBox Guest Additions

El script [install_vboxguestadditions.sh](./install_vboxguestadditions.sh) instal·la les VirtualBox Guest Additions en una màquina virtual amb Ubuntu Desktop 24.04.

Abans d'executar-lo, insereix el CD de les Guest Additions a la màquina virtual des del menú de VirtualBox: **Dispositius → Inserir imatge de CD de les Guest Additions…**

Ús:

```bash
sudo ./install_vboxguestadditions.sh
```

El script:
1. Instal·la les dependències necessàries (`linux-headers`, `build-essential`, `dkms`, `perl`).
2. Munta el CD de les Guest Additions a `/mnt/vboxga`.
3. Executa l'instal·lador `VBoxLinuxAdditions.run`.
4. Desmunta el CD un cop finalitzada la instal·lació.

Quan el script acabi, reinicia la màquina virtual amb `sudo reboot` perquè els canvis tinguin efecte.

## Instal·lar Google Chrome

El script [install_chrome.sh](./install_chrome.sh) instal·la Google Chrome descarregant el paquet `.deb` oficial de Google i instal·lant-lo via apt.

Ús:

```bash
sudo ./install_chrome.sh
```

El script:
1. Instal·la les dependències necessàries (`ca-certificates`).
2. Descarrega el paquet `google-chrome-stable_current_amd64.deb` directament des dels servidors de Google.
3. Instal·la el paquet amb `apt-get` (que gestiona automàticament les dependències).
4. Elimina el fitxer `.deb` temporal un cop finalitzada la instal·lació.

## Personalitzar el prompt del terminal amb la icona d'Ubuntu

El script [setup_ps1_ubuntu.sh](./setup_ps1_ubuntu.sh) personalitza la variable `$PS1` del terminal substituint el símbol `@` de `usuari@host` per la icona d'Ubuntu (``, U+F31B de Nerd Fonts).

Per a que la icona es vegi correctament cal una font Nerd Font; el script instal·la **JetBrainsMono Nerd Font** automàticament per a l'usuari actual.

Ús:

```bash
./setup_ps1_ubuntu.sh
```

No requereix permisos de root.

El script:
1. Descarrega i instal·la JetBrainsMono Nerd Font a `~/.local/share/fonts/NerdFonts/`.
2. Afegeix la PS1 personalitzada a `~/.bashrc`, preservant la configuració existent.
3. Si el script s'executa de nou, substitueix el bloc anterior sense duplicar-lo.

Quan el script acabi, aplica els canvis a la sessió actual amb:

```bash
source ~/.bashrc
```

**IMPORTANT:** Per veure la icona d'Ubuntu correctament, cal configurar el terminal perquè faci servir la font `JetBrainsMono Nerd Font`. A GNOME Terminal: **Edita → Preferències → Perfil → Text → Font personalitzada**.

## Instal·lar Visual Studio Code

El script [install_vscode.sh](./install_vscode.sh) instal·la Visual Studio Code afegint el repositori oficial de Microsoft i instal·lant el paquet `code` via apt.

Ús:

```bash
sudo ./install_vscode.sh
```

El script:
1. Instal·la les dependències necessàries (`apt-transport-https`, `ca-certificates`, `curl`).
2. Afegeix la clau GPG de Microsoft a `/etc/apt/keyrings/packages.microsoft.gpg`.
3. Afegeix el repositori oficial de VS Code a `/etc/apt/sources.list.d/vscode.list`.
4. Actualitza la llista de paquets i instal·la `code`.

## Instal·lar Docker Engine

El script [install_docker.sh](./install_docker.sh) instal·la Docker Engine a Ubuntu seguint la documentació oficial de Docker per Ubuntu:
[https://docs.docker.com/engine/install/ubuntu/](https://docs.docker.com/engine/install/ubuntu/)

Ús:

```bash
sudo ./install_docker.sh
```

Opcionalment, per ometre la prova final amb la imatge `hello-world`:

```bash
sudo ./install_docker.sh --skip-hello-world
```

El script:
1. Instal·la les dependències requerides (`ca-certificates`, `curl`).
2. Elimina paquets conflictius antics (`docker.io`, `podman-docker`, `containerd`, `runc`, etc.).
3. Configura la clau GPG oficial de Docker a `/etc/apt/keyrings/docker.asc`.
4. Afegeix el repositori oficial de Docker a `/etc/apt/sources.list.d/docker.sources`.
5. Instal·la els paquets oficials: `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` i `docker-compose-plugin`.
6. Verifica que el servei Docker estigui actiu i, per defecte, executa `docker run hello-world`.

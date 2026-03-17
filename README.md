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

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

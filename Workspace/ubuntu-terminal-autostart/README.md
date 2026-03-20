# Ubuntu Terminal Autostart

This project provides a simple solution to automatically open a terminal window upon logging into the Ubuntu Desktop environment.

## Project Structure

```
ubuntu-terminal-autostart
├── install.sh
├── scripts
│   └── open-terminal-on-login.sh
├── autostart
│   └── open-terminal.desktop
└── README.md
```

## Files Description

- **scripts/open-terminal-on-login.sh**: This script is executed upon login to open a terminal window. It checks common terminal emulators and launches the first available one.

- **autostart/open-terminal.desktop**: This is a desktop entry file that specifies how the terminal should be launched at startup. It includes fields such as Type, Name, Exec (which points to the script), and X-GNOME-Autostart-enabled.

- **install.sh**: Installs the launcher script into `~/.local/bin` and the autostart entry into `~/.config/autostart`.

## Setup Instructions

1. **Clone the repository** or download the project files to your local machine.

2. **Make installer executable**:
   Open a terminal in this project and run:
   ```
   chmod +x install.sh
   ```

3. **Install autostart config**:
   Run:
   ```
   ./install.sh
   ```

4. **Log out and log back in**:
   Upon logging back into your Ubuntu Desktop environment, a terminal window should automatically open.

## Notes

- The login script will try `gnome-terminal`, `kgx`, `x-terminal-emulator`, and `xterm`.
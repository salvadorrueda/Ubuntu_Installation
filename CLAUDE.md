# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A collection of Bash scripts that automate Ubuntu Desktop installation and configuration tasks. Scripts are written in Catalan and follow a consistent pattern.

## Script Conventions

All scripts use `set -euo pipefail` and follow this structure:
1. Constants defined at the top
2. `usage()` — prints usage information
3. `require_root()` / `require_commands()` — precondition checks
4. Task functions (install, configure, verify)
5. `main()` — parses args, calls task functions in order

Scripts that require root fail early via `require_root()`. Scripts that modify `~/.bashrc` (like `setup_ps1_ubuntu.sh`) do not require root.

## Running Scripts

Most scripts require root:
```bash
sudo ./install_docker.sh [--skip-hello-world]
sudo ./install_nvidia_container_toolkit.sh [--runtime docker|containerd|crio] [--skip-test]
sudo ./install_antigravity.sh
sudo ./install_vboxguestadditions.sh
sudo ./install_chrome.sh
sudo ./install_vscode.sh
sudo ./create_bootable_usb.sh /dev/sdX
```

No root needed:
```bash
./setup_ps1_ubuntu.sh       # Customizes PS1 and installs JetBrainsMono Nerd Font
```

The `Workspace/ubuntu-terminal-autostart/` sub-project installs via:
```bash
chmod +x Workspace/ubuntu-terminal-autostart/install.sh
./Workspace/ubuntu-terminal-autostart/install.sh
```

## APT Repository Pattern

Scripts that add third-party repositories follow this pattern:
1. Add GPG key to `/etc/apt/keyrings/`
2. Add repo entry to `/etc/apt/sources.list.d/` (using `.sources` DEB822 format or `.list` format)
3. Run `apt-get update` then install packages

## `setup_ps1_ubuntu.sh` Details

Uses idempotent block markers in `~/.bashrc` (`# BEGIN:` / `# END:`) to prevent duplicate entries on re-runs. The Ubuntu icon is U+F31B from Nerd Fonts — requires a Nerd Font set in the terminal emulator to render correctly.

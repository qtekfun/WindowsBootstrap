# WindowsBootstrap

**WindowsBootstrap** is a complete PowerShell bootstrap script for Windows 10/11 that performs:

- Aggressive debloat (Level B)
- Privacy hardening
- Installation of essential developer tools and apps
- WSL2 with Fedora Remix
- Oh My Posh and Nerd Fonts
- PowerShell 7 setup with profile, aliases, and autocompletion

It can be executed directly from GitHub using a single command.

---

## Quick Start

Open PowerShell as Administrator and run:

    irm https://raw.githubusercontent.com/qtekfun/WindowsBootstrap/refs/heads/master/SetupBootstrap.ps1 | iex

This will:

- Debloat Windows
- Install all requested apps and tools
- Configure privacy and PowerShell profile
- Restart Explorer to apply changes

> Warning: Only run scripts from trusted sources. This script performs system-level changes.

---

## Features

### Debloat & Privacy
- Removes consumer bloat apps (Xbox, OneNote, Teams, etc.)
- Minimal telemetry
- Disable Start menu suggestions and ads

### Installed Applications
- Browsers: Chrome, Brave
- Development: VSCode, Git, Python, pipx, PowerShell 7, Android Studio, Docker Desktop
- Utilities: 7zip, Notepad++, Nextcloud Desktop, Portmaster, Mullvad VPN, Bitwarden

### WSL
- Installs WSL2
- Adds Fedora Remix distribution

### Oh My Posh & Nerd Fonts
- Installs and configures Oh My Posh
- Adds CascadiaCode Nerd Font

### PowerShell Profile
- Aliases:
    - `psa` – open elevated PowerShell
    - `upg` – upgrade all apps with Winget
- Autocompletion for Winget and Git (native)

---

## Notes

- Compatible with Windows 10/11 (tested latest builds)
- Script is modular and can be modified if needed
- Logs are generated at:

    USERPROFILE\SetupBootstrap.log

---

## Raw Script URL

- https://raw.githubusercontent.com/qtekfun/WindowsBootstrap/refs/heads/master/SetupBootstrap.ps1

---

## Tips

- Restart PowerShell after running the script to load the new profile.
- To update in the future, rerun the `irm | iex` command.
- Modify the profile to customize Oh My Posh themes if desired.

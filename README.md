# Debian System Updater

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=flat&logo=gnu-bash&logoColor=white)

Comprehensive system update scripts for Debian-based systems including Ubuntu, Zorin OS, Proxmox, Linux Mint, Pop!_OS, and other derivatives.

## 🚀 Features

- **Package Management**: APT updates, upgrades, and cleanup with mirror-sync retry logic
- **Oh My Zsh**: Updates framework, custom plugins, and themes — handles dirty working tree automatically (Zsh version)
- **NVM / Node.js / npm**: Updates NVM itself, installs LTS Node, updates npm (Zsh version)
- **Python pip**: Updates user-installed pip packages only, keeping apt-managed packages untouched (Zsh version)
- **Ollama**: Self-updates Ollama if installed (Zsh version)
- **Snap Packages**: Automatic snap package updates
- **Flatpak Support**: Updates Flatpak applications and runtimes
- **Docker Integration**: Updates Docker CE and cleans unused resources
- **Claude Code**: Updates Claude Code CLI (`claude update`) if installed
- **Security Updates**: Dedicated security update checking and installation
- **Firmware Updates**: BIOS/UEFI and hardware driver updates via fwupd
- **Run Logging**: Appends full output to `/var/log/system-update.log` when writable
- **System Cleanup**: Log rotation, cache cleaning, database updates
- **Smart Execution**: Works as root or with sudo automatically
- **Comprehensive Reporting**: Detailed summary of all operations
- **Reboot Detection**: Shows when restart is required and which packages triggered it

## 📋 Requirements

- Debian-based operating system (Ubuntu, Debian, Zorin OS, Proxmox, etc.)
- Root access or sudo privileges
- Internet connection for updates

## 📦 Scripts

| Script | Description | Best For |
|--------|-------------|----------|
| `update-system.sh` | Bash version with universal compatibility | Servers, headless systems, Proxmox, general use |
| `update-system-zsh.sh` | Zsh version with Oh My Zsh, NVM, pip, Ollama support | Desktop systems, development environments |

## 🛠️ Installation

### Quick Download and Run
```bash
# Download the bash version
wget https://raw.githubusercontent.com/tgthibodaux/debian-system-updater/main/update-system.sh
chmod +x update-system.sh
./update-system.sh
```

### Clone Repository
```bash
git clone https://github.com/tgthibodaux/debian-system-updater.git
cd debian-system-updater
chmod +x update-system.sh update-system-zsh.sh
```

## 🚀 Usage

```bash
# Bash version (servers, headless, Proxmox)
./update-system.sh

# Zsh version (desktops with Oh My Zsh / NVM)
./update-system-zsh.sh

# Run as root (no sudo prompts)
sudo ./update-system.sh
```

## 📝 What It Does

### Both Scripts
1. **Updates package lists** (`apt update`) — retries up to 3× on mirror sync errors
2. **Upgrades packages** (`apt upgrade`)
3. **Performs full upgrade** (`apt full-upgrade`)
4. **Removes unused packages** (`apt autoremove`)
5. **Cleans package cache** (`apt autoclean`)
6. **Updates Snap packages** (if installed)
7. **Updates Flatpak packages** (if installed)
8. **Checks firmware updates** (if fwupd available)
9. **Updates Docker** (if installed)
10. **Updates Claude Code** (if installed)
11. **Security update check** and installation
12. **System log cleanup** (removes logs older than 7 days)
13. **Cache cleanup** and locate database update
14. **Reboot requirement detection** with package list
15. **System information summary**
16. **Run log** appended to `/var/log/system-update.log`

### Zsh Version Only
- **Oh My Zsh**: Updates framework; detects and stashes local modifications to tracked files before pulling so the update never aborts
- **NVM**: Self-updates NVM, installs Node.js LTS, updates npm
- **pip**: Upgrades user-installed packages only (`--user`) in a single pip invocation for clean dependency resolution — never touches apt-managed system packages
- **Ollama**: Runs the official self-updater if Ollama is installed

## 🖥️ Supported Systems

- ✅ **Ubuntu** (20.04, 22.04, 24.04+)
- ✅ **Zorin OS** (16, 17, 18+)
- ✅ **Debian** (11, 12+)
- ✅ **Proxmox VE** (7.0+)
- ✅ **Linux Mint**
- ✅ **Pop!_OS**
- ✅ **Elementary OS**
- ✅ **Other Debian derivatives**

## 🔧 Compatibility

- **Shell**: Bash 4.0+ (bash version) / Zsh 5.0+ (zsh version)
- **Architecture**: x86_64, ARM64, ARM
- **Environment**: Desktop, Server, Headless, WSL2
- **Permissions**: Works as root or with sudo

## 🤝 Contributing

Contributions are welcome! Please feel free to:

- Report bugs or issues
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

These scripts perform system-level operations. While designed to be safe:

- **Always backup important data** before running system updates
- **Test in a non-production environment** first
- **Review the scripts** to understand what they do
- The authors are not responsible for any system issues

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/tgthibodaux/debian-system-updater/issues)
- **Discussions**: [GitHub Discussions](https://github.com/tgthibodaux/debian-system-updater/discussions)

## 📈 Version History

- **v2.0** (May 2026) - Zsh: NVM/Node LTS, pip (user-only, single-pass), Ollama, Oh My Zsh dirty-state stash; both: apt mirror-sync retry, run logging, deduped disk usage output
- **v1.1** (March 2026) - Added Claude Code update step (`claude update`)
- **v1.0** (August 2025) - Initial release with comprehensive update automation

---

*Last updated: May 30, 2026*

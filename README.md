# Debian System Updater

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=flat&logo=gnu-bash&logoColor=white)

Comprehensive system update scripts for Debian-based systems including Ubuntu, Proxmox, Linux Mint, Pop!_OS, and other derivatives.

## 🚀 Features

- **Package Management**: APT updates, upgrades, and cleanup
- **Snap Packages**: Automatic snap package updates
- **Flatpak Support**: Updates Flatpak applications and runtimes
- **Docker Integration**: Updates Docker CE and cleans unused resources
- **Security Updates**: Dedicated security update checking and installation
- **Firmware Updates**: BIOS/UEFI and hardware driver updates via fwupd
- **System Cleanup**: Log rotation, cache cleaning, database updates
- **Oh My Zsh**: Updates framework, custom plugins, and themes (Zsh version)
- **Smart Execution**: Works as root or with sudo automatically
- **Comprehensive Reporting**: Detailed summary of all operations
- **Reboot Detection**: Shows when restart is required and why

## 📋 Requirements

- Debian-based operating system (Ubuntu, Debian, Proxmox, etc.)
- Root access or sudo privileges
- Internet connection for updates

## 📦 Scripts

| Script | Description | Best For |
|--------|-------------|----------|
| `update-system.sh` | Bash version with universal compatibility | Servers, headless systems, general use |
| `update-system-zsh.sh` | Zsh version with Oh My Zsh support | Desktop systems, development environments |

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

### Basic Usage
```bash
# Run the bash version (recommended for most users)
./update-system.sh

# Run the zsh version (if you use Oh My Zsh)
./update-system-zsh.sh
```

### Advanced Usage
```bash
# Run as root (no sudo prompts)
sudo ./update-system.sh

# Run on Proxmox/server systems
./update-system.sh  # Works automatically as root
```

## 📝 What It Does

### System Updates
1. **Updates package lists** (`apt update`)
2. **Upgrades packages** (`apt upgrade`)
3. **Performs full upgrade** (`apt full-upgrade`)
4. **Removes unused packages** (`apt autoremove`)
5. **Cleans package cache** (`apt autoclean`)

### Additional Updates
6. **Updates Snap packages** (if installed)
7. **Updates Flatpak packages** (if installed)
8. **Updates Docker** (if installed)
9. **Checks firmware updates** (if fwupd available)
10. **Updates Oh My Zsh** (Zsh version only)

### System Maintenance
11. **Security update check** and installation
12. **System log cleanup** (removes logs older than 7 days)
13. **Cache cleanup** and database updates
14. **Reboot requirement detection**
15. **System information summary**

## 🖥️ Supported Systems

- ✅ **Ubuntu** (20.04, 22.04, 24.04+)
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

## 📊 Example Output

```
======================================
Starting System Update Process
======================================

[INFO] Script started at: Fri Aug  1 10:30:15 2025
[INFO] Running as root - no sudo needed.

======================================
Step 1: Updating Package Lists (apt update)
======================================

[INFO] Refreshing package database from repositories...
[INFO] Package lists updated successfully!

... (detailed progress for each step) ...

======================================
Update Process Complete!
======================================

[INFO] Summary of completed tasks:
  ✓ Updated package lists
  ✓ Upgraded installed packages
  ✓ Performed full upgrade
  ✓ Removed unused packages
  ✓ Cleaned package cache
  ✓ Updated Snap packages
  ✓ Updated Docker
  ✓ Performed security checks
  ✓ System cleanup completed

[INFO] Your system is now up to date!
```

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

- **v1.0** (August 2025) - Initial release with comprehensive update automation

---

*Last updated: August 1, 2025*

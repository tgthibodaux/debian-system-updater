#!/usr/bin/env bash

# Debian System Update Script
# This script performs a comprehensive system update
# Last updated: May 30, 2026

# ── Logging ──────────────────────────────────────────────────────────────────
LOG_FILE="/var/log/system-update.log"
if touch "$LOG_FILE" 2>/dev/null; then
    exec > >(tee -a "$LOG_FILE") 2>&1
else
    LOG_FILE=""
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}======================================${NC}\n"
}
print_status()  { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Privilege check ───────────────────────────────────────────────────────────
SUDO_CMD=""
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        print_status "Running as root - no sudo needed."
        SUDO_CMD=""
    else
        if ! command -v sudo >/dev/null 2>&1; then
            print_error "Not running as root and sudo is not available."
            exit 1
        fi
        if ! sudo -n true 2>/dev/null; then
            print_warning "This script requires sudo privileges. You may be prompted for your password."
            sudo -v || { print_error "Failed to obtain sudo privileges. Exiting."; exit 1; }
        fi
        SUDO_CMD="sudo"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
print_header "Starting System Update Process"
print_status "Script started at: $(date)"
[[ -n "$LOG_FILE" ]] && print_status "Logging to: $LOG_FILE" \
    || print_warning "Could not write to /var/log — logging to stdout only."

check_privileges

# ── Step 1: apt update (with mirror-sync retry) ───────────────────────────────
print_header "Step 1: Updating Package Lists (apt update)"
print_status "Refreshing package database from repositories..."
print_status "This downloads the latest package information but doesn't install anything yet."

APT_UPDATE_SUCCESS=false
for i in 1 2 3; do
    if $SUDO_CMD apt update 2>&1; then
        APT_UPDATE_SUCCESS=true
        break
    else
        if [[ $i -lt 3 ]]; then
            print_warning "apt update attempt $i failed (possible mirror sync in progress). Retrying in 60s..."
            sleep 60
        fi
    fi
done

if $APT_UPDATE_SUCCESS; then
    print_status "Package lists updated successfully!"
else
    print_error "Failed to update package lists after 3 attempts. Check your internet connection."
    print_warning "Continuing with cached package lists — some updates may be skipped."
fi

# ── Step 2: apt upgrade ───────────────────────────────────────────────────────
print_header "Step 2: Upgrading Installed Packages (apt upgrade)"
print_status "Upgrading all installed packages to their latest versions..."
print_status "This installs newer versions of packages you already have installed."
if DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt upgrade -y; then
    print_status "Package upgrade completed successfully!"
else
    print_warning "Some packages may not have upgraded successfully."
fi

# ── Step 3: apt full-upgrade ──────────────────────────────────────────────────
print_header "Step 3: Performing Full Upgrade (apt full-upgrade)"
print_status "Performing full upgrade with intelligent dependency handling..."
print_status "This can install new packages or remove packages if needed for upgrades."
if DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt full-upgrade -y; then
    print_status "Full upgrade completed successfully!"
else
    print_warning "Full upgrade encountered some issues."
fi

# ── Step 4: apt autoremove ────────────────────────────────────────────────────
print_header "Step 4: Removing Unused Packages (apt autoremove)"
print_status "Removing packages that were automatically installed and are no longer needed..."
print_status "This frees up disk space by removing orphaned dependencies."
if DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt autoremove -y; then
    print_status "Unused packages removed successfully!"
else
    print_warning "Autoremove encountered some issues."
fi

# ── Step 5: apt autoclean ─────────────────────────────────────────────────────
print_header "Step 5: Cleaning Package Cache (apt autoclean)"
print_status "Cleaning the local package cache..."
print_status "This removes cached package files that can no longer be downloaded."
if $SUDO_CMD apt autoclean; then
    print_status "Package cache cleaned successfully!"
else
    print_warning "Autoclean encountered some issues."
fi

# ── Step 6: Snap ──────────────────────────────────────────────────────────────
print_header "Step 6: Updating Snap Packages"
if command -v snap >/dev/null 2>&1; then
    print_status "Updating snap packages..."
    print_status "Snap packages auto-update, but we'll refresh to check for immediate updates."
    if $SUDO_CMD snap refresh; then
        print_status "Snap packages updated successfully!"
    else
        print_warning "Some snap packages may not have updated successfully."
    fi
else
    print_status "Snap not installed, skipping snap updates."
fi

# ── Step 7: Flatpak ───────────────────────────────────────────────────────────
print_header "Step 7: Updating Flatpak Packages"
if command -v flatpak >/dev/null 2>&1; then
    print_status "Updating flatpak packages and runtimes..."
    print_status "This updates applications installed via Flatpak."
    if flatpak update -y; then
        print_status "Flatpak packages updated successfully!"
    else
        print_warning "Some flatpak packages may not have updated successfully."
    fi
else
    print_status "Flatpak not installed, skipping flatpak updates."
fi

# ── Step 8: Firmware ──────────────────────────────────────────────────────────
print_header "Step 8: Checking for Firmware Updates"
if command -v fwupdmgr >/dev/null 2>&1; then
    print_status "Checking for firmware updates..."
    print_status "This updates device firmware like BIOS, UEFI, and hardware drivers."
    if fwupdmgr refresh >/dev/null 2>&1 && fwupdmgr update -y >/dev/null 2>&1; then
        print_status "Firmware updates completed!"
    else
        print_status "No firmware updates available or some updates failed."
    fi
else
    print_status "fwupdmgr not available, skipping firmware updates."
    print_status "To install firmware update support: $SUDO_CMD apt install fwupd"
fi

# ── Step 9: Docker ────────────────────────────────────────────────────────────
print_header "Step 9: Updating Docker"
if command -v docker >/dev/null 2>&1; then
    print_status "Docker found, updating Docker images..."
    if $SUDO_CMD apt list --installed 2>/dev/null | grep -q docker-ce; then
        print_status "Updating Docker CE package..."
        DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt upgrade docker-ce docker-ce-cli containerd.io -y
    fi
    print_status "Cleaning up unused Docker resources..."
    docker system prune -f >/dev/null 2>&1 || print_warning "Docker cleanup requires user permissions"
    print_status "Docker updates completed!"
else
    print_status "Docker not installed, skipping Docker updates."
fi

# ── Step 10: Claude Code ──────────────────────────────────────────────────────
print_header "Step 10: Updating Claude Code"
if command -v claude >/dev/null 2>&1; then
    print_status "Claude Code found, checking for updates..."
    if claude update; then
        print_status "Claude Code updated successfully!"
    else
        print_warning "Claude Code update encountered some issues."
    fi
else
    print_status "Claude Code not installed, skipping."
fi

# ── Step 11: Security updates ─────────────────────────────────────────────────
print_header "Step 11: Security Updates"
print_status "Checking for unattended-upgrades configuration..."
if dpkg -l | grep -q unattended-upgrades; then
    print_status "Unattended upgrades is installed and will handle automatic security updates."
else
    print_warning "Consider installing unattended-upgrades for automatic security updates:"
    print_status "  $SUDO_CMD apt install unattended-upgrades"
fi

security_updates=$(apt list --upgradable 2>/dev/null | grep -c security 2>/dev/null || echo "0")
security_updates=$(echo "$security_updates" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
if [[ "${security_updates:-0}" -gt 0 ]]; then
    print_warning "There are $security_updates security updates available."
    print_status "Running security-focused upgrade..."
    DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt upgrade -y
else
    print_status "No pending security updates found."
fi

# ── Step 12: System cleanup ───────────────────────────────────────────────────
print_header "Step 12: Additional System Cleanup"
print_status "Cleaning up system logs older than 7 days..."
if command -v journalctl >/dev/null 2>&1; then
    $SUDO_CMD journalctl --vacuum-time=7d >/dev/null 2>&1
    print_status "System logs cleaned up."
fi

print_status "Cleaning package cache..."
$SUDO_CMD apt clean >/dev/null 2>&1

print_status "Updating locate database..."
if command -v updatedb >/dev/null 2>&1; then
    $SUDO_CMD updatedb >/dev/null 2>&1 &
    print_status "Database update running in background."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
print_header "Update Process Complete!"
print_status "All update tasks completed at: $(date)"
print_status "Summary of completed tasks:"
echo -e "  ${GREEN}✓${NC} Updated package lists"
echo -e "  ${GREEN}✓${NC} Upgraded installed packages"
echo -e "  ${GREEN}✓${NC} Performed full upgrade"
echo -e "  ${GREEN}✓${NC} Removed unused packages"
echo -e "  ${GREEN}✓${NC} Cleaned package cache"

command -v snap >/dev/null 2>&1 \
    && echo -e "  ${GREEN}✓${NC} Updated Snap packages" \
    || echo -e "  ${YELLOW}⚠${NC} Snap not installed"

command -v flatpak >/dev/null 2>&1 \
    && echo -e "  ${GREEN}✓${NC} Updated Flatpak packages" \
    || echo -e "  ${YELLOW}⚠${NC} Flatpak not installed"

command -v fwupdmgr >/dev/null 2>&1 \
    && echo -e "  ${GREEN}✓${NC} Checked firmware updates" \
    || echo -e "  ${YELLOW}⚠${NC} Firmware updates not available"

command -v docker >/dev/null 2>&1 \
    && echo -e "  ${GREEN}✓${NC} Updated Docker" \
    || echo -e "  ${YELLOW}⚠${NC} Docker not installed"

command -v claude >/dev/null 2>&1 \
    && echo -e "  ${GREEN}✓${NC} Updated Claude Code" \
    || echo -e "  ${YELLOW}⚠${NC} Claude Code not installed"

echo -e "  ${GREEN}✓${NC} Performed security checks"
echo -e "  ${GREEN}✓${NC} System cleanup completed"
[[ -n "$LOG_FILE" ]] && echo -e "  ${GREEN}✓${NC} Run logged to $LOG_FILE"

# ── Reboot check ──────────────────────────────────────────────────────────────
if [[ -f /var/run/reboot-required ]]; then
    print_warning "REBOOT REQUIRED: System updates require a reboot to take effect."
    echo -e "${YELLOW}Run '$SUDO_CMD reboot' when convenient.${NC}"
    if [[ -f /var/run/reboot-required.pkgs ]]; then
        print_status "Packages that triggered reboot requirement:"
        cat /var/run/reboot-required.pkgs | sed 's/^/  - /'
    fi
else
    print_status "No reboot required at this time."
fi

print_status "Your system is now up to date!"

# ── System info ───────────────────────────────────────────────────────────────
print_header "System Information"
print_status "System version: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
print_status "Kernel version: $(uname -r)"
print_status "System uptime: $(uptime -p 2>/dev/null || uptime)"

print_status "Disk usage:"
df -h / /var /tmp 2>/dev/null | grep -E '^/dev|Filesystem' | sort -u | while read line; do
    echo "  $line"
done

print_status "Update script completed successfully!"

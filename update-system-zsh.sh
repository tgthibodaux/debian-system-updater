#!/usr/bin/zsh

# Debian System Update Script (Zsh Version)
# This script performs a comprehensive system update including Oh My Zsh
# Last updated: May 30, 2026

# ── Logging ────────────────────────────────────────────────────────────────
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

# ── Privilege check ─────────────────────────────────────────────────────────
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

# ── Main ────────────────────────────────────────────────────────────────────
print_header "Starting System Update Process"
print_status "Script started at: $(date)"
[[ -n "$LOG_FILE" ]] && print_status "Logging to: $LOG_FILE" \
    || print_warning "Could not write to /var/log — logging to stdout only."

check_privileges

# ── Step 1: apt update (with mirror-sync retry) ─────────────────────────────
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

# ── Step 2: apt upgrade ──────────────────────────────────────────────────────
print_header "Step 2: Upgrading Installed Packages (apt upgrade)"
print_status "Upgrading all installed packages to their latest versions..."
print_status "This installs newer versions of packages you already have installed."
if DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt upgrade -y; then
    print_status "Package upgrade completed successfully!"
else
    print_warning "Some packages may not have upgraded successfully."
fi

# ── Step 3: apt full-upgrade ─────────────────────────────────────────────────
print_header "Step 3: Performing Full Upgrade (apt full-upgrade)"
print_status "Performing full upgrade with intelligent dependency handling..."
print_status "This can install new packages or remove packages if needed for upgrades."
if DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt full-upgrade -y; then
    print_status "Full upgrade completed successfully!"
else
    print_warning "Full upgrade encountered some issues."
fi

# ── Step 4: apt autoremove ───────────────────────────────────────────────────
print_header "Step 4: Removing Unused Packages (apt autoremove)"
print_status "Removing packages that were automatically installed and are no longer needed..."
print_status "This frees up disk space by removing orphaned dependencies."
if DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt autoremove -y; then
    print_status "Unused packages removed successfully!"
else
    print_warning "Autoremove encountered some issues."
fi

# ── Step 5: apt autoclean ────────────────────────────────────────────────────
print_header "Step 5: Cleaning Package Cache (apt autoclean)"
print_status "Cleaning the local package cache..."
print_status "This removes cached package files that can no longer be downloaded."
if $SUDO_CMD apt autoclean; then
    print_status "Package cache cleaned successfully!"
else
    print_warning "Autoclean encountered some issues."
fi

# ── Step 6: Oh My Zsh (with dirty-state stash) ──────────────────────────────
print_header "Step 6: Updating Oh My Zsh"
print_status "Checking for Oh My Zsh installation..."

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    print_status "Oh My Zsh found. Updating to latest version..."
    print_status "This updates your zsh configuration framework and plugins."

    current_dir=$(pwd)
    cd "$HOME/.oh-my-zsh" || { print_error "Could not access Oh My Zsh directory"; exit 1; }

    DIRTY_FILES=$(git diff --name-only 2>/dev/null)
    if [[ -n "$DIRTY_FILES" ]]; then
        print_warning "Local modifications detected in Oh My Zsh tracked files:"
        echo "$DIRTY_FILES" | sed 's/^/        /'
        print_status "Stashing local changes to allow clean update..."
        git stash push -m "auto-stash before omz update $(date +%Y%m%d-%H%M%S)"
        if git pull --rebase origin master; then
            print_status "Oh My Zsh updated successfully!"
            print_status "Discarding stashed local changes (upstream wins)."
            git stash drop
        else
            print_error "Oh My Zsh update failed even after stash. Restoring stashed changes."
            git stash pop
            print_warning "Oh My Zsh update encountered issues. You may need to update manually."
        fi
    else
        if git pull --rebase origin master; then
            print_status "Oh My Zsh updated successfully!"
        else
            print_warning "Oh My Zsh update encountered issues. You may need to update manually."
        fi
    fi

    if [[ -d "$HOME/.oh-my-zsh/custom/plugins" ]]; then
        print_status "Updating custom Oh My Zsh plugins..."
        for plugin_dir in "$HOME/.oh-my-zsh/custom/plugins"/*; do
            if [[ -d "$plugin_dir/.git" ]]; then
                plugin_name=$(basename "$plugin_dir")
                print_status "Updating plugin: $plugin_name"
                cd "$plugin_dir" && git pull
            fi
        done
    fi

    if [[ -d "$HOME/.oh-my-zsh/custom/themes" ]]; then
        print_status "Updating custom Oh My Zsh themes..."
        for theme_dir in "$HOME/.oh-my-zsh/custom/themes"/*; do
            if [[ -d "$theme_dir/.git" ]]; then
                theme_name=$(basename "$theme_dir")
                print_status "Updating theme: $theme_name"
                cd "$theme_dir" && git pull
            fi
        done
    fi

    cd "$current_dir"
else
    print_warning "Oh My Zsh not found in $HOME/.oh-my-zsh"
    print_status "If you have Oh My Zsh installed elsewhere, please update it manually."
fi

# ── Step 7: NVM / Node.js LTS / npm ─────────────────────────────────────────
print_header "Step 7: Updating NVM, Node.js, and npm"

NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -d "$NVM_DIR" ]]; then
    print_status "NVM found at $NVM_DIR. Loading environment..."
    source "$NVM_DIR/nvm.sh" 2>/dev/null || true

    if command -v nvm >/dev/null 2>&1; then
        print_status "Updating NVM itself..."
        LATEST_NVM=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null \
            | grep '"tag_name"' | cut -d'"' -f4)
        if [[ -n "$LATEST_NVM" ]]; then
            curl -s -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$LATEST_NVM/install.sh" \
                | bash >/dev/null 2>&1
            source "$NVM_DIR/nvm.sh" 2>/dev/null || true
            print_status "NVM updated to $LATEST_NVM."
        else
            print_warning "Could not determine latest NVM version. Skipping NVM self-update."
        fi

        print_status "Installing/updating Node.js LTS..."
        if nvm install --lts 2>&1; then
            nvm alias default 'lts/*' 2>/dev/null
            nvm use default 2>/dev/null
            print_status "Node.js LTS installed and set as default: $(node --version)"
        else
            print_warning "Node.js LTS update encountered issues."
        fi

        print_status "Updating npm to latest..."
        if npm install -g npm@latest >/dev/null 2>&1; then
            print_status "npm updated to $(npm --version)."
        else
            print_warning "npm self-update encountered issues."
        fi
    else
        print_warning "NVM directory found but nvm command unavailable after sourcing. Skipping."
    fi
else
    print_status "NVM not installed, skipping Node.js/npm update."
fi

# ── Step 8: pip user packages only ──────────────────────────────────────────
print_header "Step 8: Updating Python pip Packages"

PIP_CMD=""
if command -v pip3 >/dev/null 2>&1; then
    PIP_CMD="pip3"
elif command -v pip >/dev/null 2>&1; then
    PIP_CMD="pip"
fi

if [[ -n "$PIP_CMD" ]]; then
    print_status "$PIP_CMD found. Checking for outdated user-installed packages..."
    # --user scope keeps us away from apt-managed system packages entirely
    OUTDATED=$($PIP_CMD list --outdated --user --format=columns 2>/dev/null \
        | tail -n +3 | awk '{print $1}')

    if [[ -n "$OUTDATED" ]]; then
        print_status "Upgrading outdated user pip packages (single pass for clean dependency resolution)..."
        # Pass all packages at once so pip's solver handles version constraints in one shot
        # rather than thrashing dependencies package-by-package
        if $PIP_CMD install --upgrade --user $(echo "$OUTDATED" | tr '\n' ' ') 2>&1; then
            print_status "pip package updates complete."
        else
            print_warning "Some pip packages could not be upgraded."
        fi
    else
        print_status "All user pip packages are up to date."
    fi
else
    print_status "pip/pip3 not installed, skipping Python package updates."
fi

# ── Step 9: Ollama ───────────────────────────────────────────────────────────
print_header "Step 9: Updating Ollama"

if command -v ollama >/dev/null 2>&1; then
    print_status "Ollama found. Checking for updates..."
    CURRENT_OLLAMA=$(ollama --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    print_status "Current Ollama version: ${CURRENT_OLLAMA:-unknown}"
    print_status "Running Ollama self-updater..."
    if curl -fsSL https://ollama.com/install.sh | sh 2>&1; then
        NEW_OLLAMA=$(ollama --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        print_status "Ollama updated. Version now: ${NEW_OLLAMA:-unknown}"
    else
        print_warning "Ollama update encountered issues. You may need to update manually."
    fi
else
    print_status "Ollama not installed, skipping."
fi

# ── Step 10: Snap ────────────────────────────────────────────────────────────
print_header "Step 10: Updating Snap Packages"
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

# ── Step 11: Flatpak ─────────────────────────────────────────────────────────
print_header "Step 11: Updating Flatpak Packages"
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

# ── Step 12: Firmware ────────────────────────────────────────────────────────
print_header "Step 12: Checking for Firmware Updates"
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

# ── Step 13: Docker ──────────────────────────────────────────────────────────
print_header "Step 13: Updating Docker"
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

# ── Step 14: Claude Code ─────────────────────────────────────────────────────
print_header "Step 14: Updating Claude Code"
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

# ── Step 15: Security updates ────────────────────────────────────────────────
print_header "Step 15: Security Updates"
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

# ── Step 16: System cleanup ──────────────────────────────────────────────────
print_header "Step 16: Additional System Cleanup"
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

# ── Summary ──────────────────────────────────────────────────────────────────
print_header "Update Process Complete!"
print_status "All update tasks completed at: $(date)"
print_status "Summary of completed tasks:"
echo -e "  ${GREEN}✓${NC} Updated package lists"
echo -e "  ${GREEN}✓${NC} Upgraded installed packages"
echo -e "  ${GREEN}✓${NC} Performed full upgrade"
echo -e "  ${GREEN}✓${NC} Removed unused packages"
echo -e "  ${GREEN}✓${NC} Cleaned package cache"

[[ -d "$HOME/.oh-my-zsh" ]] \
    && echo -e "  ${GREEN}✓${NC} Updated Oh My Zsh" \
    || echo -e "  ${YELLOW}⚠${NC} Oh My Zsh not found/updated"

[[ -d "${NVM_DIR:-$HOME/.nvm}" ]] \
    && echo -e "  ${GREEN}✓${NC} Updated NVM / Node.js LTS / npm" \
    || echo -e "  ${YELLOW}⚠${NC} NVM not installed"

command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1 \
    && echo -e "  ${GREEN}✓${NC} Updated user pip packages" \
    || echo -e "  ${YELLOW}⚠${NC} pip not installed"

command -v ollama >/dev/null 2>&1 \
    && echo -e "  ${GREEN}✓${NC} Updated Ollama" \
    || echo -e "  ${YELLOW}⚠${NC} Ollama not installed"

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

# ── Reboot check ─────────────────────────────────────────────────────────────
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

# ── System info ──────────────────────────────────────────────────────────────
print_header "System Information"
print_status "System version: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
print_status "Kernel version: $(uname -r)"
print_status "System uptime: $(uptime -p 2>/dev/null || uptime)"

print_status "Disk usage:"
df -h / /var /tmp 2>/dev/null | grep -E '^/dev|Filesystem' | sort -u | while read line; do
    echo "  $line"
done

print_status "Update script completed successfully!"

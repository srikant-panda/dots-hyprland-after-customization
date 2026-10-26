#!/usr/bin/env bash
# ==============================================================================
# apply-customizations.sh
# ------------------------------------------------------------------------------
# Applies all custom illogical-impulse & Hyprland enhancements on top of a
# fresh dots-hyprland installation.
#
# Key Features:
# - Granular dependency checking & smart skipping of non-installed apps (e.g. VLC)
# - Interactive resolution (Retry / Ignore / Revert) for critical dependencies
# - Safety backup with 1-click automatic rollback support
# - Formatted summary table detailing what was APPLIED vs SKIPPED and WHY
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_SRC="$SCRIPT_DIR/configs/.config"
BACKUP_DIR="$HOME/ii-backups/pre-customization-backup-$(date +%Y%m%d_%H%M%S)"

# Terminal Colors
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_CYAN="\033[1;36m"
C_GRAY="\033[0;90m"

# Report Tracking Arrays
declare -a REPORT_STATUS=()
declare -a REPORT_COMPONENT=()
declare -a REPORT_DETAILS=()

record_report() {
    local status="$1"
    local component="$2"
    local details="$3"
    REPORT_STATUS+=("$status")
    REPORT_COMPONENT+=("$component")
    REPORT_DETAILS+=("$details")
}

revert_all_changes() {
    echo -e "\n${C_RED}${C_BOLD}[REVERTING] Rolling back changes from backup...${C_RESET}"
    if [ -d "$BACKUP_DIR" ]; then
        for item in quickshell/ii hypr illogical-impulse satty swappy matugen kitty gtk-3.0 gtk-4.0 xsettingsd fish; do
            if [ -d "$BACKUP_DIR/$item" ]; then
                rm -rf "$HOME/.config/$item"
                mkdir -p "$HOME/.config/$(dirname "$item")"
                cp -a "$BACKUP_DIR/$item" "$HOME/.config/$item"
            fi
        done
        if [ -f "$BACKUP_DIR/.bashrc" ]; then
            cp -f "$BACKUP_DIR/.bashrc" "$HOME/.bashrc"
        fi
        if [ -d "$BACKUP_DIR/.local" ]; then
            cp -a "$BACKUP_DIR/.local"/* "$HOME/.local/" 2>/dev/null || true
        fi
        rm -f "$HOME/.local/bin/vlc" 2>/dev/null || true
        rm -f "$HOME/.local/share/applications"/vlc*.desktop 2>/dev/null || true
        echo -e "${C_GREEN}[REVERTED] System configurations restored to safety backup at:${C_RESET}"
        echo "           $BACKUP_DIR"
    fi
    exit 1
}

# Resolve dependency with user prompt for critical dependencies or auto-skip for independent ones
# Arguments: <dep_name> <test_command> <is_critical: true/false> <component_name>
resolve_dependency() {
    local dep_name="$1"
    local test_cmd="$2"
    local is_critical="$3"
    local comp_name="$4"

    while true; do
        if eval "$test_cmd" >/dev/null 2>&1; then
            return 0 # Dependency satisfied
        fi

        if [ "$is_critical" = "false" ]; then
            # Non-critical independent component: auto-skip without error
            echo -e "      ${C_YELLOW}[SKIP]${C_RESET} '$dep_name' not found. Skipping $comp_name."
            record_report "SKIPPED" "$comp_name" "'$dep_name' not installed on this system"
            return 1
        fi

        # Critical dependent component: prompt user
        echo -e "\n${C_RED}${C_BOLD}[!] MISSING DEPENDENCY:${C_RESET} '$dep_name' is missing, but other customizations depend on it!"
        echo -e "    Component affected: ${C_BOLD}$comp_name${C_RESET}"
        echo -e "    Options:"
        echo -e "      ${C_GREEN}[r] Retry${C_RESET}  : Install '$dep_name' in another terminal, then press 'r' to re-check"
        echo -e "      ${C_YELLOW}[i] Ignore${C_RESET} : Skip $comp_name and its dependent components"
        echo -e "      ${C_RED}[b] Revert${C_RESET} : Abort and revert all changes made so far"
        
        local choice=""
        if [ -t 0 ]; then
            read -r -p "    Enter choice [r/i/b]: " choice
        elif [ -r /dev/tty ]; then
            read -r -p "    Enter choice [r/i/b]: " choice </dev/tty
        else
            echo "    Non-interactive session detected; defaulting to [i] Ignore."
            choice="i"
        fi

        case "$choice" in
            [rR]*)
                echo "    Retrying check for '$dep_name'..."
                ;;
            [bB]*)
                revert_all_changes
                ;;
            [iI]*|*)
                echo -e "    Ignoring '$dep_name'. Skipping dependent features."
                record_report "SKIPPED" "$comp_name" "Skipped by user (missing '$dep_name')"
                return 1
                ;;
        esac
    done
}

print_summary_chart() {
    echo ""
    echo "========================================================================================================================"
    echo "                                        CUSTOMIZATION DEPLOYMENT STATUS REPORT                                          "
    echo "========================================================================================================================"
    printf " %-8s | %-36s | %-68s \n" "STATUS" "COMPONENT" "DETAILS / REASON"
    echo "---------+--------------------------------------+----------------------------------------------------------------------"
    for i in "${!REPORT_STATUS[@]}"; do
        local st="${REPORT_STATUS[$i]}"
        local cp="${REPORT_COMPONENT[$i]}"
        local dt="${REPORT_DETAILS[$i]}"
        if [ "$st" = "APPLIED" ]; then
            printf " ${C_GREEN}%-8s${C_RESET} | %-36s | %-68s \n" "$st" "$cp" "$dt"
        else
            printf " ${C_YELLOW}%-8s${C_RESET} | %-36s | %-68s \n" "$st" "$cp" "$dt"
        fi
    done
    echo "========================================================================================================================"
}

echo "===================================================================="
echo "      Applying Custom Illogical-Impulse & Hyprland Enhancements     "
echo "===================================================================="

# 1. Ensure required directories exist and create safety backup
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$BACKUP_DIR"

echo "[1/6] Created safety backup of current configs to:"
echo "      $BACKUP_DIR"

# Backup existing configs if present
for item in quickshell/ii hypr illogical-impulse satty swappy matugen kitty gtk-3.0 gtk-4.0 xsettingsd fish; do
    if [ -e "$HOME/.config/$item" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$item")"
        cp -a "$HOME/.config/$item" "$BACKUP_DIR/$item"
    fi
done
if [ -f "$HOME/.bashrc" ]; then
    cp -a "$HOME/.bashrc" "$BACKUP_DIR/.bashrc"
fi
if [ -d "$HOME/.local" ]; then
    mkdir -p "$BACKUP_DIR/.local/bin" "$BACKUP_DIR/.local/share/applications"
    [ -f "$HOME/.local/bin/vlc" ] && cp -a "$HOME/.local/bin/vlc" "$BACKUP_DIR/.local/bin/vlc"
    cp -a "$HOME/.local/share/applications"/vlc*.desktop "$BACKUP_DIR/.local/share/applications/" 2>/dev/null || true
fi

# 2. Deploy Core Configurations
echo "[2/6] Applying custom configuration files..."

# Ensure ~/.config/gtk-4.0/gtk.css is never a root-owned symlink causing Permission Denied in matugen
if [ -L "$HOME/.config/gtk-4.0/gtk.css" ]; then
    rm -f "$HOME/.config/gtk-4.0/gtk.css"
fi

# Deploy Quickshell
if [ -d "$CONFIGS_SRC/quickshell" ]; then
    cp -rv "$CONFIGS_SRC/quickshell" "$HOME/.config/" >/dev/null
    record_report "APPLIED" "Quickshell Shell & Panels (ii)" "Custom M3 popups, tray overflow, & theme transitions deployed"
fi

# Deploy Hyprland configs
if [ -d "$CONFIGS_SRC/hypr" ]; then
    cp -rv "$CONFIGS_SRC/hypr" "$HOME/.config/" >/dev/null
    record_report "APPLIED" "Hyprland Configs & Lua Core" "Custom keybinds, rules, execs & scripts deployed"
fi

# Deploy GTK 3/4, xsettingsd, matugen
for cfg in gtk-3.0 gtk-4.0 xsettingsd matugen; do
    if [ -d "$CONFIGS_SRC/$cfg" ]; then
        cp -rv "$CONFIGS_SRC/$cfg" "$HOME/.config/" >/dev/null
    fi
done
record_report "APPLIED" "GTK 3/4 & Theme Synchronization" "Two-way dynamic sync configured for GTK 3, GTK 4 & xsettingsd"

# Deploy Terminal configs (Kitty, Bash, Fish)
if [ -d "$CONFIGS_SRC/kitty" ]; then
    cp -rv "$CONFIGS_SRC/kitty" "$HOME/.config/" >/dev/null
    rm -f "$HOME/.config/kitty"/*.auto.conf 2>/dev/null || true
fi
if [ -f "$SCRIPT_DIR/configs/.bashrc" ]; then
    cp -f "$SCRIPT_DIR/configs/.bashrc" "$HOME/.bashrc"
fi
if [ -d "$CONFIGS_SRC/fish" ]; then
    cp -rv "$CONFIGS_SRC/fish" "$HOME/.config/" >/dev/null
fi
record_report "APPLIED" "Terminal WCAG Contrast & Isolation" "Kitty palettes, font composition & editor terminal isolation deployed"

# 3. Optional / Independent Components (Smart Skips)

# Screenshot tools
if resolve_dependency "swappy or satty" "command -v swappy >/dev/null 2>&1 || command -v satty >/dev/null 2>&1" "false" "Screenshot Tools (swappy/satty)"; then
    [ -d "$CONFIGS_SRC/satty" ] && cp -rv "$CONFIGS_SRC/satty" "$HOME/.config/" >/dev/null
    [ -d "$CONFIGS_SRC/swappy" ] && cp -rv "$CONFIGS_SRC/swappy" "$HOME/.config/" >/dev/null
    record_report "APPLIED" "Screenshot Tools (swappy/satty)" "Configured default output save path to ~/Pictures/Screenshots"
fi

# VLC Integration (Native XDG Portal & OS Theme Following)
if resolve_dependency "vlc" "command -v vlc >/dev/null 2>&1 || [ -f /usr/bin/vlc ]" "false" "VLC Portal & Theme Follower"; then
    if [ -f "$SCRIPT_DIR/configs/.local/bin/vlc" ]; then
        cp -f "$SCRIPT_DIR/configs/.local/bin/vlc" "$HOME/.local/bin/vlc"
        chmod +x "$HOME/.local/bin/vlc"
    fi
    if [ -d "$SCRIPT_DIR/configs/.local/share/applications" ]; then
        cp -f "$SCRIPT_DIR/configs/.local/share/applications"/vlc*.desktop "$HOME/.local/share/applications/" 2>/dev/null || true
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    record_report "APPLIED" "VLC Portal & Theme Follower" "Deployed wrapper & desktop entries (Portal FileChooser + Dark/Light Sync)"
fi

# Motion Wallpapers (mpvpaper)
if resolve_dependency "mpvpaper" "command -v mpvpaper >/dev/null 2>&1" "false" "Motion Wallpapers (mpvpaper)"; then
    record_report "APPLIED" "Motion Wallpapers (mpvpaper)" "Hardware accelerated video wallpaper support enabled"
fi

# 4. Dependent / System Components (Python, HyprMod, Daemons)
echo "[3/6] Verifying system dependencies and patching HyprMod..."
HAS_PYTHON=true
if ! resolve_dependency "python3" "command -v python3 >/dev/null 2>&1" "true" "Python Daemons & HyprMod Fixes"; then
    HAS_PYTHON=false
fi

if [ "$HAS_PYTHON" = true ]; then
    # pycairo check
    if ! python3 -c "import cairo" >/dev/null 2>&1; then
        echo "      pycairo not found for python3, attempting installation..."
        pip install --break-system-packages pycairo 2>/dev/null || sudo pacman -S --needed python-cairo 2>/dev/null || true
    fi

    # Hardware daemons executable check
    chmod +x "$HOME/.config/hypr/custom/scripts"/*.py "$HOME/.config/hypr/custom/scripts"/*.sh "$HOME/.config/quickshell/ii/scripts/colors"/*.sh 2>/dev/null || true
    record_report "APPLIED" "Hardware Daemons (Lid & USB)" "handle_lid.py and handle_usb.py background daemons enabled"

    # HyprMod site-packages patching
    HYPRMOD_PATHS=$(python3 -c "import sys, site; print('\n'.join(site.getsitepackages() + [site.getusersitepackages()]))" 2>/dev/null || true)
    
    # 4a. monitor_preview.py (Vertical monitor snapping)
    FOUND_HYPRMOD=false
    for p in $HYPRMOD_PATHS; do
        TARGET_FILE="$p/hyprmod/ui/monitor_preview.py"
        if [ -f "$TARGET_FILE" ] && [ -w "$TARGET_FILE" ]; then
            cp -f "$SCRIPT_DIR/configs/hyprmod/monitor_preview.py" "$TARGET_FILE"
            FOUND_HYPRMOD=true
            break
        fi
    done
    if [ "$FOUND_HYPRMOD" = false ]; then
        for target in "$HOME"/.local/lib/python*/site-packages/hyprmod/ui/monitor_preview.py; do
            if [ -f "$target" ]; then
                cp -f "$SCRIPT_DIR/configs/hyprmod/monitor_preview.py" "$target"
                FOUND_HYPRMOD=true
                break
            fi
        done
    fi

    if [ "$FOUND_HYPRMOD" = true ]; then
        record_report "APPLIED" "HyprMod Vertical Snapping Fix" "Site-packages patched: secondary display positioning above/below unlocked"
    else
        record_report "SKIPPED" "HyprMod Vertical Snapping Fix" "'hyprmod' package not found in Python site-packages"
    fi

    # 4b. cursor.py (GTK/XDG cursor synchronization)
    FOUND_CURSOR=false
    for p in $HYPRMOD_PATHS; do
        TARGET_FILE="$p/hyprmod/pages/cursor.py"
        if [ -f "$TARGET_FILE" ] && [ -w "$TARGET_FILE" ]; then
            cp -f "$SCRIPT_DIR/configs/hyprmod/cursor.py" "$TARGET_FILE"
            FOUND_CURSOR=true
            break
        fi
    done
    if [ "$FOUND_CURSOR" = false ]; then
        for target in "$HOME"/.local/lib/python*/site-packages/hyprmod/pages/cursor.py; do
            if [ -f "$target" ]; then
                cp -f "$SCRIPT_DIR/configs/hyprmod/cursor.py" "$target"
                FOUND_CURSOR=true
                break
            fi
        done
    fi

    if [ "$FOUND_CURSOR" = true ]; then
        record_report "APPLIED" "HyprMod Cursor Synchronization Fix" "Site-packages patched: real-time GTK 3/4 and xsettingsd persistence"
    else
        record_report "SKIPPED" "HyprMod Cursor Synchronization Fix" "'hyprmod' cursor page not found in site-packages"
    fi

    # 4c. hyprland_monitors monitors.py (Unmirror bug fix)
    FOUND_UNMIRROR=false
    for p in $HYPRMOD_PATHS; do
        TARGET_FILE="$p/hyprland_monitors/monitors.py"
        if [ -f "$TARGET_FILE" ] && [ -w "$TARGET_FILE" ]; then
            cp -f "$SCRIPT_DIR/configs/hyprland_monitors/monitors.py" "$TARGET_FILE"
            FOUND_UNMIRROR=true
            break
        fi
    done
    if [ "$FOUND_UNMIRROR" = false ]; then
        for target in "$HOME"/.local/lib/python*/site-packages/hyprland_monitors/monitors.py; do
            if [ -f "$target" ]; then
                cp -f "$SCRIPT_DIR/configs/hyprland_monitors/monitors.py" "$target"
                FOUND_UNMIRROR=true
                break
            fi
        done
    fi

    if [ "$FOUND_UNMIRROR" = true ]; then
        record_report "APPLIED" "HyprMod Multi-Monitor Unmirror Fix" "Site-packages patched: emits mirror = '' to detach mirrored screens"
    else
        record_report "SKIPPED" "HyprMod Multi-Monitor Unmirror Fix" "'hyprland_monitors' package not found in site-packages"
    fi
fi

# 5. Cursor Defaults & XDG/GTK Alignment
echo "[4/6] Aligning Adwaita default cursor..."
mkdir -p "$HOME/.icons/default" "$HOME/.local/share/icons/default"
cat << 'EOF' > "$HOME/.local/share/icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Adwaita
EOF
cp -f "$HOME/.local/share/icons/default/index.theme" "$HOME/.icons/default/index.theme"
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
dconf write /org/gnome/desktop/interface/cursor-theme "'Adwaita'" 2>/dev/null || true
dconf write /org/gnome/desktop/interface/cursor-size 24 2>/dev/null || true
record_report "APPLIED" "Universal Adwaita Cursor" "Configured default cursor across Hyprland, XDG, X11 and GTK"

# 6. Reload Compositor & Desktop Shell
echo "[5/6] Reloading Hyprland..."
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

echo "[6/6] Reloading Quickshell & Syncing Theme..."
if command -v qs >/dev/null 2>&1; then
    pkill -x quickshell 2>/dev/null || true
    pkill -x qs 2>/dev/null || true
    sleep 0.5
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl repl 'hl.exec_cmd("qs -c ii -d")' >/dev/null 2>&1 || true
    else
        nohup qs -c ii -d >/dev/null 2>&1 &
        disown 2>/dev/null || true
    fi
fi

if [ -f "$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh" ]; then
    bash "$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh" --noswitch >/dev/null 2>&1 || true
fi

# 7. Print Final Status Chart
print_summary_chart

echo ""
echo -e "${C_GREEN}${C_BOLD}Customization deployment complete!${C_RESET}"

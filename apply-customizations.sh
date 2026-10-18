#!/usr/bin/env bash
# ==============================================================================
# apply-customizations.sh
# ------------------------------------------------------------------------------
# Applies all custom illogical-impulse & Hyprland enhancements on top of a
# fresh dots-hyprland installation.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_SRC="$SCRIPT_DIR/configs/.config"
BACKUP_DIR="$HOME/ii-backups/pre-customization-backup-$(date +%Y%m%d_%H%M%S)"

echo "===================================================================="
echo "      Applying Custom Illogical-Impulse & Hyprland Enhancements     "
echo "===================================================================="

# 1. Ensure required directories exist
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/.config"
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

# 2. Copy all customized config files
echo "[2/6] Applying custom configuration files..."
# Ensure ~/.config/gtk-4.0/gtk.css is never a root-owned symlink causing Permission Denied in matugen
if [ -L "$HOME/.config/gtk-4.0/gtk.css" ]; then
    rm -f "$HOME/.config/gtk-4.0/gtk.css"
fi
cp -rv "$CONFIGS_SRC"/* "$HOME/.config/"
rm -f "$HOME/.config/kitty"/*.auto.conf 2>/dev/null || true

# 3. Check and configure screenshot tools
echo "[3/6] Setting screenshot default directories to ~/Pictures/Screenshots..."
mkdir -p "$HOME/Pictures/Screenshots"

# 4. Check & fix HyprMod (Python pycairo & monitor_preview.py)
echo "[4/6] Verifying HyprMod dependencies and monitor positioning..."
if command -v python3 >/dev/null 2>&1; then
    if ! python3 -c "import cairo" >/dev/null 2>&1; then
        echo "      pycairo not found for python3, attempting installation..."
        pip install --break-system-packages pycairo 2>/dev/null || sudo pacman -S --needed python-cairo 2>/dev/null || true
    fi

    # Find hyprmod site-packages directory
    HYPRMOD_PATHS=$(python3 -c "import sys, site; print('\n'.join(site.getsitepackages() + [site.getusersitepackages()]))" 2>/dev/null || true)
    FOUND_HYPRMOD=false
    for p in $HYPRMOD_PATHS; do
        TARGET_FILE="$p/hyprmod/ui/monitor_preview.py"
        if [ -f "$TARGET_FILE" ] && [ -w "$TARGET_FILE" ]; then
            echo "      Patching $TARGET_FILE for vertical monitor snapping..."
            cp -f "$SCRIPT_DIR/configs/hyprmod/monitor_preview.py" "$TARGET_FILE"
            FOUND_HYPRMOD=true
            break
        fi
    done
    if [ "$FOUND_HYPRMOD" = false ]; then
        # Check ~/.local/lib directly
        for target in "$HOME"/.local/lib/python*/site-packages/hyprmod/ui/monitor_preview.py; do
            if [ -f "$target" ]; then
                echo "      Patching $target for vertical monitor snapping..."
                cp -f "$SCRIPT_DIR/configs/hyprmod/monitor_preview.py" "$target"
                break
            fi
        done
    fi

    # Patch hyprmod cursor.py (GTK/XDG/xsettingsd synchronization fix)
    for p in $HYPRMOD_PATHS; do
        TARGET_FILE="$p/hyprmod/pages/cursor.py"
        if [ -f "$TARGET_FILE" ] && [ -w "$TARGET_FILE" ]; then
            echo "      Patching $TARGET_FILE for GTK/XDG cursor syncing..."
            cp -f "$SCRIPT_DIR/configs/hyprmod/cursor.py" "$TARGET_FILE"
            break
        fi
    done
    for target in "$HOME"/.local/lib/python*/site-packages/hyprmod/pages/cursor.py; do
        if [ -f "$target" ]; then
            echo "      Patching $target for GTK/XDG cursor syncing..."
            cp -f "$SCRIPT_DIR/configs/hyprmod/cursor.py" "$target"
            break
        fi
    done

    # Patch hyprland_monitors (Unmirror bug fix)
    for p in $HYPRMOD_PATHS; do
        TARGET_FILE="$p/hyprland_monitors/monitors.py"
        if [ -f "$TARGET_FILE" ] && [ -w "$TARGET_FILE" ]; then
            echo "      Patching $TARGET_FILE for unmirror support..."
            cp -f "$SCRIPT_DIR/configs/hyprland_monitors/monitors.py" "$TARGET_FILE"
            break
        fi
    done
    for target in "$HOME"/.local/lib/python*/site-packages/hyprland_monitors/monitors.py; do
        if [ -f "$target" ]; then
            echo "      Patching $target for unmirror support..."
            cp -f "$SCRIPT_DIR/configs/hyprland_monitors/monitors.py" "$target"
            break
        fi
    done
fi

# Ensure default cursor theme is synchronized across XDG, X11, and GTK
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

# Ensure custom scripts are executable
chmod +x "$HOME/.config/hypr/custom/scripts"/*.py "$HOME/.config/hypr/custom/scripts"/*.sh "$HOME/.config/quickshell/ii/scripts/colors"/*.sh 2>/dev/null || true

# Verify mpvpaper dependency for motion wallpapers
if ! command -v mpvpaper >/dev/null 2>&1; then
    echo "      [Notice] mpvpaper is not installed (required for motion/video wallpapers)."
    echo "      Install with: yay -S mpvpaper"
fi

# 5. Reload Hyprland configuration
echo "[5/6] Reloading Hyprland..."
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# 6. Reload or restart Quickshell
echo "[6/6] Reloading Quickshell..."
if command -v qs >/dev/null 2>&1; then
    if pgrep -x "quickshell" >/dev/null || pgrep -x "qs" >/dev/null; then
        # Terminate running qs and launch afresh
        pkill -x quickshell 2>/dev/null || true
        pkill -x qs 2>/dev/null || true
        sleep 1
        nohup qs -c ii -d >/dev/null 2>&1 &
        disown 2>/dev/null || true
        echo "      Quickshell restarted successfully."
    else
        nohup qs -c ii -d >/dev/null 2>&1 &
        disown 2>/dev/null || true
        echo "      Quickshell started."
    fi
fi

# Refresh Material You colors and sync GTK / terminal configs
if [ -f "$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh" ]; then
    echo "      Refreshing theme palettes and syncing GTK / Terminal settings..."
    bash "$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh" --noswitch >/dev/null 2>&1 || true
fi

echo "===================================================================="
echo "  [SUCCESS] All customizations have been successfully applied!"
echo "===================================================================="
echo "Summary of applied features:"
echo "  1. Top Bar: Custom M3 Clipboard popup anchored below applet (Clear All, Private Mode, per-item delete)."
echo "  2. Top Bar: Live Network Speed monitor indicator (dynamic KB/s, MB/s, GB/s)."
echo "  3. Center Popup: Battery health indicator removed."
echo "  4. Right Sidebar: Responsive StyledFlickable layout (768p + 1080p+)."
echo "  5. Screenshots: Satty, Swappy & Snip configured to ~/Pictures/Screenshots."
echo "  6. Mouse/Touchpad: Middle-button emulation & tap enabled."
echo "  7. HyprMod: Vertical (top/bottom) monitor snapping bug fix applied."
echo "  8. HyprMod: Multi-monitor unmirror fix applied."
echo "  9. Hyprland: Multi-monitor lid behavior & clamshell auto-switching daemon."
echo " 10. Hyprland: Scratchpad window retrieval keybinds (SUPER+ALT+B, etc.)."
echo " 11. Wallpapers: Video/Motion wallpaper support in Quickshell picker & switchwall."
echo " 12. Hardware: USB Device Plug & Unplug notifier daemon (handle_usb.py)."
echo " 13. KDE Connect: File transfer and sharing status windows always open floating and centered."
echo " 14. Top Bar: Windows-style collapsible System Tray with animated chevron arrow and pin/unpin."
echo " 15. Top Bar: Responsive dynamic spacing preventing widget overlap and icon collisions."
echo " 16. Terminal Theming: Dynamic Kitty & ANSI 16 color harmony for Light & Dark modes with full WCAG contrast."
echo " 17. GTK & System Theming: Two-way automatic synchronization for GTK 3, GTK 4, xsettingsd, and Qt/KDE."
echo " 18. Top Bar: Variable-length title truncation (...) and responsive center module stability."
echo " 19. Cursor Configuration: Uniform Adwaita default with HyprMod multi-layer live syncing (Hyprland, GTK 3/4, xsettingsd, XDG)."
echo " 20. Smooth Theme Switching: Instant, rigid optimistic toggle with concurrency locking and smooth QtQuick color transitions."
echo "===================================================================="


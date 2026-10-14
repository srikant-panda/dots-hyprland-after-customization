#!/usr/bin/env bash
# ==============================================================================
# restore-original-upstream.sh
# ------------------------------------------------------------------------------
# Reverts configurations back to the untouched official illogical-impulse upstream.
# ==============================================================================

set -euo pipefail

UPSTREAM_REF="$HOME/ii-backups/official-illogical-impulse-upstream"
BACKUP_DIR="$HOME/ii-backups/pre-revert-backup-$(date +%Y%m%d_%H%M%S)"

echo "===================================================================="
echo "      Restoring Official Illogical-Impulse Upstream State           "
echo "===================================================================="

if [ ! -d "$UPSTREAM_REF" ]; then
    echo "ERROR: Upstream reference directory not found at $UPSTREAM_REF"
    exit 1
fi

mkdir -p "$BACKUP_DIR"
echo "[1/4] Created safety backup of current configs to:"
echo "      $BACKUP_DIR"

for item in quickshell/ii hypr; do
    if [ -e "$HOME/.config/$item" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$item")"
        cp -a "$HOME/.config/$item" "$BACKUP_DIR/$item"
    fi
done

echo "[2/4] Restoring upstream files..."
if [ -d "$UPSTREAM_REF/quickshell" ]; then
    cp -rf "$UPSTREAM_REF/quickshell"/* "$HOME/.config/quickshell/"
fi
if [ -d "$UPSTREAM_REF/hypr" ]; then
    cp -rf "$UPSTREAM_REF/hypr"/* "$HOME/.config/hypr/"
fi

echo "[3/4] Reloading Hyprland..."
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

echo "[4/4] Restarting Quickshell..."
if command -v qs >/dev/null 2>&1; then
    pkill -x quickshell 2>/dev/null || true
    pkill -x qs 2>/dev/null || true
    sleep 1
    nohup qs -c ii -d >/dev/null 2>&1 &
fi

echo "===================================================================="
echo "  [SUCCESS] Official upstream configuration restored!"
echo "===================================================================="

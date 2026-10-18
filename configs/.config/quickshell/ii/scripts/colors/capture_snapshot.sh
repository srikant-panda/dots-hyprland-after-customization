#!/usr/bin/env bash
# capture_snapshot.sh: captures sub-50ms snapshots of all monitors for the circular reveal transition
SNAPSHOT_DIR="/tmp/quickshell/media/theme_snapshots"
mkdir -p "$SNAPSHOT_DIR"

TS="${1:-$(date +%s%N)}"

# Get cursor position from Hyprland
CURSOR_JSON=$(hyprctl cursorpos -j 2>/dev/null || echo '{"x":960,"y":540}')
cx=$(echo "$CURSOR_JSON" | jq -r '.x // 960')
cy=$(echo "$CURSOR_JSON" | jq -r '.y // 540')

# Capture each active monitor in parallel using grim with JPEG compression
pids=()
if command -v grim >/dev/null 2>&1; then
    monitors=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | .name' 2>/dev/null)
    if [[ -z "$monitors" ]]; then
        grim -t jpeg -q 82 "$SNAPSHOT_DIR/default_${TS}.jpg" 2>/dev/null &
        pids+=($!)
    else
        for mon in $monitors; do
            grim -t jpeg -q 82 -o "$mon" "$SNAPSHOT_DIR/${mon}_${TS}.jpg" 2>/dev/null &
            pids+=($!)
        done
    fi

    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
else
    echo '{"error":"grim_not_found"}' >&2
    exit 1
fi

echo "{\"x\":$cx,\"y\":$cy,\"ts\":\"$TS\"}"
exit 0

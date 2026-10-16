# Illogical-Impulse & Hyprland Customizations Backup

This bundle contains all your personal customizations, bug fixes, and enhancements for **illogical-impulse / dots-hyprland**.

If you ever reinstall your system or re-clone `dots-hyprland`, you can re-apply all your customizations instantly with a single command.

---

## ⚡ 1-Step Quick Restore

After installing the base `dots-hyprland` dotfiles on a fresh system, run:

```bash
bash ~/dots-customizations/apply-customizations.sh
```

*(Or `./apply-customizations.sh` from inside this directory)*

### What the restore script does automatically:
1. **Creates a timestamped safety backup** of your existing configurations in `~/ii-backups/` before touching anything.
2. **Applies all custom configuration files** to `~/.config/`.
3. **Ensures `~/Pictures/Screenshots` directory exists**.
4. **Verifies and installs HyprMod fixes** (`pycairo` support and the vertical monitor preview snapping bug fix).
5. **Reloads Hyprland and restarts Quickshell** seamlessly.

---

## 📦 What Customizations Are Included?

### 1. Top Bar Clipboard Applet & Custom M3 Popup
- **Files:**
  - `~/.config/quickshell/ii/modules/ii/bar/ClipboardButton.qml`
  - `~/.config/quickshell/ii/modules/ii/bar/ClipboardPopup.qml` (Custom M3 Popup)
  - `~/.config/quickshell/ii/services/Cliphist.qml`
  - `~/.config/quickshell/ii/modules/ii/overview/Overview.qml`
  - `~/.config/hypr/hyprland/execs.lua`
- **Features:**
  - Replaces default center overview search with an authentic Material 3 dropdown popup anchored directly below the top-bar clipboard button (matching KDE Connect style).
  - **Private Mode Toggle:** One-click toggle (with shield icon/badge) that temporarily disables saving copied items to cliphist history (`/tmp/cliphist_private_mode` guard).
  - **Clear All:** Two-step confirmation wipe button (`delete_sweep`) to clear the entire clipboard history instantly.
  - **Individual Item Deletion:** Instant delete button per clipboard item with 0ms optimistic removal.
  - **Search & Filter:** Live fuzzy search with filter chips (`All`, `Text`, `Images` with thumbnail previews).
  - **Global Keybind:** `SUPER + V` opens this custom popup anchored below the bar button.

### 2. Battery Popup
- **File:** `~/.config/quickshell/ii/modules/ii/bar/BatteryPopup.qml`
- **Features:** Clean battery percentage, charging status, and remaining time with the battery health indicator cleanly removed.

### 3. Right Sidebar Responsiveness (768p & 1080p+)
- **Files:**
  - `~/.config/quickshell/ii/modules/ii/sidebarRight/SidebarRightContent.qml`
  - `~/.config/quickshell/ii/modules/ii/sidebarRight/CenterWidgetGroup.qml`
  - `~/.config/quickshell/ii/modules/ii/sidebarRight/notifications/NotificationList.qml`
- **Features:**
  - Preserves `SystemButtonRow` pinned at the top.
  - Dynamically adapts between tall screens (1080p+) and short screens (1366x768).
  - Smooth vertical `StyledFlickable` touchpad/mouse scrolling when height is constrained.
  - Completely eliminates widget collision, squishing, and overlapping.
  - Anchors notification placeholder cleanly above notification status buttons.

### 4. Screenshot Save Path Configuration
- **Files:**
  - `~/.config/swappy/config` (`save_dir = ~/Pictures/Screenshots`)
  - `~/.config/satty/config.toml` (`save-dir = ~/Pictures/Screenshots`)
  - `~/.config/illogical-impulse/config.json` (`screenSnip.savePath = ~/Pictures/Screenshots`)
- **Features:** Both Super+Shift+S region snip and full screen snips save to `~/Pictures/Screenshots`.

### 5. Mouse & Touchpad Middle-Click Emulation
- **File:** `~/.config/hypr/hyprland-gui.lua`
- **Features:** `input.touchpad.middle_button_emulation = true` enables middle-click by pressing both left and right buttons simultaneously.

### 6. HyprMod Dual-Monitor Snapping & Layout
- **File:** `~/.local/lib/python3.14/site-packages/hyprmod/ui/monitor_preview.py`
- **Features:** Fixed the drag-and-drop collision bug in HyprMod that blocked vertical monitor positioning, allowing monitor placement above/below (e.g. secondary monitor above laptop screen).

### 7. Hyprlock 12-Hour Clock
- **File:** `~/.config/hypr/hyprlock.conf`
- **Features:** Configured lockscreen clock to 12-hour format (`$TIME12`).

### 8. HyprMod Multi-Monitor Unmirror Fix
- **File:** `~/.local/lib/python3.14/site-packages/hyprland_monitors/monitors.py`
- **Features:** Solved Hyprland 0.56.2 additive monitor mirroring issue where turning off mirroring in HyprMod did not release the mirror. Emits `mirror = ""` to explicitly detach mirrored displays.

### 9. Multi-Monitor Laptop Lid & Clamshell Management
- **Files:**
  - `~/.config/hypr/custom/scripts/handle_lid.py`
  - `~/.config/hypr/custom/keybinds.lua` (`switch:on:Lid Switch` & `switch:off:Lid Switch`)
  - `~/.config/hypr/custom/execs.lua` (autostart hotplug daemon)
- **Features:**
  - **State A (Lid Open + External):** Restores both internal and external displays at user's configured positions (`0x0` and `320x-768`), restoring primary focus.
  - **State B (Lid Closed + External):** Clamshell mode; cleanly disables laptop internal panel and makes external monitor the sole active primary display at `0x0`.
  - **State C (External Disconnected):** Laptop-only fallback; guarantees internal display remains enabled at `0x0`.
  - **State D (Hotplug while Closed):** Seamlessly enables external monitor as primary at `0x0`.
  - **Fail-safe & Safe:** Exclusive file locking (`/tmp/hypr_lid_monitor.lock`), 400ms event debouncing, zero touch of system power/logind/suspend settings.

### 10. Cross-Workspace Window Cycling (Alt+Tab & Super+Tab)
- **File:** `~/.config/hypr/custom/keybinds.lua`
- **Keys:** `ALT + Tab` / `SUPER + Tab` (Forward), `ALT + SHIFT + Tab` / `SUPER + SHIFT + Tab` (Backward)
- **Features:**
  - Cycles active focus through all windows across all workspaces and monitors irrespective of workspace boundaries.
  - Uses native MRU (Most Recently Used) focus history ordering.
  - Quick Alt+Tab toggles between the two most recently used windows.
  - Holding and pressing Tab repeatedly cycles through all open windows in sequence.
  - Microsecond latency directly executed in Hyprland's Lua core.

### 11. Motion & Video Wallpaper Support
- **Files:**
  - `~/.config/quickshell/ii/services/Wallpapers.qml`
  - `~/.config/quickshell/ii/modules/common/Images.qml`
  - `~/.config/quickshell/ii/modules/ii/wallpaperSelector/WallpaperDirectoryItem.qml`
  - `~/.config/quickshell/ii/modules/common/widgets/ThumbnailImage.qml`
  - `~/.config/quickshell/ii/scripts/colors/switchwall.sh`
- **Features:**
  - Enables motion/video wallpapers (`.mp4`, `.webm`, `.mkv`, `.avi`, `.mov`) in Quickshell's GUI wallpaper selector.
  - Automatic thumbnail extraction using `ffmpeg` for video files in the wallpaper browser.
  - Distinct video badge icon on motion wallpaper thumbnails in the picker.
  - Seamless integration with `mpvpaper` (hardware accelerated playback on Wayland), with automatic transparency for Quickshell background layer.
  - Dynamic Material You theming extracted from video frames via `matugen`.
  - Updated `switchwall.sh` dependency helper to install `mpvpaper` from Arch AUR via `yay`.

### 12. USB Device Plug & Unplug Notifier
- **Files:**
  - `~/.config/hypr/custom/scripts/handle_usb.py`
  - `~/.config/hypr/custom/execs.lua`
- **Features:**
  - Monitors udev hardware events directly in real-time.
  - Automatically sends native desktop notifications via `notify-send` when any USB device (flash drive, mouse, keyboard, phone, controller) is connected or disconnected.
  - Intelligently filters out internal Linux Foundation root hubs and initial boot devices to prevent spam.
  - Formats clean device names and chooses appropriate icons (`drive-removable-media-usb`, `input-mouse`, `audio-card`).
  - Restores the missing USB plug/unplug notification functionality that was lost when transitioning away from KDE Plasma.

---

## 🗂 Directory Structure

```
dots-customizations/
├── README.md                      # This documentation
├── apply-customizations.sh        # 1-click restore script
├── restore-original-upstream.sh   # Revert to clean official upstream state
├── configs/                       # Raw customized configuration files
│   ├── .config/
│   │   ├── hypr/                  # Hyprland & HyprMod configs
│   │   ├── illogical-impulse/     # Screen snip configs
│   │   ├── quickshell/            # Quickshell UI mods
│   │   ├── satty/                 # Satty config
│   │   └── swappy/                # Swappy config
│   └── hyprmod/
│       └── monitor_preview.py      # HyprMod python bug fix
├── patches/                        # Unified diffs against upstream
│   ├── hyprland.patch
│   └── quickshell.patch
└── archive/
    └── customizations-backup.tar.gz # Single compressed portable archive
```

---

## 🔄 How to Revert to Official Upstream State

If you ever want to revert everything back to the untouched official upstream state:

```bash
bash ~/dots-customizations/restore-original-upstream.sh
```

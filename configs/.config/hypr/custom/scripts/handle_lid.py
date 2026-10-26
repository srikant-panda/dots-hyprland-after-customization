#!/usr/bin/env python3
"""
handle_lid.py - Hyprland Multi-Monitor Lid & Hotplug Management
---------------------------------------------------------------
Implements automatic monitor layout switching based on laptop lid state
and external display hotplug events.

Supports:
  State A: Lid open with external monitor connected (Dual-display arrangement restored)
  State B: Lid closed with external monitor connected (Clamshell mode: internal disabled, external at 0x0)
  State C: External monitor disconnected (Internal display always enabled at 0x0)
  State D: External monitor connected while lid is closed (External becomes sole active display at 0x0)

Strictly controls display layout only. Does NOT touch power management, suspend, or sleep.
"""

import sys
import os
import glob
import json
import time
import fcntl
import socket
import select
import logging
import argparse
import subprocess
from pathlib import Path

LOG_FILE = "/tmp/hypr_lid_monitor.log"
LOCK_FILE = "/tmp/hypr_lid_monitor.lock"
SAVED_CONFIG = Path.home() / ".config/hypr/hyprland-gui.lua"

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)

def log_and_print(msg: str):
    logging.info(msg)
    print(msg)


def is_on_ac() -> bool:
    """Check if the system is currently connected to AC mains power."""
    try:
        ps_path = "/sys/class/power_supply"
        if os.path.exists(ps_path):
            for dev in os.listdir(ps_path):
                type_file = os.path.join(ps_path, dev, "type")
                online_file = os.path.join(ps_path, dev, "online")
                if os.path.exists(type_file) and os.path.exists(online_file):
                    with open(type_file, "r") as tf:
                        dev_type = tf.read().strip()
                    if dev_type in ("Mains", "USB_C", "USB"):
                        with open(online_file, "r") as of:
                            if of.read().strip() == "1":
                                return True
    except Exception as e:
        log_and_print(f"Error checking AC status: {e}")
    return False


def get_lid_power_action(on_ac: bool) -> str:
    """Read configured lid close action for single integrated display from config.json."""
    config_file = Path.home() / ".config/illogical-impulse/config.json"
    power_cfg = {}
    if config_file.exists():
        try:
            with open(config_file, "r") as f:
                data = json.load(f)
                power_cfg = data.get("power", {})
        except Exception as e:
            log_and_print(f"Error reading power config: {e}")

    if on_ac:
        # Normal power level (plugged into AC)
        return power_cfg.get("lidActionAc", "lock")
    else:
        # Low power level (on battery)
        return power_cfg.get("lidActionBattery", "suspend")


def hypr_eval(code: str) -> str:
    """Execute Lua code in Hyprland via hyprctl repl."""
    try:
        res = subprocess.run(
            ["hyprctl", "repl", code],
            capture_output=True,
            text=True,
            timeout=5,
        )
        output = res.stdout.strip()
        if res.returncode != 0:
            logging.error(f"hypr_eval error ({res.returncode}): {res.stderr.strip()}")
        return output
    except Exception as e:
        logging.error(f"hypr_eval exception: {e}")
        return ""


def get_hypr_monitors() -> list[dict]:
    """Fetch all monitors (active and inactive) from Hyprland."""
    try:
        res = subprocess.run(
            ["hyprctl", "monitors", "all", "-j"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if res.returncode == 0:
            return json.loads(res.stdout)
    except Exception as e:
        logging.error(f"Failed to get monitors from hyprctl: {e}")
    return []


def get_drm_connectors() -> dict[str, str]:
    """Inspect /sys/class/drm/*/status for real hardware connection status."""
    connectors = {}
    for p in glob.glob("/sys/class/drm/*/status"):
        # e.g. /sys/class/drm/card1-eDP-1/status
        port_dir = os.path.basename(os.path.dirname(p))
        port = port_dir.partition("-")[-1]  # 'eDP-1', 'HDMI-A-1'
        try:
            with open(p, "r") as f:
                connectors[port] = f.read().strip()
        except OSError:
            pass
    return connectors


def get_lid_state() -> str:
    """Read hardware lid switch state from /proc/acpi/button/lid/*/state."""
    for p in glob.glob("/proc/acpi/button/lid/*/state"):
        try:
            with open(p, "r") as f:
                content = f.read().lower()
                if "closed" in content:
                    return "closed"
                elif "open" in content:
                    return "open"
        except OSError:
            pass
    return "open"


def parse_saved_monitor_config() -> dict[str, dict]:
    """Parse monitor preferences from hyprland-gui.lua to preserve user config."""
    saved = {}
    if not SAVED_CONFIG.exists():
        return saved

    try:
        content = SAVED_CONFIG.read_text()
        # Find hl.monitor({ ... }) blocks
        import re
        pattern = re.compile(r"hl\.monitor\(\s*\{([^}]+)\}\s*\)", re.MULTILINE)
        for match in pattern.finditer(content):
            block = match.group(1)
            mon_data = {}
            for line in block.splitlines():
                line = line.strip().rstrip(",")
                if "=" in line:
                    k, _, v = line.partition("=")
                    k = k.strip()
                    v = v.strip().strip('"').strip("'")
                    mon_data[k] = v
            output = mon_data.get("output", "")
            if output:
                saved[output] = mon_data
    except Exception as e:
        logging.error(f"Error parsing saved monitor config: {e}")
    return saved


def get_saved_monitor_setting(mon: dict, saved_configs: dict[str, dict]) -> dict:
    """Retrieve saved settings for a monitor by name or description."""
    if not mon:
        return {}
    name = mon.get("name", "")
    desc = mon.get("description", "")
    if name in saved_configs:
        return saved_configs[name]
    if desc and f"desc:{desc}" in saved_configs:
        return saved_configs[f"desc:{desc}"]
    for k, v in saved_configs.items():
        if k.startswith("desc:") and k[5:] in desc:
            return v
    return {}


def classify_monitors(hypr_mons: list[dict], drm_status: dict[str, str]) -> tuple[dict | None, list[dict]]:
    """Dynamically distinguish between the internal panel and external display(s)."""
    internal = None
    external = []

    for m in hypr_mons:
        name = m.get("name", "")
        # Internal panels typically match eDP-*, LVDS-*, DSI-*
        is_internal_name = name.startswith("eDP") or name.startswith("LVDS") or name.startswith("DSI")
        status = drm_status.get(name, "connected" if not m.get("disabled") else "unknown")

        if is_internal_name:
            internal = m
        else:
            # Check if physically connected or enabled in Hyprland
            if status == "connected" or not m.get("disabled"):
                external.append(m)

    # If internal wasn't in hyprctl monitors for some reason, check DRM
    if not internal:
        for port, status in drm_status.items():
            if (port.startswith("eDP") or port.startswith("LVDS") or port.startswith("DSI")) and status == "connected":
                internal = {"name": port, "disabled": True, "width": 1920, "height": 1080, "refreshRate": 60.0}
                break

    return internal, external


def apply_profile(lid_event: str | None = None):
    """Evaluate monitors and lid state, then apply the correct profile atomically."""
    # Ensure exclusive execution via non-blocking file lock
    lock_fd = open(LOCK_FILE, "w")
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        log_and_print("Another monitor update is already in progress. Skipping.")
        return

    try:
        # Determine current lid state
        hardware_lid = get_lid_state()
        if lid_event in ("close", "closed"):
            lid_state = "closed"
        elif lid_event in ("open", "opened"):
            lid_state = "open"
        else:
            lid_state = hardware_lid

        hypr_mons = get_hypr_monitors()
        drm_status = get_drm_connectors()
        saved_configs = parse_saved_monitor_config()

        internal, external = classify_monitors(hypr_mons, drm_status)
        int_name = internal["name"] if internal else "eDP-1"

        has_external = len(external) > 0
        log_and_print(f"Lid State: {lid_state} (Hardware: {hardware_lid}) | Internal: {int_name} | External connected: {[e['name'] for e in external]}")

        # Lookup saved parameters for internal monitor
        saved_int = get_saved_monitor_setting(internal, saved_configs) if internal else {}
        int_mode = saved_int.get("mode", f"{internal.get('width', 1920)}x{internal.get('height', 1080)}@{internal.get('refreshRate', 60.0):.2f}Hz") if internal else "1920x1080@60.01Hz"
        int_pos = saved_int.get("position", "0x0")
        int_scale = saved_int.get("scale", str(internal.get("scale", 1))) if internal else "1"

        if has_external and lid_state == "closed":
            # -------------------------------------------------------------
            # State B / State D: Clamshell Mode (Lid closed, external connected)
            # -------------------------------------------------------------
            log_and_print("Applying State B/D: Clamshell profile (Internal disabled, external sole active at 0x0)")
            lua_commands = []

            # Enable primary external monitor starting at 0x0
            primary_ext = external[0]["name"]
            saved_ext = get_saved_monitor_setting(external[0], saved_configs)
            ext_mode = saved_ext.get("mode", f"{external[0].get('width', 1366)}x{external[0].get('height', 768)}@{external[0].get('refreshRate', 60.0):.2f}Hz")
            ext_scale = saved_ext.get("scale", str(external[0].get("scale", 1)))

            lua_commands.append(
                f'hl.monitor({{ output = "{primary_ext}", disabled = false, mode = "{ext_mode}", position = "0x0", scale = {ext_scale}, mirror = "" }})'
            )

            # Disable internal display
            lua_commands.append(f'hl.monitor({{ output = "{int_name}", disabled = true }})')

            # Any secondary external displays
            for ext in external[1:]:
                e_name = ext["name"]
                s_ext = get_saved_monitor_setting(ext, saved_configs)
                e_mode = s_ext.get("mode", f"{ext.get('width', 1920)}x{ext.get('height', 1080)}@{ext.get('refreshRate', 60.0):.2f}Hz")
                e_pos = s_ext.get("position", "auto")
                e_scale = s_ext.get("scale", str(ext.get("scale", 1)))
                lua_commands.append(
                    f'hl.monitor({{ output = "{e_name}", disabled = false, mode = "{e_mode}", position = "{e_pos}", scale = {e_scale}, mirror = "" }})'
                )

            # Switch focus to the external monitor
            lua_commands.append(f'hl.dispatch(hl.dsp.focus({{ monitor = "{primary_ext}" }}))')

            hypr_eval("\n".join(lua_commands))

        elif has_external and lid_state == "open":
            # -------------------------------------------------------------
            # State A: Dual Monitor Mode (Lid open, external connected)
            # -------------------------------------------------------------
            log_and_print("Applying State A: Multi-monitor profile (Both internal & external enabled at configured layout)")
            lua_commands = []

            # Enable internal display at original position
            lua_commands.append(
                f'hl.monitor({{ output = "{int_name}", disabled = false, mode = "{int_mode}", position = "{int_pos}", scale = {int_scale}, mirror = "" }})'
            )

            # Enable external monitor(s) at their configured multi-monitor positions
            for ext in external:
                e_name = ext["name"]
                s_ext = get_saved_monitor_setting(ext, saved_configs)
                e_mode = s_ext.get("mode", f"{ext.get('width', 1366)}x{ext.get('height', 768)}@{ext.get('refreshRate', 60.0):.2f}Hz")
                e_scale = s_ext.get("scale", str(ext.get("scale", 1)))
                e_mirror = s_ext.get("mirror", "")

                # If mirror is configured in hyprland-gui.lua, preserve it
                if e_mirror:
                    lua_commands.append(
                        f'hl.monitor({{ output = "{e_name}", disabled = false, mode = "{e_mode}", scale = {e_scale}, mirror = "{e_mirror}" }})'
                    )
                else:
                    # Non-mirrored position
                    e_pos = s_ext.get("position", f"{ext.get('x', 320)}x{ext.get('y', -768)}")
                    # Guard against accidental 0x0 overlap with internal display when unmirrored
                    if e_pos == "0x0" and int_pos == "0x0":
                        e_pos = "320x-768"
                    lua_commands.append(
                        f'hl.monitor({{ output = "{e_name}", disabled = false, mode = "{e_mode}", position = "{e_pos}", scale = {e_scale}, mirror = "" }})'
                    )

            # Focus primary monitor (internal)
            lua_commands.append(f'hl.dispatch(hl.dsp.focus({{ monitor = "{int_name}" }}))')

            hypr_eval("\n".join(lua_commands))

        elif not has_external and lid_state == "closed":
            # -------------------------------------------------------------
            # State E: Single display (integrated monitor only) with lid closed
            # -------------------------------------------------------------
            on_ac = is_on_ac()
            power_level_name = "AC/Normal" if on_ac else "Battery/Low Power"
            action = get_lid_power_action(on_ac).lower().strip()
            log_and_print(f"Applying State E: Single display lid closed. Power level: {power_level_name}, Action: '{action}'")

            if action == "suspend":
                log_and_print("Executing system suspend...")
                subprocess.Popen(["bash", "-c", "systemctl suspend || loginctl suspend"])
            elif action == "lock":
                log_and_print("Executing screen lock...")
                subprocess.Popen(["loginctl", "lock-session"])
                hypr_eval(f'hl.dispatch(hl.dsp.dpms({{ action = "disable" }}))')
            else:
                log_and_print("Lid action is 'nothing' or 'ignore'. Display and session remain active.")

        else:
            # -------------------------------------------------------------
            # State C: Laptop-only Mode (External disconnected or lid open without external)
            # -------------------------------------------------------------
            log_and_print("Applying State C: Single display profile (Internal display enabled at 0x0)")
            lua_commands = [
                f'hl.monitor({{ output = "{int_name}", disabled = false, mode = "{int_mode}", position = "0x0", scale = {int_scale}, mirror = "" }})',
                f'hl.dispatch(hl.dsp.dpms({{ action = "enable" }}))',
                f'hl.dispatch(hl.dsp.focus({{ monitor = "{int_name}" }}))',
            ]
            hypr_eval("\n".join(lua_commands))

        log_and_print("Profile successfully applied.")

    finally:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
            lock_fd.close()
        except OSError:
            pass


def run_daemon():
    """Background listener for Hyprland's socket2 to handle hotplug events."""
    pid_file = "/tmp/hypr_lid_daemon.pid"
    if os.path.exists(pid_file):
        try:
            with open(pid_file, "r") as f:
                old_pid = int(f.read().strip())
            os.kill(old_pid, 0)
            log_and_print(f"Daemon already running with PID {old_pid}. Exiting.")
            return
        except (OSError, ValueError):
            pass

    try:
        with open(pid_file, "w") as f:
            f.write(str(os.getpid()))
    except OSError:
        pass

    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")

    if not sig:
        sockets = sorted(glob.glob(f"{xdg_runtime}/hypr/*/.socket2.sock"), key=os.path.getmtime, reverse=True)
        if sockets:
            sock_path = sockets[0]
            sig = os.path.basename(os.path.dirname(sock_path))
            os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = sig
        else:
            sock_path = f"{xdg_runtime}/hypr/{sig}/.socket2.sock"
    else:
        sock_path = f"{xdg_runtime}/hypr/{sig}/.socket2.sock"

    log_and_print(f"Starting monitor hotplug listener daemon on {sock_path}...")

    # Run initial check to sync state at startup
    apply_profile()

    while True:
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(sock_path)
            log_and_print("Connected to Hyprland socket2. Listening for hotplug events...")

            buffer = ""
            last_event_time = 0.0

            while True:
                ready, _, _ = select.select([s], [], [], 10.0)
                if not ready:
                    continue

                chunk = s.recv(4096).decode("utf-8", errors="ignore")
                if not chunk:
                    break

                buffer += chunk
                while "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    line = line.strip()
                    if not line:
                        continue

                    # Only respond to physical hardware monitor addition or removal
                    if (
                        line.startswith("monitoradded>>")
                        or line.startswith("monitorremoved>>")
                    ):
                        now = time.time()
                        if now - last_event_time > 0.4:  # 400ms debounce
                            last_event_time = now
                            log_and_print(f"Hotplug event detected: {line}")
                            time.sleep(0.3)  # Allow DRM to settle
                            apply_profile()

        except (socket.error, OSError) as e:
            logging.warning(f"Socket disconnected or error: {e}. Reconnecting in 3s...")
            time.sleep(3)


def main():
    parser = argparse.ArgumentParser(description="Hyprland Multi-Monitor Lid & Hotplug Manager")
    parser.add_argument("action", choices=["open", "close", "update", "check", "daemon", "status"], nargs="?", default="update")
    args = parser.parse_args()

    if args.action == "daemon":
        run_daemon()
    elif args.action == "status":
        hypr_mons = get_hypr_monitors()
        drm_status = get_drm_connectors()
        lid = get_lid_state()
        internal, external = classify_monitors(hypr_mons, drm_status)
        print("=== Multi-Monitor Lid Status ===")
        print(f"Lid State: {lid}")
        print(f"Internal Monitor: {internal['name'] if internal else 'None'}")
        print(f"External Monitors: {[e['name'] for e in external]}")
        print("Hyprland Monitors JSON:")
        print(json.dumps(hypr_mons, indent=2))
    elif args.action in ("open", "close"):
        apply_profile(lid_event=args.action)
    else:
        apply_profile()


if __name__ == "__main__":
    main()

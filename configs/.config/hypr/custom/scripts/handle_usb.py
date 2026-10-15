#!/usr/bin/env python3
"""
handle_usb.py - System Notifications for USB Device Plug & Unplug
----------------------------------------------------------------
Emulates the native KDE Plasma / System Notifications daemon for Hyprland.
Monitors udev in real-time and issues "USB Device Detected" and
"USB Device Removed" notifications with authentic audio feedback.
"""

import sys
import os
import glob
import fcntl
import signal
import subprocess

LOCK_FILE = "/tmp/hypr_usb_monitor.lock"

def get_initial_usb_devices():
    """Scan existing USB devices to avoid false notifications on startup."""
    devices = {}
    for devpath in glob.glob("/sys/bus/usb/devices/*"):
        basename = os.path.basename(devpath)
        if ":" in basename:
            continue
        vid_file = os.path.join(devpath, "idVendor")
        prod_file = os.path.join(devpath, "product")
        mfr_file = os.path.join(devpath, "manufacturer")
        if os.path.exists(vid_file):
            try:
                with open(vid_file) as f:
                    vid = f.read().strip()
                if vid == "1d6b":  # Skip Linux Foundation root hubs
                    continue
                name = ""
                if os.path.exists(prod_file):
                    with open(prod_file) as f:
                        name = f.read().strip()
                if not name and os.path.exists(mfr_file):
                    with open(mfr_file) as f:
                        name = f.read().strip()
                devices[basename] = name or "USB Device"
            except Exception:
                pass
    return devices

def send_notification(summary: str, body: str, icon: str = "drive-removable-media-usb", sound: str = None):
    try:
        cmd = [
            "notify-send",
            "-a", "System Notifications",
            "-i", icon,
            summary,
            body,
            "-u", "normal"
        ]
        if sound:
            cmd.extend(["-h", f"string:sound-name:{sound}"])
        subprocess.run(cmd, check=False)
        if sound:
            subprocess.Popen(["canberra-gtk-play", "-i", sound], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def process_event(event: dict, devices: dict):
    subsys = event.get("SUBSYSTEM", "")
    devtype = event.get("DEVTYPE", "")

    if subsys != "usb" or devtype != "usb_device":
        return

    vid = event.get("ID_VENDOR_ID", "")
    if vid == "1d6b":  # Skip root hubs
        return

    action = event.get("ACTION")
    devpath = event.get("DEVPATH", "")
    dev_key = os.path.basename(devpath) if devpath else event.get("DEVNAME", "")

    # Clean display name
    name = (
        event.get("ID_MODEL_FROM_DATABASE")
        or event.get("ID_MODEL")
        or event.get("PRODUCT_NAME")
    )
    mfr = event.get("ID_VENDOR_FROM_DATABASE") or event.get("ID_VENDOR", "")
    if not name:
        name = f"{mfr}".strip() or "USB Device"
    elif mfr and mfr.lower() not in name.lower() and not name.lower().startswith(mfr.lower()):
        name = f"{mfr} {name}"
    name = " ".join(name.replace("_", " ").split())

    # Determine icon
    driver = event.get("ID_USB_DRIVER", "")
    icon = "drive-removable-media-usb"
    if "storage" in driver or "mass-storage" in driver:
        icon = "drive-removable-media-usb"
    elif "input" in subsys or "hid" in driver:
        icon = "input-mouse"
    elif "sound" in subsys or "audio" in driver:
        icon = "audio-card"

    if action == "add":
        devices[dev_key] = name
        send_notification("USB Device Detected", f"{name} has been connected.", icon, "device-added")
    elif action == "remove":
        removed_name = devices.pop(dev_key, name)
        send_notification("USB Device Removed", f"{removed_name} has been disconnected.", icon, "device-removed")

def run_monitor():
    lock_fd = open(LOCK_FILE, "w")
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print("[handle_usb] Another instance is already running. Exiting.")
        sys.exit(0)

    devices = get_initial_usb_devices()

    cmd = ["udevadm", "monitor", "--udev", "--environment", "--subsystem-match=usb"]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)

    def handle_sig(sig, frame):
        proc.terminate()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_sig)
    signal.signal(signal.SIGTERM, handle_sig)

    current_event = {}
    for line in proc.stdout:
        line = line.strip()
        if not line:
            if current_event:
                process_event(current_event, devices)
                current_event = {}
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            current_event[k] = v

if __name__ == "__main__":
    run_monitor()

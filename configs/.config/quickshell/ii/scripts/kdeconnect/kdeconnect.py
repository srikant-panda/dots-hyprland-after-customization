#!/usr/bin/env python3
import sys
import os
import json
import time
import urllib.parse
import subprocess
from pathlib import Path

STATE_DIR = Path.home() / ".local/state/quickshell/user/generated"
SHARES_FILE = STATE_DIR / "kdeconnect_shares.json"

def ensure_state_dir():
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    if not SHARES_FILE.exists():
        with open(SHARES_FILE, "w") as f:
            json.dump([], f)

def load_shares():
    ensure_state_dir()
    try:
        with open(SHARES_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return []

def save_shares(shares):
    ensure_state_dir()
    try:
        with open(SHARES_FILE, "w") as f:
            json.dump(shares, f, indent=2)
    except Exception as e:
        print(f"Error saving shares: {e}", file=sys.stderr)

def format_size(bytes_num):
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes_num < 1024.0:
            return f"{bytes_num:.1f} {unit}" if unit != 'B' else f"{int(bytes_num)} B"
        bytes_num /= 1024.0
    return f"{bytes_num:.1f} TB"

def get_status():
    devices = []
    available = False
    connected = False

    # Check if kdeconnectd is running / qdbus6 responds
    try:
        out = subprocess.check_output(
            ['qdbus6', 'org.kde.kdeconnect', '/modules/kdeconnect', 'org.kde.kdeconnect.daemon.devices', 'true', 'true'],
            stderr=subprocess.DEVNULL, timeout=2.0
        ).decode().strip()
        available = True
        device_ids = [d.strip() for d in out.splitlines() if d.strip()]
    except Exception:
        # Fallback to checking kdeconnect-cli
        try:
            cli_out = subprocess.check_output(['kdeconnect-cli', '-a', '--id-only'], stderr=subprocess.DEVNULL, timeout=2.0).decode().strip()
            available = True
            device_ids = [d.strip() for d in cli_out.splitlines() if d.strip()]
        except Exception:
            device_ids = []

    for dev_id in device_ids:
        dev_path = f'/modules/kdeconnect/devices/{dev_id}'
        try:
            name = subprocess.check_output(['qdbus6', 'org.kde.kdeconnect', dev_path, 'org.kde.kdeconnect.device.name'], stderr=subprocess.DEVNULL, timeout=1.0).decode().strip()
            is_paired = subprocess.check_output(['qdbus6', 'org.kde.kdeconnect', dev_path, 'org.kde.kdeconnect.device.isPaired'], stderr=subprocess.DEVNULL, timeout=1.0).decode().strip() == 'true'
            is_reachable = subprocess.check_output(['qdbus6', 'org.kde.kdeconnect', dev_path, 'org.kde.kdeconnect.device.isReachable'], stderr=subprocess.DEVNULL, timeout=1.0).decode().strip() == 'true'

            if is_paired and is_reachable:
                connected = True

            # Battery
            bat_path = f'{dev_path}/battery'
            charge = -1
            is_charging = False
            try:
                charge = int(subprocess.check_output(['qdbus6', 'org.kde.kdeconnect', bat_path, 'org.kde.kdeconnect.device.battery.charge'], stderr=subprocess.DEVNULL, timeout=1.0).decode().strip())
                is_charging = subprocess.check_output(['qdbus6', 'org.kde.kdeconnect', bat_path, 'org.kde.kdeconnect.device.battery.isCharging'], stderr=subprocess.DEVNULL, timeout=1.0).decode().strip() == 'true'
            except Exception:
                pass

            # Cellular
            conn_path = f'{dev_path}/connectivity_report'
            cell_signal = -1
            cell_type = ''
            try:
                cell_signal = int(subprocess.check_output(['qdbus6', 'org.kde.kdeconnect', conn_path, 'org.kde.kdeconnect.device.connectivity_report.cellularNetworkStrength'], stderr=subprocess.DEVNULL, timeout=1.0).decode().strip())
                cell_type = subprocess.check_output(['qdbus6', 'org.kde.kdeconnect', conn_path, 'org.kde.kdeconnect.device.connectivity_report.cellularNetworkType'], stderr=subprocess.DEVNULL, timeout=1.0).decode().strip()
            except Exception:
                pass

            # Notifications
            notifs_path = f'{dev_path}/notifications'
            notifications = []
            try:
                notif_ids = subprocess.check_output(['qdbus6', 'org.kde.kdeconnect', notifs_path, 'org.kde.kdeconnect.device.notifications.activeNotifications'], stderr=subprocess.DEVNULL, timeout=1.0).decode().strip().splitlines()
                for nid in notif_ids:
                    nid = nid.strip()
                    if not nid: continue
                    n_path = f'{notifs_path}/{nid}'
                    n_props_raw = subprocess.check_output(['qdbus6', 'org.kde.kdeconnect', n_path, 'org.freedesktop.DBus.Properties.GetAll', 'org.kde.kdeconnect.device.notifications.notification'], stderr=subprocess.DEVNULL, timeout=1.0).decode()
                    n_props = {}
                    for line in n_props_raw.splitlines():
                        if ':' in line:
                            k, v = line.split(':', 1)
                            n_props[k.strip()] = v.strip()
                    notifications.append({
                        'id': nid,
                        'appName': n_props.get('appName', 'App'),
                        'title': n_props.get('title', ''),
                        'text': n_props.get('text', ''),
                        'iconPath': n_props.get('iconPath', ''),
                        'dismissable': n_props.get('dismissable', 'true') == 'true'
                    })
            except Exception:
                pass

            devices.append({
                'id': dev_id,
                'name': name or dev_id,
                'isPaired': is_paired,
                'isReachable': is_reachable,
                'battery': {
                    'charge': charge,
                    'isCharging': is_charging
                },
                'cellular': {
                    'signal': cell_signal,
                    'type': cell_type
                },
                'notifications': notifications
            })
        except Exception:
            pass

    shares = load_shares()
    result = {
        "available": available,
        "connected": connected,
        "devices": devices,
        "shares": shares,
        "shareCount": len(shares)
    }
    print(json.dumps(result))

def ring_phone(dev_id):
    try:
        subprocess.run(['qdbus6', 'org.kde.kdeconnect', f'/modules/kdeconnect/devices/{dev_id}/findmyphone', 'org.kde.kdeconnect.device.findmyphone.ring'], check=True)
    except Exception as e:
        print(f"Error ringing phone: {e}", file=sys.stderr)

def browse_device(dev_id):
    try:
        subprocess.run(['qdbus6', 'org.kde.kdeconnect', f'/modules/kdeconnect/devices/{dev_id}/sftp', 'org.kde.kdeconnect.device.sftp.startBrowsing'], check=True)
    except Exception as e:
        print(f"Error browsing device: {e}", file=sys.stderr)

def dismiss_notif(dev_id, notif_id):
    try:
        subprocess.run(['qdbus6', 'org.kde.kdeconnect', f'/modules/kdeconnect/devices/{dev_id}/notifications/{notif_id}', 'org.kde.kdeconnect.device.notifications.notification.dismiss'], check=True)
    except Exception as e:
        print(f"Error dismissing notification: {e}", file=sys.stderr)

def share_file(dev_id, path=None):
    if not path:
        try:
            path = subprocess.check_output(['kdialog', '--getopenfilename', str(Path.home()), 'All Files (*)'], stderr=subprocess.DEVNULL).decode().strip()
        except Exception:
            return
    if path and os.path.exists(path):
        try:
            subprocess.run(['kdeconnect-cli', '-d', dev_id, '--share', path], check=True)
        except Exception as e:
            print(f"Error sharing file: {e}", file=sys.stderr)

def send_clipboard(dev_id):
    try:
        subprocess.run(['kdeconnect-cli', '-d', dev_id, '--send-clipboard'], check=True)
    except Exception as e:
        print(f"Error sending clipboard: {e}", file=sys.stderr)

def open_sms():
    try:
        subprocess.Popen(['kdeconnect-sms'])
    except Exception:
        subprocess.Popen(['kdeconnect-app'])

def open_settings():
    try:
        subprocess.Popen(['kdeconnect-app'])
    except Exception as e:
        print(f"Error opening settings: {e}", file=sys.stderr)

def clear_shares():
    save_shares([])
    print("Cleared shares")

def delete_share(index):
    shares = load_shares()
    if 0 <= index < len(shares):
        shares.pop(index)
        save_shares(shares)
        print("Deleted share")

def run_listener():
    from gi.repository import Gio, GLib

    def on_share_received(connection, sender, path, interface, signal, parameters):
        try:
            raw_url = parameters.unpack()[0]
            parsed = urllib.parse.urlparse(raw_url)
            file_path = urllib.parse.unquote(parsed.path) if parsed.scheme == 'file' else raw_url
            file_name = os.path.basename(file_path) if parsed.scheme == 'file' else raw_url
            
            size_str = ""
            if os.path.exists(file_path):
                size_str = format_size(os.path.getsize(file_path))

            new_share = {
                "id": str(int(time.time() * 1000)),
                "url": raw_url,
                "path": file_path,
                "name": file_name,
                "size": size_str,
                "time": time.strftime("%I:%M %p"),
                "timestamp": int(time.time())
            }

            shares = load_shares()
            shares.insert(0, new_share)
            save_shares(shares[:50]) # Keep max 50 recent shares

            # Terminate kdeconnect-handler so no unwanted window stays open
            subprocess.run(['pkill', '-f', 'kdeconnect-handler'], stderr=subprocess.DEVNULL)

            # Notify Quickshell via IPC if available
            subprocess.run(['qs', '-c', 'ii', 'ipc', 'call', 'kdeconnect', 'onShareReceived'], stderr=subprocess.DEVNULL)
        except Exception as e:
            print(f"Error in shareReceived handler: {e}", file=sys.stderr)

    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    bus.signal_subscribe(
        'org.kde.kdeconnect',
        'org.kde.kdeconnect.device.share',
        'shareReceived',
        None,
        None,
        Gio.DBusSignalFlags.NONE,
        on_share_received,
        None
    )
    print("KDE Connect share listener running...")
    loop = GLib.MainLoop()
    loop.run()

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] == "status":
        get_status()
    elif sys.argv[1] == "ring" and len(sys.argv) >= 3:
        ring_phone(sys.argv[2])
    elif sys.argv[1] == "browse" and len(sys.argv) >= 3:
        browse_device(sys.argv[2])
    elif sys.argv[1] == "dismiss" and len(sys.argv) >= 4:
        dismiss_notif(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "share" and len(sys.argv) >= 3:
        share_file(sys.argv[2], sys.argv[3] if len(sys.argv) >= 4 else None)
    elif sys.argv[1] == "clipboard" and len(sys.argv) >= 3:
        send_clipboard(sys.argv[2])
    elif sys.argv[1] == "sms":
        open_sms()
    elif sys.argv[1] == "settings":
        open_settings()
    elif sys.argv[1] == "clear_shares":
        clear_shares()
    elif sys.argv[1] == "delete_share" and len(sys.argv) >= 3:
        delete_share(int(sys.argv[2]))
    elif sys.argv[1] == "daemon":
        run_listener()
    else:
        print(f"Unknown command: {sys.argv[1]}", file=sys.stderr)

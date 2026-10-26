#!/usr/bin/env python3
"""
update_hypridle.py - Synchronize hypridle configuration with user power settings
Updates ~/.config/hypr/hypridle.conf based on lock and sleep timeouts and restarts hypridle.
"""
import os
import sys
import json
import subprocess
import argparse

HYPRIDLE_CONF = os.path.expanduser("~/.config/hypr/hypridle.conf")
CONFIG_JSON = os.path.expanduser("~/.config/illogical-impulse/config.json")


def generate_conf(lock_timeout: int, sleep_timeout: int) -> str:
    lock_cmd = "hyprctl dispatch 'hl.dsp.global(\"quickshell:lock\")' & pidof qs quickshell hyprlock || hyprlock"
    suspend_cmd = "systemctl suspend || loginctl suspend"

    lines = [
        f"$lock_cmd = {lock_cmd}",
        f"$suspend_cmd = {suspend_cmd}",
        "",
        "general {",
        "    lock_cmd = $lock_cmd",
        "    before_sleep_cmd = loginctl lock-session",
        "    after_sleep_cmd = hyprctl dispatch 'hl.dsp.global(\"quickshell:lockFocus\")'",
        "    inhibit_sleep = 3",
        "}",
        "",
    ]

    # Lock listener
    if lock_timeout > 0:
        lines.extend([
            "listener {",
            f"    timeout = {lock_timeout}",
            "    on-timeout = loginctl lock-session",
            "}",
            "",
        ])

    # DPMS (Screen turn off) listener
    dpms_timeout = 0
    if lock_timeout > 0 and sleep_timeout > 0:
        if sleep_timeout > lock_timeout + 60:
            dpms_timeout = lock_timeout + 60
        else:
            dpms_timeout = max(lock_timeout + 15, (lock_timeout + sleep_timeout) // 2)
    elif lock_timeout > 0:
        dpms_timeout = lock_timeout + 60
    elif sleep_timeout > 0:
        dpms_timeout = max(60, sleep_timeout // 2)

    if dpms_timeout > 0:
        lines.extend([
            "listener {",
            f"    timeout = {dpms_timeout}",
            "    on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'",
            "    on-resume = hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'",
            "}",
            "",
        ])

    # Suspend listener
    if sleep_timeout > 0:
        lines.extend([
            "listener {",
            f"    timeout = {sleep_timeout}",
            "    on-timeout = $suspend_cmd",
            "}",
            "",
        ])

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Update hypridle config with power timeouts")
    parser.add_argument("--lock", type=int, default=None, help="Lock timeout in seconds (0 = never)")
    parser.add_argument("--sleep", type=int, default=None, help="Sleep timeout in seconds (0 = never)")
    args = parser.parse_args()

    lock_timeout = args.lock
    sleep_timeout = args.sleep

    if lock_timeout is None or sleep_timeout is None:
        if os.path.exists(CONFIG_JSON):
            try:
                with open(CONFIG_JSON, "r") as f:
                    data = json.load(f)
                    p_cfg = data.get("power", {})
                    if lock_timeout is None:
                        lock_timeout = p_cfg.get("lockTimeout", 300)
                    if sleep_timeout is None:
                        sleep_timeout = p_cfg.get("sleepTimeout", 900)
            except Exception as e:
                print(f"Warning: could not read {CONFIG_JSON}: {e}", file=sys.stderr)

    if lock_timeout is None:
        lock_timeout = 300
    if sleep_timeout is None:
        sleep_timeout = 900

    new_conf = generate_conf(lock_timeout, sleep_timeout)
    with open(HYPRIDLE_CONF, "w") as f:
        f.write(new_conf)

    # Restart hypridle
    subprocess.run(["pkill", "-x", "hypridle"], stderr=subprocess.DEVNULL)
    subprocess.Popen(
        ["hypridle"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    print(f"hypridle updated successfully: lock={lock_timeout}s, sleep={sleep_timeout}s")


if __name__ == "__main__":
    main()

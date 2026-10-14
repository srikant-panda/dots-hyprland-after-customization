-- Custom execs

-- Multi-monitor Lid & Hotplug Management Daemon
hl.on("hyprland.start", function ()
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py daemon")
end)

-- Ensure daemon is running on reload if not already active
hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py daemon")

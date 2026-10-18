-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("qs -c $qsConfig")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

    -- Core components (authentication, lock screen, notification daemon)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard: history (guarded by private mode)
    hl.exec_cmd("wl-paste --type text --watch bash -c 'if [ ! -f /tmp/cliphist_private_mode ]; then cliphist store && qs -c $qsConfig ipc call cliphistService update; fi'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'if [ ! -f /tmp/cliphist_private_mode ]; then cliphist store && qs -c $qsConfig ipc call cliphistService update; fi'")

    -- Cursor (dynamically uses XCURSOR_THEME/SIZE from HyprMod/environment, defaulting to Adwaita)
    hl.exec_cmd("hyprctl setcursor ${XCURSOR_THEME:-Adwaita} ${XCURSOR_SIZE:-24}")
end)

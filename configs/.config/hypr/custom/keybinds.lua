hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Laptop lid switch event handlers (multi-monitor clamshell / dual-display layout)
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py close"), { locked = true, description = "Lid: Closed" })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py open"), { locked = true, description = "Lid: Opened" })

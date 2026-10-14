hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Laptop lid switch event handlers (multi-monitor clamshell / dual-display layout)
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py close"), { locked = true, description = "Lid: Closed" })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py open"), { locked = true, description = "Lid: Opened" })

-- Unbind default overview from SUPER+Tab so it can be used for visual window switcher
pcall(function() hl.unbind("SUPER + Tab") end)
pcall(function() hl.unbind("SUPER+Tab") end)
pcall(function() hl.unbind("ALT + Tab") end)
pcall(function() hl.unbind("ALT+Tab") end)

-- Define switcher submap for visual Alt+Tab / Super+Tab
hl.define_submap("alttab", function()
    -- Tab / Shift+Tab cycling while holding modifiers
    hl.bind("ALT + Tab", hl.dsp.global("quickshell:altTabNext"))
    hl.bind("ALT + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"))
    hl.bind("SUPER + Tab", hl.dsp.global("quickshell:altTabNext"))
    hl.bind("SUPER + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"))
    hl.bind("Tab", hl.dsp.global("quickshell:altTabNext"))
    hl.bind("SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"))

    -- Arrow keys navigation
    hl.bind("Right", hl.dsp.global("quickshell:altTabNext"), { ignore_mods = true })
    hl.bind("Left", hl.dsp.global("quickshell:altTabPrev"), { ignore_mods = true })

    -- Enter to commit, Escape to cancel
    hl.bind("Return", function()
        hl.dispatch(hl.dsp.global("quickshell:altTabCommit"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { ignore_mods = true })
    hl.bind("Escape", function()
        hl.dispatch(hl.dsp.global("quickshell:altTabCancel"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { ignore_mods = true })

    -- Modifier release handlers: commits selection and exits submap
    hl.bind("Alt_L", function()
        hl.dispatch(hl.dsp.global("quickshell:altTabCommit"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { release = true, ignore_mods = true })
    hl.bind("Alt_R", function()
        hl.dispatch(hl.dsp.global("quickshell:altTabCommit"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { release = true, ignore_mods = true })
    hl.bind("SUPER_L", function()
        hl.dispatch(hl.dsp.global("quickshell:altTabCommit"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { release = true, ignore_mods = true })
    hl.bind("SUPER_R", function()
        hl.dispatch(hl.dsp.global("quickshell:altTabCommit"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { release = true, ignore_mods = true })
end)

-- Entry keybinds to open switcher and enter submap
local function start_switcher(reverse)
    if reverse then
        hl.dispatch(hl.dsp.global("quickshell:altTabPrev"))
    else
        hl.dispatch(hl.dsp.global("quickshell:altTabNext"))
    end
    hl.dispatch(hl.dsp.submap("alttab"))
end

hl.bind("ALT + Tab", function() start_switcher(false) end, { description = "Window: Visual Alt-Tab Switcher" })
hl.bind("ALT + SHIFT + Tab", function() start_switcher(true) end, { description = "Window: Visual Alt-Tab Switcher (prev)" })
hl.bind("SUPER + Tab", function() start_switcher(false) end, { description = "Window: Visual Super-Tab Switcher" })
hl.bind("SUPER + SHIFT + Tab", function() start_switcher(true) end, { description = "Window: Visual Super-Tab Switcher (prev)" })

hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Laptop lid switch event handlers (multi-monitor clamshell / dual-display layout)
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py close"), { locked = true, description = "Lid: Closed" })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py open"), { locked = true, description = "Lid: Opened" })

-- Unbind default overview from SUPER+Tab
pcall(function() hl.unbind("SUPER + Tab") end)
pcall(function() hl.unbind("SUPER+Tab") end)
pcall(function() hl.unbind("ALT + Tab") end)
pcall(function() hl.unbind("ALT+Tab") end)

-- Keys that commit switcher upon release
local release_keys = {
    "Alt_L", "Alt_R", "ALT_L", "ALT_R", "Meta_L", "Meta_R",
    "Super_L", "Super_R", "SUPER_L", "SUPER_R"
}

-- Define switcher submap for visual Alt+Tab / Super+Tab
hl.define_submap("alttab", function()
    -- Tab / Shift+Tab cycling while holding modifiers
    hl.bind("ALT + Tab", hl.dsp.global("quickshell:altTabNext"), { repeating = true })
    hl.bind("ALT + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
    hl.bind("SUPER + Tab", hl.dsp.global("quickshell:altTabNext"), { repeating = true })
    hl.bind("SUPER + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
    hl.bind("Tab", hl.dsp.global("quickshell:altTabNext"), { repeating = true, ignore_mods = true })
    hl.bind("SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })

    -- Arrow keys navigation
    hl.bind("Right", hl.dsp.global("quickshell:altTabNext"), { ignore_mods = true })
    hl.bind("Left", hl.dsp.global("quickshell:altTabPrev"), { ignore_mods = true })

    -- Enter commits, Escape cancels
    hl.bind("Return", hl.dsp.global("quickshell:altTabCommit"), { ignore_mods = true })
    hl.bind("Return", hl.dsp.submap("reset"), { ignore_mods = true })
    hl.bind("Escape", hl.dsp.global("quickshell:altTabCancel"), { ignore_mods = true })
    hl.bind("Escape", hl.dsp.submap("reset"), { ignore_mods = true })

    -- Modifier release handlers inside submap: commit + reset submap
    for _, k in ipairs(release_keys) do
        hl.bind(k, hl.dsp.global("quickshell:altTabCommit"), { ignore_mods = true, transparent = true, release = true })
        hl.bind(k, hl.dsp.submap("reset"), { ignore_mods = true, transparent = true, release = true })

        hl.bind("ALT + " .. k, hl.dsp.global("quickshell:altTabCommit"), { transparent = true, release = true })
        hl.bind("ALT + " .. k, hl.dsp.submap("reset"), { transparent = true, release = true })

        hl.bind("SUPER + " .. k, hl.dsp.global("quickshell:altTabCommit"), { transparent = true, release = true })
        hl.bind("SUPER + " .. k, hl.dsp.submap("reset"), { transparent = true, release = true })

        hl.bind("ALT + SHIFT + " .. k, hl.dsp.global("quickshell:altTabCommit"), { transparent = true, release = true })
        hl.bind("ALT + SHIFT + " .. k, hl.dsp.submap("reset"), { transparent = true, release = true })

        hl.bind("SUPER + SHIFT + " .. k, hl.dsp.global("quickshell:altTabCommit"), { transparent = true, release = true })
        hl.bind("SUPER + SHIFT + " .. k, hl.dsp.submap("reset"), { transparent = true, release = true })
    end
end)

-- Global release handlers outside submap as fail-safe
for _, k in ipairs(release_keys) do
    hl.bind(k, hl.dsp.global("quickshell:altTabCommit"), { ignore_mods = true, transparent = true, release = true })
    hl.bind("ALT + " .. k, hl.dsp.global("quickshell:altTabCommit"), { transparent = true, release = true })
    hl.bind("SUPER + " .. k, hl.dsp.global("quickshell:altTabCommit"), { transparent = true, release = true })
end

-- Initial trigger: Start visual switcher + enter submap
hl.bind("ALT + Tab", hl.dsp.global("quickshell:altTabNext"), { repeating = true, description = "Window: Visual Alt-Tab Switcher" })
hl.bind("ALT + Tab", hl.dsp.submap("alttab"), { repeating = true })

hl.bind("ALT + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true, description = "Window: Visual Alt-Tab Switcher (prev)" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.submap("alttab"), { repeating = true })

hl.bind("SUPER + Tab", hl.dsp.global("quickshell:altTabNext"), { repeating = true, description = "Window: Visual Super-Tab Switcher" })
hl.bind("SUPER + Tab", hl.dsp.submap("alttab"), { repeating = true })

hl.bind("SUPER + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true, description = "Window: Visual Super-Tab Switcher (prev)" })
hl.bind("SUPER + SHIFT + Tab", hl.dsp.submap("alttab"), { repeating = true })

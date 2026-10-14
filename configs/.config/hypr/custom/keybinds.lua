hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Laptop lid switch event handlers (multi-monitor clamshell / dual-display layout)
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py close"), { locked = true, description = "Lid: Closed" })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py open"), { locked = true, description = "Lid: Opened" })

-- Unbind default overview from SUPER+Tab so it can be used for visual window switcher
pcall(function() hl.unbind("SUPER + Tab") end)
pcall(function() hl.unbind("SUPER+Tab") end)
pcall(function() hl.unbind("ALT + Tab") end)
pcall(function() hl.unbind("ALT+Tab") end)

local function commit_switcher()
    hl.dispatch(hl.dsp.global("quickshell:altTabCommit"))
    hl.dispatch(hl.dsp.submap("reset"))
end

local function cancel_switcher()
    hl.dispatch(hl.dsp.global("quickshell:altTabCancel"))
    hl.dispatch(hl.dsp.submap("reset"))
end

local release_keys = {
    "Alt_L", "Alt_R", "ALT_L", "ALT_R", "Meta_L", "Meta_R",
    "Super_L", "Super_R", "SUPER_L", "SUPER_R"
}

-- Define switcher submap for visual Alt+Tab / Super+Tab
hl.define_submap("alttab", function()
    -- Tab / Shift+Tab cycling while holding modifiers
    hl.bind("ALT + Tab", hl.dsp.global("quickshell:altTabNext"))
    hl.bind("ALT + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"))
    hl.bind("SUPER + Tab", hl.dsp.global("quickshell:altTabNext"))
    hl.bind("SUPER + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"))
    hl.bind("Tab", hl.dsp.global("quickshell:altTabNext"), { ignore_mods = true })
    hl.bind("SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"))

    -- Arrow keys navigation
    hl.bind("Right", hl.dsp.global("quickshell:altTabNext"), { ignore_mods = true })
    hl.bind("Left", hl.dsp.global("quickshell:altTabPrev"), { ignore_mods = true })

    -- Enter to commit, Escape to cancel
    hl.bind("Return", commit_switcher, { ignore_mods = true })
    hl.bind("Escape", cancel_switcher, { ignore_mods = true })

    -- Modifier release handlers inside submap
    for _, k in ipairs(release_keys) do
        hl.bind(k, commit_switcher, { ignore_mods = true, transparent = true, release = true })
        hl.bind("ALT + " .. k, commit_switcher, { transparent = true, release = true })
        hl.bind("SUPER + " .. k, commit_switcher, { transparent = true, release = true })
        hl.bind("ALT + SHIFT + " .. k, commit_switcher, { transparent = true, release = true })
        hl.bind("SUPER + SHIFT + " .. k, commit_switcher, { transparent = true, release = true })
    end
end)

-- Global release handlers (fires reliably in any state)
for _, k in ipairs(release_keys) do
    hl.bind(k, hl.dsp.global("quickshell:altTabCommit"), { ignore_mods = true, transparent = true, release = true })
    hl.bind("ALT + " .. k, hl.dsp.global("quickshell:altTabCommit"), { transparent = true, release = true })
    hl.bind("SUPER + " .. k, hl.dsp.global("quickshell:altTabCommit"), { transparent = true, release = true })
end

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

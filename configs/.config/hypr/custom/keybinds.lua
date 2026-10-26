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
    -- Tab / Shift+Tab cycling while holding modifiers (Forward: Left to Right, Reverse: Shift enabled)
    hl.bind("ALT + Tab", hl.dsp.global("quickshell:altTabNext"), { repeating = true })
    hl.bind("ALT + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
    hl.bind("ALT + ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
    hl.bind("ALT + SHIFT + ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })

    hl.bind("SUPER + Tab", hl.dsp.global("quickshell:altTabNext"), { repeating = true })
    hl.bind("SUPER + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
    hl.bind("SUPER + ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
    hl.bind("SUPER + SHIFT + ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })

    hl.bind("Tab", hl.dsp.global("quickshell:altTabNext"), { repeating = true })
    hl.bind("SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
    hl.bind("ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
    hl.bind("SHIFT + ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })

    -- Arrow keys navigation (Right = forward/next, Left = reverse/prev)
    hl.bind("Right", hl.dsp.global("quickshell:altTabNext"), { ignore_mods = true })
    hl.bind("Left", hl.dsp.global("quickshell:altTabPrev"), { ignore_mods = true })

    -- Close selected window with Delete key
    hl.bind("Delete", hl.dsp.global("quickshell:altTabClose"), { ignore_mods = true })
    hl.bind("ALT + Delete", hl.dsp.global("quickshell:altTabClose"))
    hl.bind("SUPER + Delete", hl.dsp.global("quickshell:altTabClose"))
    hl.bind("BackSpace", hl.dsp.global("quickshell:altTabClose"), { ignore_mods = true })

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
hl.bind("ALT + ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
hl.bind("ALT + ISO_Left_Tab", hl.dsp.submap("alttab"), { repeating = true })
hl.bind("ALT + SHIFT + ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
hl.bind("ALT + SHIFT + ISO_Left_Tab", hl.dsp.submap("alttab"), { repeating = true })

hl.bind("SUPER + Tab", hl.dsp.global("quickshell:altTabNext"), { repeating = true, description = "Window: Visual Super-Tab Switcher" })
hl.bind("SUPER + Tab", hl.dsp.submap("alttab"), { repeating = true })

hl.bind("SUPER + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true, description = "Window: Visual Super-Tab Switcher (prev)" })
hl.bind("SUPER + SHIFT + Tab", hl.dsp.submap("alttab"), { repeating = true })
hl.bind("SUPER + ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
hl.bind("SUPER + ISO_Left_Tab", hl.dsp.submap("alttab"), { repeating = true })
hl.bind("SUPER + SHIFT + ISO_Left_Tab", hl.dsp.global("quickshell:altTabPrev"), { repeating = true })
hl.bind("SUPER + SHIFT + ISO_Left_Tab", hl.dsp.submap("alttab"), { repeating = true })

-- ============================================================================
-- Scratchpad Window Retrieval
-- Retrieve / move window from scratchpad (special:special) back to active workspace
-- ============================================================================
local function retrieve_scratchpad_window()
    local win = hl.get_active_window()
    -- If focused window is currently in a special workspace, move it to current workspace (+0)
    if win and win.workspace and (win.workspace.special or win.workspace.id < 0) then
        hl.dispatch(hl.dsp.window.move({ workspace = "+0" }))
        return
    end

    -- If currently on a regular workspace, check if any window exists in scratchpad
    for _, w in ipairs(hl.get_windows()) do
        if w.workspace and (w.workspace.special or w.workspace.id < 0) then
            -- Open scratchpad to focus window, then pull it to current workspace (+0)
            hl.dispatch(hl.dsp.workspace.toggle_special("special"))
            hl.dispatch(hl.dsp.window.move({ workspace = "+0" }))
            return
        end
    end
end

-- Key combinations for getting app back from scratchpad:
-- 1. SUPER + SHIFT + ALT + S / SUPER + ALT + SHIFT + S (natural inverse of SUPER + ALT + S)
-- 2. SUPER + ALT + B (B for "Back" / Bring back from scratchpad)
-- 3. SUPER + ALT + Down (drop window from scratchpad down to current workspace)
hl.bind("SUPER + SHIFT + ALT + S", retrieve_scratchpad_window, { description = "Window: Get back from scratchpad" })
hl.bind("SUPER + ALT + SHIFT + S", retrieve_scratchpad_window, { description = "Window: Get back from scratchpad" })
hl.bind("SUPER + ALT + B", retrieve_scratchpad_window, { description = "Window: Get back from scratchpad" })
hl.bind("SUPER + ALT + Down", retrieve_scratchpad_window, { description = "Window: Get back from scratchpad" })


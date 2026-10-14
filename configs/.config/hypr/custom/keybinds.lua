hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Laptop lid switch event handlers (multi-monitor clamshell / dual-display layout)
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py close"), { locked = true, description = "Lid: Closed" })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/handle_lid.py open"), { locked = true, description = "Lid: Opened" })

-- Unbind default overview from SUPER+Tab so it can be used for cross-workspace window switching
pcall(function() hl.unbind("SUPER + Tab") end)
pcall(function() hl.unbind("SUPER+Tab") end)
pcall(function() hl.unbind("ALT + Tab") end)
pcall(function() hl.unbind("ALT+Tab") end)

-- Cross-workspace Window Cycler (MRU with rapid cycle support)
local last_cycle_time = 0
local cycle_idx = 1
local mru_windows = {}

function _G.cycle_windows_cross_workspace(reverse)
    local now = os.clock()
    -- Rebuild MRU list if more than 1.5s passed since last cycle, or cache empty
    if (now - last_cycle_time > 1.5) or (#mru_windows == 0) then
        local all_wins = hl.get_windows()
        mru_windows = {}
        for _, w in ipairs(all_wins) do
            if w.mapped and not w.hidden and w.workspace and w.workspace.id >= 1 then
                table.insert(mru_windows, w)
            end
        end

        if #mru_windows <= 1 then
            return
        end

        -- Sort by focus_history_id: 0 is current, 1 is previous, 2 is older...
        table.sort(mru_windows, function(a, b)
            return (a.focus_history_id or 999) < (b.focus_history_id or 999)
        end)

        cycle_idx = 1
    end

    last_cycle_time = now

    if #mru_windows <= 1 then
        return
    end

    if reverse then
        cycle_idx = cycle_idx - 1
        if cycle_idx < 1 then
            cycle_idx = #mru_windows
        end
    else
        cycle_idx = cycle_idx + 1
        if cycle_idx > #mru_windows then
            cycle_idx = 1
        end
    end

    local target = mru_windows[cycle_idx]
    if target and target.address then
        hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
    end
end

-- Bind ALT+Tab and SUPER+Tab to cycle windows irrespective of workspace
hl.bind("ALT+Tab", function() cycle_windows_cross_workspace(false) end, { description = "Window: Cycle next across all workspaces" })
hl.bind("ALT+SHIFT+Tab", function() cycle_windows_cross_workspace(true) end, { description = "Window: Cycle prev across all workspaces" })
hl.bind("SUPER+Tab", function() cycle_windows_cross_workspace(false) end, { description = "Window: Cycle next across all workspaces" })
hl.bind("SUPER+SHIFT+Tab", function() cycle_windows_cross_workspace(true) end, { description = "Window: Cycle prev across all workspaces" })

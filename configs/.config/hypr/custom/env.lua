-- Prepend ~/.local/bin to PATH so local user wrappers take precedence
local home_dir = os.getenv("HOME")
local current_path = os.getenv("PATH") or ""
if not string.find(current_path, home_dir .. "/.local/bin") then
    hl.env("PATH", home_dir .. "/.local/bin:" .. current_path)
end

-- NOTE: If you wish to set QT_QPA_PLATFORMTHEME globally across all Qt apps instead of
-- the targeted VLC wrapper and desktop entry, uncomment the line below.
-- Trade-off: Setting this globally causes Qt6 KDE apps (Dolphin, Ark) to lose their
-- Breeze theme/icon loader and emit null pixmap warnings.
-- hl.env("QT_QPA_PLATFORMTHEME", "xdgdesktopportal")

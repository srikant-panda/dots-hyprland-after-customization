-- Silently handle KDE Connect URL/file sharing handler offscreen so no window pops up
hl.window_rule({match = {class = "^(org\\.kde\\.kdeconnect\\.handler)$" }, float = true})
hl.window_rule({match = {class = "^(org\\.kde\\.kdeconnect\\.handler)$" }, no_initial_focus = true})
hl.window_rule({match = {class = "^(org\\.kde\\.kdeconnect\\.handler)$" }, move = {999999, 999999}})
hl.window_rule({match = {class = "^(org\\.kde\\.kdeconnect\\.handler)$" }, size = {0, 0}})

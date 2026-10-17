-- KDE Connect file transfer progress and URL/sharing status windows (always open in floating window)
hl.window_rule({match = {class = "^(org\\.kde\\.kdeconnect\\.handler)$" }, float = true})
hl.window_rule({match = {class = "^(org\\.kde\\.kdeconnect\\.handler)$" }, center = true})

hl.window_rule({match = {class = "^(org\\.kde\\.kdeconnect\\.daemon)$" }, float = true})
hl.window_rule({match = {class = "^(org\\.kde\\.kdeconnect\\.daemon)$" }, center = true})

hl.window_rule({match = {class = "^(kdeconnectd)$" }, float = true})
hl.window_rule({match = {class = "^(kdeconnectd)$" }, center = true})

-- KDE / KIO file transfer progress dialogs (whether sending or getting files)
hl.window_rule({match = {title = ".*(Progress Dialog).*" }, float = true})
hl.window_rule({match = {title = ".*(Progress Dialog).*" }, center = true})
hl.window_rule({match = {title = "^(KDE Connect).*$" }, float = true})
hl.window_rule({match = {title = "^(KDE Connect).*$" }, center = true})

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.services
import qs.modules.common

Singleton {
    id: root

    /**
     * Determines clean source information for an MprisPlayer.
     * Identifies YouTube, Spotify, KDE Connect, browsers, etc.
     */
    function getSourceInfo(player) {
        if (!player) {
            return {
                name: Translation.tr("Media"),
                iconName: "music_note",
                iconPath: "",
                materialSymbol: "music_note",
                isMaterial: true,
                rawPlayer: null
            };
        }

        const dbus = (player.dbusName || "").toLowerCase();
        const identity = (player.identity || "").toLowerCase();
        const desktop = (player.desktopEntry || "").toLowerCase();
        const url = (player.trackUrl || "").toLowerCase();
        const title = (player.trackTitle || "").toLowerCase();
        const art = (player.trackArtUrl || "").toLowerCase();

        // 1. YouTube / YouTube Music detection
        if (url.includes("youtube.com") || url.includes("youtu.be") ||
            url.includes("music.youtube") || art.includes("youtube") ||
            title.includes("youtube") || identity.includes("youtube") ||
            desktop.includes("youtube")) {
            
            const isMusic = url.includes("music.youtube") || title.includes("youtube music") || identity.includes("youtube music");
            return {
                name: isMusic ? "YouTube Music" : "YouTube",
                iconName: "youtube",
                iconPath: resolveIcon("youtube") || resolveIcon("appimagekit-youtube-dl-gui"),
                materialSymbol: isMusic ? "play_circle" : "smart_display",
                isMaterial: false,
                rawPlayer: player
            };
        }

        // 2. Spotify detection
        if (dbus.includes("spotify") || identity.includes("spotify") || desktop.includes("spotify")) {
            return {
                name: "Spotify",
                iconName: "spotify",
                iconPath: resolveIcon("spotify") || resolveIcon("com.spotify.Client") || resolveIcon("spotify-client"),
                materialSymbol: "library_music",
                isMaterial: false,
                rawPlayer: player
            };
        }

        // 3. KDE Connect / KDE Network detection
        if (dbus.includes("kdeconnect") || identity.includes("kde connect") ||
            identity.includes("kdeconnect") || desktop.includes("kdeconnect")) {
            return {
                name: "KDE Connect",
                iconName: "kdeconnect",
                iconPath: resolveIcon("kdeconnect") || resolveIcon("org.kde.kdeconnect.daemon"),
                materialSymbol: "phonelink",
                isMaterial: false,
                rawPlayer: player
            };
        }

        // 4. Web Browsers
        if (dbus.includes("firefox") || identity.includes("firefox") || desktop.includes("firefox")) {
            return {
                name: "Firefox",
                iconName: "firefox",
                iconPath: resolveIcon("firefox"),
                materialSymbol: "public",
                isMaterial: false,
                rawPlayer: player
            };
        }
        if (dbus.includes("chrome") || identity.includes("chrome") || desktop.includes("chrome")) {
            return {
                name: "Google Chrome",
                iconName: "google-chrome",
                iconPath: resolveIcon("google-chrome"),
                materialSymbol: "public",
                isMaterial: false,
                rawPlayer: player
            };
        }
        if (dbus.includes("chromium") || identity.includes("chromium") || desktop.includes("chromium")) {
            return {
                name: "Chromium",
                iconName: "chromium",
                iconPath: resolveIcon("chromium"),
                materialSymbol: "public",
                isMaterial: false,
                rawPlayer: player
            };
        }
        if (dbus.includes("brave") || identity.includes("brave") || desktop.includes("brave")) {
            return {
                name: "Brave",
                iconName: "brave-browser",
                iconPath: resolveIcon("brave-browser") || resolveIcon("brave"),
                materialSymbol: "public",
                isMaterial: false,
                rawPlayer: player
            };
        }
        if (dbus.includes("plasma-browser-integration")) {
            return {
                name: player.identity && player.identity.length > 0 ? player.identity : "Browser",
                iconName: "internet-web-browser",
                iconPath: resolveIcon("internet-web-browser") || resolveIcon("google-chrome"),
                materialSymbol: "language",
                isMaterial: false,
                rawPlayer: player
            };
        }

        // 5. Standalone Media Players
        if (dbus.includes("vlc") || identity.includes("vlc") || desktop.includes("vlc")) {
            return {
                name: "VLC",
                iconName: "vlc",
                iconPath: resolveIcon("vlc"),
                materialSymbol: "movie",
                isMaterial: false,
                rawPlayer: player
            };
        }
        if (dbus.includes("mpv") || identity.includes("mpv") || desktop.includes("mpv")) {
            return {
                name: "mpv",
                iconName: "mpv",
                iconPath: resolveIcon("mpv"),
                materialSymbol: "movie",
                isMaterial: false,
                rawPlayer: player
            };
        }
        if (dbus.includes("elisa") || identity.includes("elisa") || desktop.includes("elisa")) {
            return {
                name: "Elisa",
                iconName: "elisa",
                iconPath: resolveIcon("elisa"),
                materialSymbol: "music_note",
                isMaterial: false,
                rawPlayer: player
            };
        }

        // 6. Generic or desktop-entry resolved fallback
        let guessedIcon = "";
        if (player.desktopEntry && player.desktopEntry.length > 0) {
            guessedIcon = resolveIcon(player.desktopEntry) || resolveIcon(AppSearch.guessIcon(player.desktopEntry));
        }
        if (!guessedIcon && player.identity && player.identity.length > 0) {
            guessedIcon = resolveIcon(player.identity) || resolveIcon(AppSearch.guessIcon(player.identity));
        }

        return {
            name: player.identity && player.identity.length > 0 ? player.identity : Translation.tr("Media Player"),
            iconName: player.desktopEntry || "multimedia-audio-player",
            iconPath: guessedIcon,
            materialSymbol: "music_note",
            isMaterial: !guessedIcon,
            rawPlayer: player
        };
    }

    /**
     * Resolves a desktop icon path or returns empty string if not found.
     */
    function resolveIcon(iconName) {
        if (!iconName || iconName.length === 0) return "";
        try {
            const path = Quickshell.iconPath(iconName, "image-missing");
            if (path && path.length > 0 && !path.includes("image-missing")) {
                return path;
            }
        } catch (e) {
            // Ignore error
        }
        return "";
    }

    /**
     * Cleanly closes or stops a media source.
     */
    function closeSource(player) {
        if (!player) return;
        try {
            console.log(`[MediaUtils] Closing media source: ${player.identity || player.dbusName} (canQuit: ${player.canQuit})`);
            
            // 1. If player supports Quit, call native quit()
            if (player.canQuit) {
                player.quit();
            } else {
                if (player.canStop && player.stop) player.stop();
                if (player.canPause && player.pause) player.pause();
            }

            // 3. Also dispatch DBus Stop via playerctl as reliable fallback
            if (player.dbusName && player.dbusName.length > 0) {
                const shortName = player.dbusName.replace("org.mpris.MediaPlayer2.", "");
                Quickshell.execDetached(["playerctl", "--player=" + shortName, "stop"]);
            }
        } catch (e) {
            console.log("[MediaUtils] Error closing source:", e);
        }
    }
}

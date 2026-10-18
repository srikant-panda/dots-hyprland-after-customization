pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    property bool targetDark: Appearance.m3colors.darkmode
    property bool isSwitching: false

    // Circular reveal properties
    property bool revealActive: false
    property real revealOriginX: 960
    property real revealOriginY: 540
    property real revealProgress: 0.0
    property string snapshotTimestamp: ""

    function reapplyTheme() {
        themeFileView.reload()
    }

    function applyColors(fileContent) {
        if (!fileContent || fileContent.trim().length === 0) return;
        try {
            const json = JSON.parse(fileContent)
            for (const key in json) {
                if (json.hasOwnProperty(key)) {
                    // Convert snake_case to CamelCase
                    const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                    const m3Key = `m3${camelCaseKey}`
                    Appearance.m3colors[m3Key] = json[key]
                }
            }
            
            Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
            root.targetDark = Appearance.m3colors.darkmode
            root.isSwitching = false
            switchingSafetyTimeout.stop()
        } catch (e) {
            console.error("[MaterialThemeLoader] Error applying colors:", e)
            root.isSwitching = false
        }
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    Timer {
        id: switchingSafetyTimeout
        interval: 3500
        repeat: false
        running: false
        onTriggered: {
            root.isSwitching = false
            root.targetDark = Appearance.m3colors.darkmode
            root.revealActive = false
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

    FileView { 
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: root.resetFilePathNextTime();
    }

    // NumberAnimation for circular reveal expansion (550ms OutCubic)
    NumberAnimation {
        id: revealAnim
        target: root
        property: "revealProgress"
        from: 0.0
        to: 1.0
        duration: 550
        easing.type: Easing.OutCubic
        onFinished: {
            root.revealActive = false
            // Clean up temporary snapshots in background
            Quickshell.execDetached(["rm", "-rf", "/tmp/quickshell/media/theme_snapshots"]);
        }
    }

    // Process to capture sub-50ms snapshot of screen before switching
    Process {
        id: captureSnapshotProc
        property bool pendingForceDark: false
        property bool hasPendingForceDark: false
        command: [Directories.captureSnapshotScriptPath]
        stdout: StdioCollector {
            id: snapshotOutputCollector
            onStreamFinished: {
                try {
                    const text = snapshotOutputCollector.text.trim();
                    const json = JSON.parse(text);
                    if (json.x !== undefined && json.y !== undefined) {
                        root.revealOriginX = json.x;
                        root.revealOriginY = json.y;
                    }
                    if (json.ts) {
                        root.snapshotTimestamp = json.ts;
                    }
                } catch (e) {
                    console.log("[MaterialThemeLoader] Snapshot parse info:", e);
                }
            }
        }
        onExited: (exitCode) => {
            const nextDark = captureSnapshotProc.hasPendingForceDark ? captureSnapshotProc.pendingForceDark : !root.targetDark;
            root.targetDark = nextDark;

            if (exitCode === 0 && root.snapshotTimestamp !== "") {
                root.revealProgress = 0.0;
                root.revealActive = true;
                revealAnim.restart();
            } else {
                root.revealActive = false;
            }

            // Execute theme change behind the overlay
            Quickshell.execDetached([
                Directories.wallpaperSwitchScriptPath,
                "--mode", nextDark ? "dark" : "light",
                "--noswitch"
            ]);
        }
    }

    function toggleLightDark(forceDark) {
        if (root.isSwitching || captureSnapshotProc.running) {
            return;
        }

        root.isSwitching = true;
        switchingSafetyTimeout.restart();

        captureSnapshotProc.hasPendingForceDark = (forceDark !== undefined);
        if (forceDark !== undefined) {
            captureSnapshotProc.pendingForceDark = forceDark;
        }

        captureSnapshotProc.running = true;
    }

    GlobalShortcut {
        name: "toggleLightDark"
        description: "Toggles between dark theme and light theme"

        onPressed: {
            root.toggleLightDark();
        }
    }

    IpcHandler {
        target: "theme"

        function toggleLightDark(): void {
            root.toggleLightDark();
        }
    }
}

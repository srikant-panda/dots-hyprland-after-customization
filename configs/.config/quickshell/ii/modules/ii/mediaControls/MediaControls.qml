pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Hyprland

import Quickshell.Widgets
import qs.modules.ii.bar as Bar

Scope {
    id: root
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var realPlayers: MprisController.players
    readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)
    readonly property bool hasMedia: root.meaningfulPlayers.length > 0
    readonly property MprisPlayer currentSelectedPlayer: (root.meaningfulPlayers.indexOf(root.activePlayer) !== -1 ? root.activePlayer : root.meaningfulPlayers[0]) ?? null
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    property list<real> visualizerPoints: []

    function filterDuplicatePlayers(players) {
        if (!players) return [];
        let validPlayers = players.filter(p => p && ((p.trackTitle && p.trackTitle.trim().length > 0) || p.isPlaying));
        if (validPlayers.length === 0) return [];
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < validPlayers.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = validPlayers[i];
            let group = [i];

            for (let j = i + 1; j < validPlayers.length; ++j) {
                let p2 = validPlayers[j];
                const isSameApp = (p1.desktopEntry && p2.desktopEntry && p1.desktopEntry === p2.desktopEntry) ||
                                  (p1.identity && p2.identity && p1.identity === p2.identity) ||
                                  (p1.dbusName && p2.dbusName && p1.dbusName === p2.dbusName);

                const sameTitle = p1.trackTitle && p2.trackTitle &&
                                  (p1.trackTitle === p2.trackTitle || p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle));

                const sameTime = (p1.length > 0 && p2.length > 0) &&
                                 Math.abs(p1.position - p2.position) <= 2 &&
                                 Math.abs(p1.length - p2.length) <= 2;

                if (isSameApp && (sameTitle || sameTime)) {
                    group.push(j);
                }
            }

            // Pick the one with non-empty trackArtUrl, or fallback to the first
            let chosenIdx = group.find(idx => validPlayers[idx].trackArtUrl && validPlayers[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(validPlayers[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    Process {
        id: cavaProc
        running: mediaControlsLoader.active
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                // Parse `;`-separated values into the visualizerPoints array
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Loader {
        id: mediaControlsLoader
        active: GlobalStates.mediaControlsOpen && root.hasMedia
        onActiveChanged: {
            if (!mediaControlsLoader.active && !root.hasMedia) {
                GlobalStates.mediaControlsOpen = false;
            }
        }

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: singlePlayerControl.implicitWidth
            implicitHeight: singlePlayerControl.implicitHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"

            anchors {
                top: !Config.options.bar.bottom || Config.options.bar.vertical
                bottom: Config.options.bar.bottom && !Config.options.bar.vertical
                left: !(Config.options.bar.vertical && Config.options.bar.bottom)
                right: Config.options.bar.vertical && Config.options.bar.bottom
            }
            margins {
                top: Config.options.bar.vertical ? ((panelWindow.screen.height / 2) - (singlePlayerControl.implicitHeight / 2)) : Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
                left: Config.options.bar.vertical ? Appearance.sizes.barHeight : ((panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth)
                right: Appearance.sizes.barHeight
            }

            mask: Region {
                item: singlePlayerControl
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.mediaControlsOpen = false;
                }
            }

            PlayerControl {
                id: singlePlayerControl
                anchors.fill: parent
                player: root.currentSelectedPlayer
                availablePlayers: root.meaningfulPlayers
                visualizerPoints: root.visualizerPoints
                radius: root.popupRounding
            }
        }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            mediaControlsLoader.active = !mediaControlsLoader.active;
            if (mediaControlsLoader.active)
                Notifications.timeoutAll();
        }

        function close(): void {
            mediaControlsLoader.active = false;
        }

        function open(): void {
            mediaControlsLoader.active = true;
            Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Toggles media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
        }
    }
    GlobalShortcut {
        name: "mediaControlsOpen"
        description: "Opens media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = true;
        }
    }
    GlobalShortcut {
        name: "mediaControlsClose"
        description: "Closes media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = false;
        }
    }
}

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

    readonly property MprisPlayer currentSelectedPlayer: (root.meaningfulPlayers.indexOf(root.activePlayer) !== -1 ? root.activePlayer : root.meaningfulPlayers[0]) ?? null
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    property list<real> visualizerPoints: []

    function filterDuplicatePlayers(players) {
        if (!players) return [];
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = players[i];
            let group = [i];

            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
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
            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(players[chosenIdx]);
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
        active: GlobalStates.mediaControlsOpen
        onActiveChanged: {
            if (!mediaControlsLoader.active && root.realPlayers.length === 0) {
                GlobalStates.mediaControlsOpen = false;
            }
        }

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: root.widgetWidth
            implicitHeight: playerColumnLayout.implicitHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"

            anchors {
                top: !Config.options.bar.bottom || Config.options.bar.vertical
                bottom: Config.options.bar.bottom && !Config.options.bar.vertical
                left: !(Config.options.bar.vertical && Config.options.bar.bottom)
                right: Config.options.bar.vertical && Config.options.bar.bottom
            }
            margins {
                top: Config.options.bar.vertical ? ((panelWindow.screen.height / 2) - widgetHeight * 1.5) : Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
                left: Config.options.bar.vertical ? Appearance.sizes.barHeight : ((panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth)
                right: Appearance.sizes.barHeight
            }

            mask: Region {
                item: playerColumnLayout
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

            Loader {
                id: popupSourceContextMenuLoader
                property MprisPlayer targetPlayer: null
                active: false
                sourceComponent: Bar.MediaContextMenu {
                    anchorItem: panelWindow
                    player: popupSourceContextMenuLoader.targetPlayer ?? root.currentSelectedPlayer
                    onPopupClosed: popupSourceContextMenuLoader.active = false
                }
            }

            ColumnLayout {
                id: playerColumnLayout
                anchors.fill: parent
                spacing: 2

                // Horizontal Source Switcher Bar (displayed when multiple sources exist)
                Item {
                    id: sourceBarContainer
                    visible: root.meaningfulPlayers.length > 1
                    Layout.fillWidth: true
                    implicitHeight: visible ? (sourceBarBg.implicitHeight + Appearance.sizes.elevationMargin * 2) : 0

                    StyledRectangularShadow {
                        target: sourceBarBg
                    }

                    Rectangle {
                        id: sourceBarBg
                        anchors.fill: parent
                        anchors.margins: Appearance.sizes.elevationMargin
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer0
                        border.color: Appearance.colors.colOutlineVariant
                        border.width: 1
                        implicitHeight: sourceRow.implicitHeight + 10

                        RowLayout {
                            id: sourceRow
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            MaterialSymbol {
                                text: "queue_music"
                                iconSize: 18
                                color: Appearance.colors.colPrimary
                                Layout.leftMargin: 2
                            }

                            StyledText {
                                text: Translation.tr("Sources")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colPrimary
                                Layout.rightMargin: 4
                            }

                            // Horizontal scroll / row of source icons
                            Flickable {
                                id: sourceFlickable
                                Layout.fillWidth: true
                                implicitHeight: pillsRow.implicitHeight
                                contentWidth: pillsRow.implicitWidth
                                contentHeight: pillsRow.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                RowLayout {
                                    id: pillsRow
                                    spacing: 6

                                    Repeater {
                                        model: ScriptModel {
                                            values: root.meaningfulPlayers
                                        }
                                        delegate: RippleButton {
                                            id: srcBtn
                                            required property MprisPlayer modelData
                                            readonly property var info: MediaUtils.getSourceInfo(modelData)
                                            readonly property bool isSelected: modelData === root.currentSelectedPlayer

                                            implicitHeight: 28
                                            implicitWidth: pillContent.implicitWidth + 16
                                            buttonRadius: 14

                                            colBackground: isSelected ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colLayer1, 0.4)
                                            colBackgroundHover: isSelected ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
                                            colRipple: isSelected ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer1Active

                                            contentItem: RowLayout {
                                                id: pillContent
                                                anchors.centerIn: parent
                                                spacing: 5

                                                Loader {
                                                    active: srcBtn.info.iconPath.length > 0
                                                    visible: active
                                                    Layout.alignment: Qt.AlignVCenter
                                                    sourceComponent: IconImage {
                                                        implicitSize: 16
                                                        source: srcBtn.info.iconPath
                                                    }
                                                }

                                                Loader {
                                                    active: !srcBtn.info.iconPath || srcBtn.info.iconPath.length === 0
                                                    visible: active
                                                    Layout.alignment: Qt.AlignVCenter
                                                    sourceComponent: MaterialSymbol {
                                                        text: srcBtn.info.materialSymbol
                                                        iconSize: 16
                                                        color: srcBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                                    }
                                                }

                                                StyledText {
                                                    text: srcBtn.info.name
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    font.weight: srcBtn.isSelected ? Font.Bold : Font.Normal
                                                    color: srcBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                                    Layout.alignment: Qt.AlignVCenter
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            onClicked: {
                                                MprisController.setActivePlayer(modelData);
                                            }

                                            // Right-click options on source pill
                                            MouseArea {
                                                anchors.fill: parent
                                                acceptedButtons: Qt.RightButton
                                                onClicked: (event) => {
                                                    if (event.button === Qt.RightButton) {
                                                        popupSourceContextMenuLoader.targetPlayer = modelData;
                                                        popupSourceContextMenuLoader.active = true;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Quick Close Button for current active player
                            RippleButton {
                                implicitWidth: 26
                                implicitHeight: 26
                                buttonRadius: 13
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colErrorContainer
                                colRipple: Appearance.colors.colError
                                ToolTip.visible: hovered
                                ToolTip.text: `${Translation.tr("Close")} (${MediaUtils.getSourceInfo(root.currentSelectedPlayer).name})`

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 16
                                    color: parent.hovered ? Appearance.colors.colOnErrorContainer : Appearance.colors.colError
                                }

                                onClicked: {
                                    MediaUtils.closeSource(root.currentSelectedPlayer);
                                }
                            }
                        }
                    }
                }

                // Single Active Player Control (no vertical stacking)
                PlayerControl {
                    id: singlePlayerControl
                    visible: root.meaningfulPlayers.length > 0
                    player: root.currentSelectedPlayer
                    visualizerPoints: root.visualizerPoints
                    implicitWidth: root.widgetWidth
                    implicitHeight: root.widgetHeight
                    radius: root.popupRounding
                }

                Item {
                    // No player placeholder
                    Layout.alignment: {
                        if (panelWindow.anchors.left)
                            return Qt.AlignLeft;
                        if (panelWindow.anchors.right)
                            return Qt.AlignRight;
                        return Qt.AlignHCenter;
                    }
                    Layout.leftMargin: Appearance.sizes.hyprlandGapsOut
                    Layout.rightMargin: Appearance.sizes.hyprlandGapsOut
                    visible: root.meaningfulPlayers.length === 0
                    implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                    implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                    StyledRectangularShadow {
                        target: placeholderBackground
                    }

                    Rectangle {
                        id: placeholderBackground
                        anchors.centerIn: parent
                        color: Appearance.colors.colLayer0
                        radius: root.popupRounding
                        property real padding: 20
                        implicitWidth: placeholderLayout.implicitWidth + padding * 2
                        implicitHeight: placeholderLayout.implicitHeight + padding * 2

                        ColumnLayout {
                            id: placeholderLayout
                            anchors.centerIn: parent

                            StyledText {
                                text: Translation.tr("No active player")
                                font.pixelSize: Appearance.font.pixelSize.large
                            }
                            StyledText {
                                color: Appearance.colors.colSubtext
                                text: Translation.tr("Make sure your player has MPRIS support\nor try turning off duplicate player filtering")
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }
                }
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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

PopupWindow {
    id: root

    required property Item anchorItem
    property MprisPlayer player: MprisController.activePlayer
    readonly property var allPlayers: MprisController.players
    readonly property var sourceInfo: MediaUtils.getSourceInfo(root.player)
    readonly property string cleanTitle: StringUtils.cleanMusicTitle(root.player?.trackTitle) || Translation.tr("No media playing")

    signal popupClosed

    function close() {
        root.visible = false;
        root.popupClosed();
    }

    anchor {
        adjustment: PopupAdjustment.Slide
        window: root.anchorItem?.QsWindow?.window
        item: root.anchorItem
        gravity: Config.options.bar.vertical
            ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
            : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
        edges: Config.options.bar.vertical
            ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
            : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.visible
        windows: [root, root.anchorItem?.QsWindow?.window]
        onCleared: root.close()
    }

    color: "transparent"
    visible: true
    implicitWidth: 300 + Appearance.sizes.elevationMargin * 2
    implicitHeight: (mainLayout?.implicitHeight ?? 240) + Appearance.sizes.elevationMargin * 2 + 20

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        StyledRectangularShadow {
            target: popupCard
        }

        Rectangle {
            id: popupCard
            anchors.fill: parent
            anchors.margins: Appearance.sizes.elevationMargin
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer0
            border.color: Appearance.colors.colOutlineVariant
            border.width: 1

            ColumnLayout {
                id: mainLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 6

                // 1. Header with Source Icon and Track Info
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Source app icon badge
                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 8
                        color: Appearance.colors.colSecondaryContainer
                        border.color: Appearance.colors.colOutlineVariant
                        border.width: 1

                        Loader {
                            anchors.centerIn: parent
                            active: root.sourceInfo.iconPath && root.sourceInfo.iconPath.length > 0
                            sourceComponent: IconImage {
                                implicitSize: 22
                                source: root.sourceInfo.iconPath
                            }
                        }

                        Loader {
                            anchors.centerIn: parent
                            active: !root.sourceInfo.iconPath || root.sourceInfo.iconPath.length === 0
                            sourceComponent: MaterialSymbol {
                                text: root.sourceInfo.materialSymbol
                                iconSize: 22
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            StyledText {
                                text: root.sourceInfo.name
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colPrimary
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                implicitWidth: statusText.implicitWidth + 8
                                implicitHeight: 16
                                radius: 8
                                color: root.player?.isPlaying ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1

                                StyledText {
                                    id: statusText
                                    anchors.centerIn: parent
                                    text: root.player?.isPlaying ? Translation.tr("Playing") : Translation.tr("Paused")
                                    font.pixelSize: 10
                                    color: root.player?.isPlaying ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.cleanTitle
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: (root.player?.trackArtist || "").length > 0
                            text: root.player?.trackArtist || ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.colors.colOutlineVariant
                    opacity: 0.5
                    Layout.topMargin: 2
                    Layout.bottomMargin: 2
                }

                // 2. Playback Control Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        buttonRadius: 6
                        colBackground: Appearance.colors.colLayer1
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active

                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol {
                                text: root.player?.isPlaying ? "pause" : "play_arrow"
                                iconSize: 18
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: root.player?.isPlaying ? Translation.tr("Pause") : Translation.tr("Play")
                                font.pixelSize: Appearance.font.pixelSize.smallie
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                        onClicked: {
                            root.player?.togglePlaying();
                        }
                    }

                    RippleButton {
                        implicitWidth: 34
                        implicitHeight: 34
                        buttonRadius: 6
                        colBackground: Appearance.colors.colLayer1
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_previous"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer1
                        }
                        onClicked: {
                            root.player?.previous();
                        }
                    }

                    RippleButton {
                        implicitWidth: 34
                        implicitHeight: 34
                        buttonRadius: 6
                        colBackground: Appearance.colors.colLayer1
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_next"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer1
                        }
                        onClicked: {
                            root.player?.next();
                        }
                    }
                }

                // 3. Switch Source Section (if multiple players exist)
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.allPlayers.length > 1
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Appearance.colors.colOutlineVariant
                        opacity: 0.5
                        Layout.topMargin: 2
                        Layout.bottomMargin: 2
                    }

                    StyledText {
                        text: Translation.tr("Change Source")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colSubtext
                        Layout.leftMargin: 4
                    }

                    // Source Switcher Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: root.allPlayers
                            delegate: RippleButton {
                                id: srcBtn
                                required property MprisPlayer modelData
                                readonly property var itemInfo: MediaUtils.getSourceInfo(modelData)
                                readonly property bool isCurrent: modelData === root.player

                                Layout.fillWidth: true
                                implicitHeight: 32
                                buttonRadius: 6

                                colBackground: isCurrent ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                                colBackgroundHover: isCurrent ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1Hover
                                colRipple: isCurrent ? Appearance.colors.colPrimaryContainerActive : Appearance.colors.colLayer1Active

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Loader {
                                        active: srcBtn.itemInfo.iconPath.length > 0
                                        sourceComponent: IconImage {
                                            implicitSize: 16
                                            source: srcBtn.itemInfo.iconPath
                                        }
                                    }

                                    Loader {
                                        active: !srcBtn.itemInfo.iconPath || srcBtn.itemInfo.iconPath.length === 0
                                        sourceComponent: MaterialSymbol {
                                            text: srcBtn.itemInfo.materialSymbol
                                            iconSize: 16
                                            color: srcBtn.isCurrent ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                                        }
                                    }

                                    StyledText {
                                        text: srcBtn.itemInfo.name
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: srcBtn.isCurrent ? Font.Bold : Font.Normal
                                        color: srcBtn.isCurrent ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }
                                }

                                onClicked: {
                                    MprisController.setActivePlayer(modelData);
                                    root.close();
                                }
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.colors.colOutlineVariant
                    opacity: 0.5
                    Layout.topMargin: 2
                    Layout.bottomMargin: 2
                }

                // 4. Focus Application Window (if canRaise or desktop window)
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    buttonRadius: 6
                    visible: root.player?.canRaise ?? true
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        MaterialSymbol {
                            text: "open_in_new"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer0
                        }

                        StyledText {
                            text: Translation.tr("Open Player Window")
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            color: Appearance.colors.colOnLayer0
                            Layout.fillWidth: true
                        }
                    }

                    onClicked: {
                        if (root.player?.canRaise) {
                            root.player.raise();
                        }
                        root.close();
                    }
                }

                // 5. Open Full Media Controls Popup
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    buttonRadius: 6
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        MaterialSymbol {
                            text: "expand_content"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer0
                        }

                        StyledText {
                            text: Translation.tr("Show Full Controls")
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            color: Appearance.colors.colOnLayer0
                            Layout.fillWidth: true
                        }
                    }

                    onClicked: {
                        GlobalStates.mediaControlsOpen = true;
                        root.close();
                    }
                }

                // 6. Close Source Option (Destructive Action)
                RippleButton {
                    id: closeSourceBtn
                    Layout.fillWidth: true
                    implicitHeight: 36
                    buttonRadius: 6
                    colBackground: Appearance.colors.colErrorContainer
                    colBackgroundHover: ColorUtils.mix(Appearance.colors.colErrorContainer, Appearance.colors.colError, 0.2)
                    colRipple: Appearance.colors.colError

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        MaterialSymbol {
                            text: "close"
                            iconSize: 18
                            color: Appearance.colors.colOnErrorContainer
                        }

                        StyledText {
                            text: `${Translation.tr("Close Source")} (${root.sourceInfo.name})`
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnErrorContainer
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    onClicked: {
                        MediaUtils.closeSource(root.player);
                        root.close();
                    }
                }
            }
        }
    }
}

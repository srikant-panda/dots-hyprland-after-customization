pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

PopupWindow {
    id: root

    required property Item anchorItem
    property real popupPadding: 8

    color: "transparent"
    visible: true

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

    implicitWidth: Math.max(220, Math.min(320, mainColumn.implicitWidth + 24))
    implicitHeight: mainColumn.implicitHeight + 20

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        StyledRectangularShadow {
            target: popupCard
        }

        Rectangle {
            id: popupCard
            anchors.fill: parent
            anchors.margins: 4
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainer
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            clip: true

            ColumnLayout {
                id: mainColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 10
                }
                spacing: 8

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    height: 24
                    spacing: 6

                    MaterialSymbol {
                        text: "grid_view"
                        iconSize: 16
                        color: Appearance.m3colors.m3primary
                    }

                    StyledText {
                        text: Translation.tr("Background Apps")
                        font.bold: true
                        font.pixelSize: 11
                        color: Appearance.m3colors.m3onSurface
                    }

                    StyledText {
                        text: `(${TrayService.unpinnedItems.length})`
                        font.pixelSize: 10
                        font.bold: true
                        color: Appearance.m3colors.m3primary
                        visible: TrayService.unpinnedItems.length > 0
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RippleButton {
                        implicitWidth: 22
                        implicitHeight: 22
                        buttonRadius: 11
                        colBackground: hovered ? Appearance.colors.colLayer1Hover : "transparent"

                        onPressed: root.close()

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 14
                            color: Appearance.m3colors.m3onSurfaceVariant
                        }

                        PopupToolTip {
                            text: "Close"
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.m3colors.m3outlineVariant
                    opacity: 0.4
                }

                // Empty state if no unpinned apps
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    Layout.bottomMargin: 6
                    visible: TrayService.unpinnedItems.length === 0
                    spacing: 4

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "check_circle"
                        iconSize: 24
                        color: Appearance.m3colors.m3primary
                        opacity: 0.7
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No hidden apps"
                        font.pixelSize: 11
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                }

                // Grid of unpinned apps
                GridLayout {
                    id: appsGrid
                    Layout.alignment: Qt.AlignHCenter
                    visible: TrayService.unpinnedItems.length > 0
                    columns: Math.max(3, Math.min(5, Math.ceil(Math.sqrt(TrayService.unpinnedItems.length * 2.5))))
                    columnSpacing: 6
                    rowSpacing: 6

                    Repeater {
                        model: TrayService.unpinnedItems

                        delegate: Rectangle {
                            id: appTile
                            required property SystemTrayItem modelData

                            implicitWidth: 44
                            implicitHeight: 44
                            radius: Appearance.rounding.small
                            color: tileMouseArea.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
                            border.width: 1
                            border.color: tileMouseArea.containsMouse ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            MouseArea {
                                id: tileMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor

                                onClicked: (event) => {
                                    if (event.button === Qt.LeftButton) {
                                        appTile.modelData.activate();
                                        root.close();
                                    } else if (event.button === Qt.RightButton) {
                                        if (appTile.modelData.hasMenu) {
                                            tileMenuLoader.active = true;
                                        }
                                    }
                                }
                            }

                            // App Icon
                            IconImage {
                                id: appIconImg
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: appTile.modelData.icon
                            }

                            // Pin Button in top-right corner
                            RippleButton {
                                id: pinBtn
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 1
                                implicitWidth: 16
                                implicitHeight: 16
                                buttonRadius: 8
                                visible: tileMouseArea.containsMouse || pinBtn.hovered
                                colBackground: hovered ? Appearance.m3colors.m3primaryContainer : Appearance.colors.colLayer2

                                onPressed: {
                                    TrayService.togglePin(appTile.modelData.id);
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "push_pin"
                                    iconSize: 10
                                    color: pinBtn.hovered ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
                                }

                                PopupToolTip {
                                    text: "Pin to bar"
                                }
                            }

                            // App Context Menu (Right-click)
                            Loader {
                                id: tileMenuLoader
                                active: false
                                sourceComponent: SysTrayMenu {
                                    Component.onCompleted: this.open()
                                    trayItemMenuHandle: appTile.modelData.menu
                                    trayItemId: appTile.modelData.id
                                    anchor {
                                        window: root.anchorItem?.QsWindow?.window
                                        item: appTile
                                        gravity: Config.options.bar.vertical
                                            ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
                                            : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
                                        edges: Config.options.bar.vertical
                                            ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
                                            : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
                                    }
                                    onMenuClosed: tileMenuLoader.active = false
                                }
                            }

                            PopupToolTip {
                                extraVisibleCondition: tileMouseArea.containsMouse && !pinBtn.hovered
                                text: TrayService.getTooltipForItem(appTile.modelData) + "\n• Left click: open\n• Right click: menu\n• Pin icon: keep on bar"
                            }
                        }
                    }
                }

                // Subtitle / Hint
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: TrayService.unpinnedItems.length > 0
                    text: "Right-click or use pin to keep on bar"
                    font.pixelSize: 9
                    color: Appearance.m3colors.m3onSurfaceVariant
                    opacity: 0.6
                }
            }
        }
    }
}

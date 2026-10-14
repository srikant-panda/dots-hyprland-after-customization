pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

PopupWindow {
    id: root

    required property Item anchorItem
    property real popupPadding: 10

    color: "transparent"
    visible: true

    signal popupClosed

    function open() {
        KdeConnectService.refresh();
        root.visible = true;
    }

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

    implicitWidth: 360
    implicitHeight: Math.min(mainColumn.implicitHeight + popupPadding * 2 + 16, 500)

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        StyledRectangularShadow {
            target: popupCard
        }

        Rectangle {
            id: popupCard
            anchors.fill: parent
            anchors.margins: 6
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
                    margins: 12
                }
                spacing: 12

                // Header row: Icon, Title, Actions
                RowLayout {
                    Layout.fillWidth: true
                    height: 28
                    spacing: 6

                    MaterialSymbol {
                        text: "cloud_sync"
                        iconSize: 20
                        color: Appearance.m3colors.m3primary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "File Transfers"
                        font.bold: true
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSurface
                    }

                    // Send File Button
                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: 14
                        colBackground: hovered ? Appearance.colors.colLayer1Hover : "transparent"

                        onPressed: {
                            KdeConnectService.shareFile();
                            root.close();
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "upload_file"
                            iconSize: 18
                            color: Appearance.m3colors.m3onSurface
                        }

                        PopupToolTip {
                            text: "Send file to phone"
                        }
                    }

                    // Clear All Button
                    RippleButton {
                        visible: KdeConnectService.shareCount > 0
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: 14
                        colBackground: hovered ? Appearance.colors.colLayer1Hover : "transparent"

                        onPressed: KdeConnectService.clearShares()

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "delete_sweep"
                            iconSize: 18
                            color: Appearance.m3colors.m3onSurface
                        }

                        PopupToolTip {
                            text: "Clear transfer history"
                        }
                    }

                    // Close Button
                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: 14
                        colBackground: hovered ? Appearance.colors.colLayer1Hover : "transparent"

                        onPressed: root.close()

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 18
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.m3colors.m3outlineVariant
                    opacity: 0.5
                }

                // Empty State
                Loader {
                    Layout.fillWidth: true
                    active: KdeConnectService.shareCount === 0
                    visible: active

                    sourceComponent: ColumnLayout {
                        spacing: 12
                        Layout.alignment: Qt.AlignHCenter

                        Item { height: 8 }

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "folder_shared"
                            iconSize: 36
                            color: Appearance.m3colors.m3outline
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No transfers yet"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurfaceVariant
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            RippleButton {
                                implicitHeight: 32
                                buttonRadius: 8
                                colBackground: Appearance.m3colors.m3primary

                                onPressed: {
                                    KdeConnectService.shareFile();
                                    root.close();
                                }

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol { text: "upload_file"; iconSize: 15; color: Appearance.m3colors.m3onPrimary }
                                    StyledText { text: "Send File"; font.pixelSize: 11; font.bold: true; color: Appearance.m3colors.m3onPrimary }
                                }
                            }

                            RippleButton {
                                implicitHeight: 32
                                buttonRadius: 8
                                colBackground: Appearance.colors.colLayer1

                                onPressed: {
                                    KdeConnectService.sendClipboard();
                                    root.close();
                                }

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol { text: "content_paste_go"; iconSize: 15 }
                                    StyledText { text: "Send Clipboard"; font.pixelSize: 11; font.bold: true }
                                }
                            }
                        }

                        Item { height: 8 }
                    }
                }

                // Shares List
                ListView {
                    id: sharesList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 300)
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds
                    visible: KdeConnectService.shareCount > 0

                    model: KdeConnectService.shares

                    delegate: Rectangle {
                        id: shareItem
                        required property int index
                        required property var modelData

                        width: sharesList.width
                        implicitHeight: shareRow.implicitHeight + 12
                        radius: 8
                        color: shareMouseArea.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }

                        MouseArea {
                            id: shareMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        RowLayout {
                            id: shareRow
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 6
                            }
                            spacing: 8

                            // File icon
                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                text: {
                                    const n = (shareItem.modelData?.name || "").toLowerCase();
                                    if (n.endsWith(".jpg") || n.endsWith(".jpeg") || n.endsWith(".png") || n.endsWith(".webp") || n.endsWith(".gif")) return "image";
                                    if (n.endsWith(".mp4") || n.endsWith(".mkv") || n.endsWith(".webm") || n.endsWith(".avi")) return "movie";
                                    if (n.endsWith(".mp3") || n.endsWith(".flac") || n.endsWith(".wav") || n.endsWith(".ogg")) return "music_note";
                                    if (n.endsWith(".pdf") || n.endsWith(".doc") || n.endsWith(".docx") || n.endsWith(".txt")) return "description";
                                    if (n.endsWith(".zip") || n.endsWith(".tar") || n.endsWith(".gz") || n.endsWith(".7z")) return "folder_zip";
                                    return "draft";
                                }
                                iconSize: 24
                                color: Appearance.m3colors.m3primary
                            }

                            // File details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    Layout.fillWidth: true
                                    text: shareItem.modelData?.name || "Shared file"
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: Appearance.m3colors.m3onSurface
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    spacing: 6
                                    StyledText {
                                        visible: shareItem.modelData?.size && shareItem.modelData.size.length > 0
                                        text: shareItem.modelData?.size || ""
                                        font.pixelSize: 10
                                        color: Appearance.m3colors.m3onSurfaceVariant
                                    }
                                    StyledText {
                                        text: shareItem.modelData?.time || ""
                                        font.pixelSize: 10
                                        color: Appearance.m3colors.m3onSurfaceVariant
                                        opacity: 0.8
                                    }
                                }
                            }

                            // Open File Button
                            RippleButton {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                buttonRadius: 6
                                colBackground: hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                                onPressed: {
                                    if (shareItem.modelData?.path) {
                                        Quickshell.execDetached(["xdg-open", shareItem.modelData.path]);
                                    }
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "open_in_new"
                                    iconSize: 15
                                    color: Appearance.m3colors.m3onSurface
                                }

                                PopupToolTip { text: "Open file" }
                            }

                            // Open Containing Folder Button
                            RippleButton {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                buttonRadius: 6
                                colBackground: hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                                onPressed: {
                                    if (shareItem.modelData?.path) {
                                        Quickshell.execDetached(["bash", "-c", `if which dolphin >/dev/null 2>&1; then dolphin --select "${shareItem.modelData.path}"; else xdg-open "$(dirname "${shareItem.modelData.path}")"; fi`]);
                                    }
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "folder_open"
                                    iconSize: 15
                                    color: Appearance.m3colors.m3onSurface
                                }

                                PopupToolTip { text: "Show in folder" }
                            }

                            // Dismiss Item Button
                            RippleButton {
                                id: dismissShareItemBtn
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                buttonRadius: 11
                                colBackground: hovered ? Appearance.m3colors.m3error : "transparent"

                                onPressed: {
                                    KdeConnectService.deleteShare(shareItem.index);
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 14
                                    color: dismissShareItemBtn.hovered ? Appearance.m3colors.m3onError : Appearance.m3colors.m3onSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

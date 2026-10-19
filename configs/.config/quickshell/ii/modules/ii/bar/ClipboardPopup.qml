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
    property int currentFilter: 0 // 0: All, 1: Text, 2: Images
    property bool confirmClearAll: false

    color: "transparent"
    visible: true

    signal popupClosed

    function open() {
        Cliphist.refresh();
        root.visible = true;
        searchInput.forceActiveFocus();
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

    implicitWidth: 380
    implicitHeight: 520

    Timer {
        id: resetConfirmClearTimer
        interval: 3000
        repeat: false
        onTriggered: root.confirmClearAll = false
    }

    readonly property var filteredEntries: {
        let list = Cliphist.entries;
        const q = searchInput.text.trim();
        if (q !== "") {
            list = Cliphist.fuzzyQuery(q);
        }
        if (root.currentFilter === 1) {
            return list.filter(e => !Cliphist.entryIsImage(e));
        } else if (root.currentFilter === 2) {
            return list.filter(e => Cliphist.entryIsImage(e));
        }
        return list;
    }

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
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    height: 28
                    spacing: 6

                    MaterialSymbol {
                        text: Cliphist.privateMode ? "shield" : "content_paste"
                        iconSize: 20
                        color: Cliphist.privateMode ? Appearance.m3colors.m3tertiary : Appearance.m3colors.m3primary
                    }

                    StyledText {
                        text: Translation.tr("Clipboard")
                        font.bold: true
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSurface
                    }

                    StyledText {
                        text: `(${Cliphist.entries.length})`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.bold: true
                        color: Appearance.m3colors.m3primary
                        visible: Cliphist.entries.length > 0
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Private Mode Toggle Button
                    RippleButton {
                        id: privateToggleBtn
                        implicitHeight: 28
                        implicitWidth: Cliphist.privateMode ? privateBtnRow.implicitWidth + 14 : 28
                        buttonRadius: 14
                        colBackground: Cliphist.privateMode ? Appearance.m3colors.m3tertiaryContainer : (hovered ? Appearance.colors.colLayer1Hover : "transparent")

                        onPressed: Cliphist.togglePrivateMode()

                        contentItem: RowLayout {
                            id: privateBtnRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: Cliphist.privateMode ? "shield" : "security"
                                iconSize: 16
                                color: Cliphist.privateMode ? Appearance.m3colors.m3onTertiaryContainer : Appearance.m3colors.m3onSurface
                            }

                            StyledText {
                                visible: Cliphist.privateMode
                                text: "Private"
                                font.pixelSize: 11
                                font.bold: true
                                color: Appearance.m3colors.m3onTertiaryContainer
                            }
                        }

                        PopupToolTip {
                            text: Cliphist.privateMode ? "Private Mode Active (Click to disable)" : "Turn on Private Mode"
                        }
                    }

                    // Clear All Button
                    RippleButton {
                        id: clearAllBtn
                        implicitWidth: root.confirmClearAll ? confirmRow.implicitWidth + 14 : 28
                        implicitHeight: 28
                        buttonRadius: 14
                        colBackground: root.confirmClearAll ? Appearance.m3colors.m3errorContainer : (hovered ? Appearance.colors.colLayer1Hover : "transparent")

                        onPressed: {
                            if (root.confirmClearAll) {
                                Cliphist.wipe();
                                root.confirmClearAll = false;
                                resetConfirmClearTimer.stop();
                            } else {
                                root.confirmClearAll = true;
                                resetConfirmClearTimer.restart();
                            }
                        }

                        contentItem: RowLayout {
                            id: confirmRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: root.confirmClearAll ? "check" : "delete_sweep"
                                iconSize: 18
                                color: root.confirmClearAll ? Appearance.m3colors.m3error : (clearAllBtn.hovered ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSurface)
                            }

                            StyledText {
                                visible: root.confirmClearAll
                                text: "Clear all?"
                                font.pixelSize: 11
                                font.bold: true
                                color: Appearance.m3colors.m3error
                            }
                        }

                        PopupToolTip {
                            text: root.confirmClearAll ? "Click again to confirm clear all" : "Clear all clipboard history"
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
                    opacity: 0.5
                }

                // Private Mode Notice Banner
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: privateNoticeRow.implicitHeight + 10
                    radius: 8
                    color: Appearance.m3colors.m3tertiaryContainer
                    visible: Cliphist.privateMode

                    RowLayout {
                        id: privateNoticeRow
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 6

                        MaterialSymbol {
                            text: "shield"
                            iconSize: 16
                            color: Appearance.m3colors.m3onTertiaryContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: "Private Mode active — new clips are not recorded."
                            font.pixelSize: 10
                            font.bold: true
                            color: Appearance.m3colors.m3onTertiaryContainer
                            wrapMode: Text.Wrap
                        }

                        RippleButton {
                            implicitHeight: 22
                            implicitWidth: 54
                            buttonRadius: 11
                            colBackground: Appearance.m3colors.m3tertiary

                            onPressed: Cliphist.setPrivateMode(false)

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                text: "Turn off"
                                font.pixelSize: 10
                                font.bold: true
                                color: Appearance.m3colors.m3onTertiary
                            }
                        }
                    }
                }

                // Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: searchInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 6
                        spacing: 6

                        MaterialSymbol {
                            text: "search"
                            iconSize: 18
                            color: searchInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            StyledText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: searchInput.text.length === 0
                                text: "Search clipboard history..."
                                font.pixelSize: 11
                                color: Appearance.m3colors.m3onSurfaceVariant
                                opacity: 0.6
                            }

                            StyledTextInput {
                                id: searchInput
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 11
                                selectByMouse: true
                            }
                        }

                        RippleButton {
                            visible: searchInput.text.length > 0
                            implicitWidth: 20
                            implicitHeight: 20
                            buttonRadius: 10
                            colBackground: hovered ? Appearance.colors.colLayer1Hover : "transparent"

                            onPressed: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: 14
                                color: Appearance.m3colors.m3onSurfaceVariant
                            }
                        }
                    }
                }

                // Filter Chips Row (All, Text, Images)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // All chip
                    RippleButton {
                        implicitHeight: 24
                        implicitWidth: allChipRow.implicitWidth + 16
                        buttonRadius: 12
                        colBackground: root.currentFilter === 0 ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                        colBackgroundHover: root.currentFilter === 0 ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1Hover

                        onPressed: root.currentFilter = 0

                        contentItem: RowLayout {
                            id: allChipRow
                            anchors.centerIn: parent
                            spacing: 4

                            StyledText {
                                text: "All"
                                font.pixelSize: 10
                                font.bold: root.currentFilter === 0
                                color: root.currentFilter === 0 ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                            }

                            StyledText {
                                text: `${Cliphist.entries.length}`
                                font.pixelSize: 9
                                color: root.currentFilter === 0 ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
                                opacity: 0.8
                            }
                        }
                    }

                    // Text chip
                    RippleButton {
                        readonly property int textCount: Cliphist.entries.filter(e => !Cliphist.entryIsImage(e)).length
                        implicitHeight: 24
                        implicitWidth: textChipRow.implicitWidth + 16
                        buttonRadius: 12
                        colBackground: root.currentFilter === 1 ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                        colBackgroundHover: root.currentFilter === 1 ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1Hover

                        onPressed: root.currentFilter = 1

                        contentItem: RowLayout {
                            id: textChipRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: "notes"
                                iconSize: 12
                                color: root.currentFilter === 1 ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
                            }

                            StyledText {
                                text: "Text"
                                font.pixelSize: 10
                                font.bold: root.currentFilter === 1
                                color: root.currentFilter === 1 ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                            }

                            StyledText {
                                text: `${parent.parent.textCount}`
                                font.pixelSize: 9
                                color: root.currentFilter === 1 ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
                                opacity: 0.8
                            }
                        }
                    }

                    // Images chip
                    RippleButton {
                        readonly property int imageCount: Cliphist.entries.filter(e => Cliphist.entryIsImage(e)).length
                        implicitHeight: 24
                        implicitWidth: imgChipRow.implicitWidth + 16
                        buttonRadius: 12
                        colBackground: root.currentFilter === 2 ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                        colBackgroundHover: root.currentFilter === 2 ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1Hover

                        onPressed: root.currentFilter = 2

                        contentItem: RowLayout {
                            id: imgChipRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: "image"
                                iconSize: 12
                                color: root.currentFilter === 2 ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
                            }

                            StyledText {
                                text: "Images"
                                font.pixelSize: 10
                                font.bold: root.currentFilter === 2
                                color: root.currentFilter === 2 ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                            }

                            StyledText {
                                text: `${parent.parent.imageCount}`
                                font.pixelSize: 9
                                color: root.currentFilter === 2 ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
                                opacity: 0.8
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                // Clipboard Items List
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Empty state indicator
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: root.filteredEntries.length === 0
                        spacing: 8

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: searchInput.text.trim() !== "" ? "search_off" : "content_paste_off"
                            iconSize: 36
                            color: Appearance.m3colors.m3onSurfaceVariant
                            opacity: 0.5
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                if (searchInput.text.trim() !== "") return "No matching clipboard items";
                                if (Cliphist.entries.length === 0) return "Clipboard history is empty";
                                return "No items in this category";
                            }
                            font.pixelSize: 12
                            color: Appearance.m3colors.m3onSurfaceVariant
                            opacity: 0.7
                        }
                    }

                    StyledListView {
                        id: clipList
                        anchors.fill: parent
                        clip: true
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds
                        visible: root.filteredEntries.length > 0
                        model: root.filteredEntries

                        delegate: Rectangle {
                            id: itemDelegate
                            required property var modelData
                            readonly property bool isImage: Cliphist.entryIsImage(itemDelegate.modelData)
                            readonly property bool isMedia: Cliphist.entryIsMedia(itemDelegate.modelData)
                            readonly property string rawText: itemDelegate.modelData ? itemDelegate.modelData.replace(/^\d+\t/, "") : ""
                            property bool copiedFeedback: false
                            property bool copiedPathFeedback: false

                            Timer {
                                id: feedbackTimer
                                interval: 1000
                                repeat: false
                                onTriggered: {
                                    itemDelegate.copiedFeedback = false;
                                    itemDelegate.copiedPathFeedback = false;
                                }
                            }

                            function copyThis() {
                                Cliphist.copy(itemDelegate.modelData);
                                itemDelegate.copiedFeedback = true;
                                itemDelegate.copiedPathFeedback = false;
                                feedbackTimer.restart();
                            }

                            function copyFilePath() {
                                Cliphist.copyPath(itemDelegate.modelData);
                                itemDelegate.copiedFeedback = true;
                                itemDelegate.copiedPathFeedback = true;
                                feedbackTimer.restart();
                            }

                            width: clipList.width
                            implicitHeight: itemContentRow.implicitHeight + 12
                            radius: 8
                            color: itemMouseArea.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
                            border.width: 1
                            border.color: itemDelegate.copiedFeedback
                                ? Appearance.m3colors.m3primary
                                : (itemMouseArea.containsMouse ? Appearance.m3colors.m3outlineVariant : "transparent")

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Cliphist.copy(itemDelegate.modelData);
                                    root.close();
                                }
                            }

                            RowLayout {
                                id: itemContentRow
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: 6
                                }
                                spacing: 8

                                // Type indicator icon
                                Item {
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    Layout.alignment: Qt.AlignTop

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: itemDelegate.copiedFeedback ? "check" : (itemDelegate.isImage ? "image" : "notes")
                                        iconSize: 16
                                        color: itemDelegate.copiedFeedback
                                            ? Appearance.m3colors.m3primary
                                            : (itemDelegate.isImage ? Appearance.m3colors.m3tertiary : Appearance.m3colors.m3onSurfaceVariant)
                                    }
                                }

                                // Content Area (Text or Image)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    // If Image
                                    Loader {
                                        active: itemDelegate.isImage
                                        visible: active
                                        Layout.fillWidth: true
                                        sourceComponent: ColumnLayout {
                                            spacing: 4
                                            CliphistImage {
                                                entry: itemDelegate.modelData
                                                maxWidth: 200
                                                maxHeight: 100
                                            }
                                            StyledText {
                                                text: itemDelegate.rawText
                                                font.pixelSize: 9
                                                color: Appearance.m3colors.m3onSurfaceVariant
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }

                                    // If Text
                                    StyledText {
                                        visible: !itemDelegate.isImage
                                        Layout.fillWidth: true
                                        text: itemDelegate.rawText
                                        font.pixelSize: 11
                                        font.family: Appearance.font.family.main
                                        color: Appearance.m3colors.m3onSurface
                                        wrapMode: Text.WrapAnywhere
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }

                                    // Copied feedback label
                                    StyledText {
                                        visible: itemDelegate.copiedFeedback
                                        text: itemDelegate.copiedPathFeedback ? "File path copied to clipboard!" : "Copied to clipboard!"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: Appearance.m3colors.m3primary
                                    }
                                }

                                // Action Buttons: Copy, Copy Path & Individual Delete
                                RowLayout {
                                    Layout.alignment: Qt.AlignTop
                                    spacing: 2

                                    // Copy Path button (images and media items)
                                    RippleButton {
                                        id: copyPathItemBtn
                                        visible: itemDelegate.isMedia
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        buttonRadius: 12
                                        colBackground: hovered ? Appearance.colors.colLayer2Hover : "transparent"

                                        onPressed: itemDelegate.copyFilePath()

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: itemDelegate.copiedPathFeedback ? "check" : "link"
                                            iconSize: 14
                                            color: itemDelegate.copiedPathFeedback ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
                                        }

                                        PopupToolTip {
                                            text: "Copy file path"
                                        }
                                    }

                                    // Copy button
                                    RippleButton {
                                        id: copyItemBtn
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        buttonRadius: 12
                                        colBackground: hovered ? Appearance.colors.colLayer2Hover : "transparent"

                                        onPressed: itemDelegate.copyThis()

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: (itemDelegate.copiedFeedback && !itemDelegate.copiedPathFeedback) ? "check" : "content_copy"
                                            iconSize: 14
                                            color: (itemDelegate.copiedFeedback && !itemDelegate.copiedPathFeedback) ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
                                        }

                                        PopupToolTip {
                                            text: "Copy to clipboard"
                                        }
                                    }

                                    // Individual Delete button
                                    RippleButton {
                                        id: deleteItemBtn
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        buttonRadius: 12
                                        colBackground: hovered ? Appearance.m3colors.m3errorContainer : "transparent"

                                        onPressed: {
                                            Cliphist.deleteEntry(itemDelegate.modelData);
                                        }

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "delete"
                                            iconSize: 14
                                            color: deleteItemBtn.hovered ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSurfaceVariant
                                        }

                                        PopupToolTip {
                                            text: "Delete this item"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

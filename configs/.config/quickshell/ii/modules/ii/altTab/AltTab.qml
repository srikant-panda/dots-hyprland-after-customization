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
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: altTabScope

    property bool open: false
    property int selectedIndex: 0
    property var windows: []
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    readonly property var currentSelectedWindow: (windows && windows.length > selectedIndex && selectedIndex >= 0) ? windows[selectedIndex] : null

    function getAppIcon(win) {
        if (!win) return "application-x-executable";
        let icon = AppSearch.guessIcon(win.class);
        if (!icon || icon === "image-missing") {
            icon = AppSearch.guessIcon(win.initialClass);
        }
        if (!icon || icon === "image-missing") {
            if (win.class && win.class.includes("chrome-")) {
                return "google-chrome";
            }
            return "application-x-executable";
        }
        return icon;
    }

    function getAppName(win) {
        if (!win) return "Window";
        if (win.class && win.class.includes("chrome-")) {
            if (win.title && win.title.includes("YouTube")) return "YouTube";
            return "Chrome App";
        }
        const entry = DesktopEntries.byId(win.class);
        if (entry && entry.name) return entry.name;
        if (win.class && win.class.length > 0) {
            return win.class.charAt(0).toUpperCase() + win.class.slice(1);
        }
        return win.initialClass || "Window";
    }

    function refreshWindows() {
        const allWins = HyprlandData.windowList || [];
        let validWins = allWins.filter(w => {
            return w && w.mapped && !w.hidden && w.workspace && (w.workspace.id >= 1 || (w.workspace.name && w.workspace.name.length > 0));
        });
        validWins.sort((a, b) => (a.focusHistoryID ?? 999) - (b.focusHistoryID ?? 999));

        const toplevelList = ToplevelManager.toplevels.values;
        for (let i = 0; i < validWins.length; i++) {
            const win = validWins[i];
            const addr = (win.address || "").toLowerCase().replace(/^0x/, "");
            win.toplevel = toplevelList.find(t => {
                if (!t || !t.HyprlandToplevel) return false;
                const tAddr = (t.HyprlandToplevel.address || "").toLowerCase().replace(/^0x/, "");
                return tAddr === addr;
            }) || null;
        }

        altTabScope.windows = validWins;
        return validWins;
    }

    function ensureVisible() {
        if (switcherLoader.item && switcherLoader.item.listView) {
            switcherLoader.item.listView.positionViewAtIndex(altTabScope.selectedIndex, ListView.Contain);
        }
    }

    function next() {
        if (!altTabScope.open) {
            const list = refreshWindows();
            if (list.length === 0) return;
            altTabScope.open = true;
            altTabScope.selectedIndex = (list.length > 1) ? 1 : 0;
        } else {
            if (altTabScope.windows.length === 0) return;
            altTabScope.selectedIndex = (altTabScope.selectedIndex + 1) % altTabScope.windows.length;
        }
        ensureVisible();
    }

    function prev() {
        if (!altTabScope.open) {
            const list = refreshWindows();
            if (list.length === 0) return;
            altTabScope.open = true;
            altTabScope.selectedIndex = list.length - 1;
        } else {
            if (altTabScope.windows.length === 0) return;
            altTabScope.selectedIndex = (altTabScope.selectedIndex - 1 + altTabScope.windows.length) % altTabScope.windows.length;
        }
        ensureVisible();
    }

    function commit() {
        if (!altTabScope.open) return;
        const target = altTabScope.currentSelectedWindow;
        altTabScope.open = false;
        if (target && target.address) {
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:${target.address}" })`);
        }
        Hyprland.dispatch('hl.dsp.submap("reset")');
    }

    function cancel() {
        if (!altTabScope.open) return;
        altTabScope.open = false;
        Hyprland.dispatch('hl.dsp.submap("reset")');
    }

    function selectIndex(index) {
        if (index >= 0 && index < altTabScope.windows.length) {
            altTabScope.selectedIndex = index;
            altTabScope.commit();
        }
    }

    function closeWindow(win) {
        if (!win) return;
        if (win.address) {
            Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${win.address}" })`);
        } else if (win.toplevel) {
            win.toplevel.close();
        }
        const updated = altTabScope.windows.filter(w => w.address !== win.address);
        altTabScope.windows = updated;
        if (updated.length === 0) {
            altTabScope.cancel();
        } else if (altTabScope.selectedIndex >= updated.length) {
            altTabScope.selectedIndex = updated.length - 1;
        }
    }

    // Listen to Hyprland submap reset events as an extra automatic commit fallback
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "submap") {
                if (event.data === "" && altTabScope.open) {
                    altTabScope.commit();
                }
            }
        }
    }

    IpcHandler {
        target: "altTab"

        function next(): void {
            altTabScope.next();
        }
        function prev(): void {
            altTabScope.prev();
        }
        function commit(): void {
            altTabScope.commit();
        }
        function cancel(): void {
            altTabScope.cancel();
        }
        function closeCurrent(): void {
            if (altTabScope.currentSelectedWindow) {
                altTabScope.closeWindow(altTabScope.currentSelectedWindow);
            }
        }
    }

    GlobalShortcut {
        name: "altTabNext"
        description: "Visual Switcher: Next window"
        onPressed: altTabScope.next()
    }

    GlobalShortcut {
        name: "altTabPrev"
        description: "Visual Switcher: Previous window"
        onPressed: altTabScope.prev()
    }

    GlobalShortcut {
        name: "altTabCommit"
        description: "Visual Switcher: Commit selection"
        onPressed: altTabScope.commit()
        onReleased: altTabScope.commit()
    }

    GlobalShortcut {
        name: "altTabCancel"
        description: "Visual Switcher: Cancel switcher"
        onPressed: altTabScope.cancel()
        onReleased: altTabScope.cancel()
    }


    Loader {
        id: switcherLoader
        active: altTabScope.open

        sourceComponent: PanelWindow {
            id: switcherWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(switcherWindow.screen)
            property alias listView: windowListView

            screen: altTabScope.focusedScreen
            visible: altTabScope.open

            WlrLayershell.namespace: "quickshell:altTab"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }


            // Dim backdrop
            Rectangle {
                anchors.fill: parent
                color: "#48000000"

                MouseArea {
                    anchors.fill: parent
                    onClicked: altTabScope.cancel()
                }
            }

            // Centered HUD dialog
            Rectangle {
                id: hudCard
                anchors.centerIn: parent
                radius: 24
                color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.08)
                border.color: Appearance.m3colors.m3outlineVariant
                border.width: 1

                implicitWidth: Math.min(Math.max(windowListView.contentWidth + 56, 440), switcherWindow.width - 64)
                implicitHeight: mainColumn.implicitHeight + 36

                ColumnLayout {
                    id: mainColumn
                    anchors.centerIn: parent
                    spacing: 16
                    width: hudCard.implicitWidth - 36

                    // Windows Horizontal ListView with direct window previews
                    ListView {
                        id: windowListView
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 188
                        Layout.preferredWidth: Math.min(contentWidth, hudCard.implicitWidth - 44)
                        orientation: ListView.Horizontal
                        spacing: 14
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        model: altTabScope.windows

                        delegate: Rectangle {
                            id: itemCard
                            required property int index
                            required property var modelData

                            readonly property bool isSelected: index === altTabScope.selectedIndex
                            readonly property bool isHovered: itemMouseArea.containsMouse

                            width: 236
                            height: 184
                            radius: 16

                            color: isSelected 
                                ? Appearance.m3colors.m3primaryContainer 
                                : (isHovered ? Appearance.m3colors.m3surfaceContainerHigh : Appearance.m3colors.m3surfaceContainerLow)

                            border.color: isSelected 
                                ? Appearance.m3colors.m3primary 
                                : (isHovered ? Appearance.m3colors.m3outline : Appearance.m3colors.m3outlineVariant)
                            border.width: isSelected ? 2.5 : 1

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 120 }
                            }

                            // Card Click to Select
                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    altTabScope.selectedIndex = itemCard.index;
                                }
                                onClicked: {
                                    altTabScope.selectIndex(itemCard.index);
                                }
                            }

                            // Card Header: App Icon, Name, Workspace Badge & Close Button
                            RowLayout {
                                id: cardHeader
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: 8
                                    bottomMargin: 4
                                }
                                height: 26
                                spacing: 6

                                // Small app icon
                                IconImage {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignVCenter
                                    source: Quickshell.iconPath(altTabScope.getAppIcon(itemCard.modelData), "application-x-executable")
                                }

                                // App Name
                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: altTabScope.getAppName(itemCard.modelData)
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    color: itemCard.isSelected 
                                        ? Appearance.m3colors.m3onPrimaryContainer 
                                        : Appearance.m3colors.m3onSurface
                                }

                                // Workspace Badge Pill
                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 6
                                    height: 18
                                    implicitWidth: wsText.implicitWidth + 8
                                    color: itemCard.isSelected 
                                        ? Appearance.m3colors.m3primary 
                                        : Appearance.m3colors.m3surfaceContainerHighest

                                    Text {
                                        id: wsText
                                        anchors.centerIn: parent
                                        text: itemCard.modelData?.workspace?.name ? ("WS " + itemCard.modelData.workspace.name) : ""
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: itemCard.isSelected 
                                            ? Appearance.m3colors.m3onPrimary 
                                            : Appearance.m3colors.m3onSurfaceVariant
                                    }
                                }

                                // Close Button (X)
                                Rectangle {
                                    id: closeBtn
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    radius: 11
                                    color: closeBtnMouse.containsMouse 
                                        ? Appearance.m3colors.m3error 
                                        : ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHighest, 0.4)

                                    Behavior on color {
                                        ColorAnimation { duration: 100 }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: closeBtnMouse.containsMouse 
                                            ? Appearance.m3colors.m3onError 
                                            : Appearance.m3colors.m3onSurfaceVariant
                                    }

                                    MouseArea {
                                        id: closeBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: event => {
                                            event.accepted = true;
                                            altTabScope.closeWindow(itemCard.modelData);
                                        }
                                    }
                                }
                            }

                            // Direct Live Window Preview Body
                            Rectangle {
                                id: previewContainer
                                anchors {
                                    top: cardHeader.bottom
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: 8
                                    topMargin: 2
                                }
                                radius: 10
                                clip: true
                                color: Appearance.m3colors.m3surfaceContainerLowest
                                border.color: Appearance.m3colors.m3outlineVariant
                                border.width: 1

                                ScreencopyView {
                                    id: livePreview
                                    anchors.centerIn: parent
                                    captureSource: itemCard.modelData?.toplevel ?? null
                                    live: true
                                    paintCursor: false
                                    constraintSize: Qt.size(216, 134)
                                }

                                // Fallback icon when screencopy is not yet available
                                IconImage {
                                    anchors.centerIn: parent
                                    width: 52
                                    height: 52
                                    visible: !itemCard.modelData?.toplevel
                                    source: Quickshell.iconPath(altTabScope.getAppIcon(itemCard.modelData), "application-x-executable")
                                }
                            }
                        }
                    }

                    // Selected Window Title & Details Footer
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            Layout.maximumWidth: hudCard.implicitWidth - 48
                            horizontalAlignment: Text.AlignHCenter
                            text: altTabScope.currentSelectedWindow?.title || ""
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideMiddle
                            color: Appearance.m3colors.m3onSurface
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: {
                                const win = altTabScope.currentSelectedWindow;
                                if (!win) return "";
                                const ws = win.workspace?.name ? ("Workspace " + win.workspace.name) : "";
                                const cls = win.class ? win.class : "";
                                return ws && cls ? (ws + "  •  " + cls) : (ws || cls);
                            }
                            font.pixelSize: 11
                            color: Appearance.m3colors.m3onSurfaceVariant
                            opacity: 0.85
                        }
                    }
                }
            }
        }
    }
}

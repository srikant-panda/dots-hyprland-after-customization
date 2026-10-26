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

    function computePyramidRows(total, maxRowLimit) {
        if (total <= 0) return [];
        const maxLimit = maxRowLimit || 5;
        // Wrap only if needed: 1 to maxLimit windows stay on a single row
        if (total <= maxLimit) return [total];

        // 2-row downward pyramids:
        if (total === 6) return [4, 2];
        if (total === 7) return [4, 3];
        if (total === 8) return [5, 3];
        if (total === 9) return [5, 4];

        // 3-row downward pyramids:
        if (total === 10) return [5, 3, 2];
        if (total === 11) return [5, 4, 2];
        if (total === 12) return [5, 4, 3];
        if (total === 13) return [5, 5, 3];
        if (total === 14) return [5, 5, 4];
        if (total === 15) return [5, 4, 3, 3];

        let counts = [];
        let rem = total;
        while (rem > 0) {
            let count = Math.min(maxLimit, Math.ceil(rem / 2));
            if (counts.length > 0 && count > counts[counts.length - 1]) {
                count = counts[counts.length - 1];
            }
            count = Math.min(count, rem);
            counts.push(count);
            rem -= count;
        }
        return counts;
    }

    function getPyramidRowGroups(winList) {
        if (!winList || winList.length === 0) return [];
        const total = winList.length;
        const rowCounts = altTabScope.computePyramidRows(total, 5);
        let groups = [];
        let cursor = 0;
        for (let r = 0; r < rowCounts.length; r++) {
            const count = rowCounts[r];
            const rowWindows = [];
            for (let i = 0; i < count && cursor < total; i++) {
                const w = winList[cursor];
                w.globalIndex = cursor;
                rowWindows.push(w);
                cursor++;
            }
            groups.push(rowWindows);
        }
        return groups;
    }

    readonly property var rowGroups: getPyramidRowGroups(windows)

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

    function wsKey(w) {
        if (!w || !w.workspace) return 999999;
        const id = w.workspace.id;
        if (id >= 1) return id;
        return 100000 + Math.abs(id);
    }

    function refreshWindows() {
        altTabScope.focusedScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];

        const allWins = HyprlandData.windowList || [];
        let validWins = allWins.filter(w => {
            return w && w.mapped && !w.hidden && w.workspace && (w.workspace.id >= 1 || (w.workspace.name && w.workspace.name.length > 0));
        });

        if (validWins.length === 0) {
            altTabScope.windows = [];
            return { list: [], activeIndex: 0 };
        }

        // Strict, physical Left-to-Right serial sort:
        // 1. Workspace ID ascending (WS 1 -> WS 2 -> WS 3)
        // 2. Physical X coordinate ascending (left to right)
        // 3. Physical Y coordinate ascending (top to bottom)
        // 4. Stable tie-breaker: address
        validWins.sort((a, b) => {
            const diffWs = wsKey(a) - wsKey(b);
            if (diffWs !== 0) return diffWs;

            const diffX = (a.at?.[0] ?? 0) - (b.at?.[0] ?? 0);
            if (diffX !== 0) return diffX;

            const diffY = (a.at?.[1] ?? 0) - (b.at?.[1] ?? 0);
            if (diffY !== 0) return diffY;

            return (a.address || "").localeCompare(b.address || "");
        });

        // Identify currently active window
        let currentAddr = "";
        if (ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.HyprlandToplevel) {
            const raw = ToplevelManager.activeToplevel.HyprlandToplevel.address || "";
            if (raw) currentAddr = "0x" + raw.toLowerCase().replace(/^0x/, "");
        }
        if (!currentAddr) {
            const fh0 = allWins.find(w => w && w.focusHistoryID === 0);
            if (fh0 && fh0.address) {
                currentAddr = fh0.address.toLowerCase();
            }
        }

        // Connect toplevels for ScreencopyView live thumbnails and find activeIndex
        const toplevelList = ToplevelManager.toplevels.values;
        let activeIndex = -1;
        for (let i = 0; i < validWins.length; i++) {
            const win = validWins[i];
            const addr = (win.address || "").toLowerCase().replace(/^0x/, "");
            win.toplevel = toplevelList.find(t => {
                if (!t || !t.HyprlandToplevel) return false;
                const tAddr = (t.HyprlandToplevel.address || "").toLowerCase().replace(/^0x/, "");
                return tAddr === addr;
            }) || null;

            if (currentAddr && (win.address || "").toLowerCase() === currentAddr) {
                activeIndex = i;
            }
        }

        if (activeIndex === -1) {
            activeIndex = validWins.findIndex(w => w && w.focusHistoryID === 0);
        }
        if (activeIndex === -1) {
            activeIndex = 0;
        }

        // Mark the starting/current active window and assign globalIndex
        for (let i = 0; i < validWins.length; i++) {
            validWins[i].globalIndex = i;
            validWins[i].isCurrent = (i === activeIndex);
        }

        altTabScope.windows = validWins;
        return { list: validWins, activeIndex: activeIndex };
    }

    function ensureVisible() {
    }

    function next() {
        if (!altTabScope.open) {
            const res = refreshWindows();
            const list = res.list;
            if (!list || list.length === 0) return;
            altTabScope.open = true;
            // Left-to-Right: move from current window to next window on the right
            const startIdx = res.activeIndex;
            altTabScope.selectedIndex = (list.length > 1) ? ((startIdx + 1) % list.length) : 0;
        } else {
            if (altTabScope.windows.length === 0) return;
            // Advance forward: Left to Right
            altTabScope.selectedIndex = (altTabScope.selectedIndex + 1) % altTabScope.windows.length;
        }
        ensureVisible();
    }

    function prev() {
        if (!altTabScope.open) {
            const res = refreshWindows();
            const list = res.list;
            if (!list || list.length === 0) return;
            altTabScope.open = true;
            // Reverse (Shift enabled): move from current window to previous window on the left
            const startIdx = res.activeIndex;
            altTabScope.selectedIndex = (list.length > 1) ? ((startIdx - 1 + list.length) % list.length) : 0;
        } else {
            if (altTabScope.windows.length === 0) return;
            // Advance backward: Reverse
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
        for (let i = 0; i < updated.length; i++) {
            updated[i].globalIndex = i;
        }
        altTabScope.windows = updated;
        if (updated.length === 0) {
            altTabScope.cancel();
        } else if (altTabScope.selectedIndex >= updated.length) {
            altTabScope.selectedIndex = updated.length - 1;
        }
    }

    // Fallback: commit if Hyprland submap resets
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

    GlobalShortcut {
        name: "altTabClose"
        description: "Visual Switcher: Close selected window"
        onPressed: {
            if (altTabScope.currentSelectedWindow) {
                altTabScope.closeWindow(altTabScope.currentSelectedWindow);
            }
        }
    }

    PanelWindow {
        id: switcherWindow
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(switcherWindow.screen)

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

            implicitWidth: Math.min(Math.max(pyramidColumn.implicitWidth + 48, 380), switcherWindow.width - 64)
            implicitHeight: Math.min(mainColumn.implicitHeight + 36, switcherWindow.height - 64)

            readonly property int cardWidth: 200
            readonly property int cardHeight: 154
            readonly property int cardSpacing: 12

            ColumnLayout {
                id: mainColumn
                anchors.centerIn: parent
                spacing: 14
                width: hudCard.implicitWidth - 36

                // Downward Pyramid Window Grid
                Column {
                    id: pyramidColumn
                    Layout.alignment: Qt.AlignHCenter
                    spacing: hudCard.cardSpacing

                    Repeater {
                        id: rowRepeater
                        model: altTabScope.rowGroups

                        Row {
                            id: rowLayout
                            required property var modelData
                            required property int index
                            readonly property var rowItems: modelData

                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: hudCard.cardSpacing

                            Repeater {
                                model: rowLayout.rowItems

                                delegate: Rectangle {
                                    id: itemCard
                                    required property int index
                                    required property var modelData

                                    readonly property int gIndex: itemCard.modelData?.globalIndex ?? index
                                    readonly property bool isSelected: gIndex === altTabScope.selectedIndex
                                    readonly property bool isHovered: itemMouseArea.containsMouse
                                    readonly property bool isCurrent: itemCard.modelData?.isCurrent ?? false

                                    width: hudCard.cardWidth
                                    height: hudCard.cardHeight
                                    radius: 14

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
                                    altTabScope.selectedIndex = itemCard.gIndex;
                                }
                                onClicked: {
                                    altTabScope.selectIndex(itemCard.gIndex);
                                }
                            }

                            // Card Header: App Icon, Name, Starting/Current Badge, Workspace Badge & Close Button
                            RowLayout {
                                id: cardHeader
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: 7
                                    bottomMargin: 3
                                }
                                height: 24
                                spacing: 5

                                // Small app icon
                                IconImage {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    Layout.alignment: Qt.AlignVCenter
                                    source: Quickshell.iconPath(altTabScope.getAppIcon(itemCard.modelData), "application-x-executable")
                                }

                                // App Name
                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: altTabScope.getAppName(itemCard.modelData)
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                    color: itemCard.isSelected 
                                        ? Appearance.m3colors.m3onPrimaryContainer 
                                        : Appearance.m3colors.m3onSurface
                                }

                                // Starting Window Badge (Current)
                                Rectangle {
                                    visible: itemCard.isCurrent
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 5
                                    height: 16
                                    implicitWidth: currentBadgeText.implicitWidth + 6
                                    color: itemCard.isSelected 
                                        ? Appearance.m3colors.m3primary 
                                        : ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.2)

                                    Text {
                                        id: currentBadgeText
                                        anchors.centerIn: parent
                                        text: "Current"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: itemCard.isSelected 
                                            ? Appearance.m3colors.m3onPrimary 
                                            : Appearance.m3colors.m3onSecondaryContainer
                                    }
                                }

                                // Workspace Badge Pill
                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 5
                                    height: 16
                                    implicitWidth: wsText.implicitWidth + 6
                                    color: itemCard.isSelected 
                                        ? Appearance.m3colors.m3primary 
                                        : Appearance.m3colors.m3surfaceContainerHighest

                                    Text {
                                        id: wsText
                                        anchors.centerIn: parent
                                        text: itemCard.modelData?.workspace?.name ? ("WS " + itemCard.modelData.workspace.name) : ""
                                        font.pixelSize: 9
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
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    radius: 10
                                    color: closeBtnMouse.containsMouse 
                                        ? Appearance.m3colors.m3error 
                                        : ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHighest, 0.4)

                                    Behavior on color {
                                        ColorAnimation { duration: 100 }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 9
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
                                    margins: 6
                                    topMargin: 2
                                }
                                radius: 8
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
                                    constraintSize: Qt.size(184, 110)
                                }

                                // Fallback icon when screencopy is not yet available
                                IconImage {
                                    anchors.centerIn: parent
                                    width: 44
                                    height: 44
                                    visible: !itemCard.modelData?.toplevel
                                    source: Quickshell.iconPath(altTabScope.getAppIcon(itemCard.modelData), "application-x-executable")
                                }
                            }
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

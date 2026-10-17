import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    readonly property var screen: root.QsWindow.window?.screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

    // Bounded responsive width: prevents runaway text from breaking top bar responsiveness
    readonly property real maxWidth: Math.min(240, Math.max(140, (screen?.width ?? 1920) * 0.14))
    implicitWidth: Math.min(maxWidth, Math.max(1, colLayout.implicitWidth))
    implicitHeight: Appearance.sizes.baseBarHeight
    Layout.maximumWidth: maxWidth

    function truncateText(str, maxLen) {
        if (!str) return ""
        str = String(str).replace(/\s+/g, " ").trim()
        if (str.length <= maxLen) return str
        return str.substring(0, maxLen).trim() + "..."
    }

    ColumnLayout {
        id: colLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: -4

        StyledText {
            Layout.fillWidth: true
            Layout.maximumWidth: root.maxWidth
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: root.truncateText(root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
                root.activeWindow?.appId :
                (root.biggestWindow?.class) ?? Translation.tr("Desktop"), 24)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.maximumWidth: root.maxWidth
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: root.truncateText(root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
                root.activeWindow?.title :
                (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`, 28)
        }

    }

}

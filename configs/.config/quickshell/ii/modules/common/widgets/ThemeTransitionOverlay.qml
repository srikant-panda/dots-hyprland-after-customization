import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs.modules.common
import qs.services

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: transitionWindow
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:theme-transition"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {
                item: null
            }

            visible: MaterialThemeLoader.revealActive

            readonly property real screenX: modelData.x
            readonly property real screenY: modelData.y
            readonly property real screenW: modelData.width
            readonly property real screenH: modelData.height

            // Calculate origin relative to this monitor
            readonly property real originX: MaterialThemeLoader.revealOriginX - screenX
            readonly property real originY: MaterialThemeLoader.revealOriginY - screenY

            // Calculate distance to the furthest corner of this screen
            readonly property real d1: Math.hypot(originX, originY)
            readonly property real d2: Math.hypot(screenW - originX, originY)
            readonly property real d3: Math.hypot(originX, screenH - originY)
            readonly property real d4: Math.hypot(screenW - originX, screenH - originY)
            readonly property real maxRadius: Math.max(d1, d2, d3, d4) + 80

            // Current radius based on revealProgress (0.0 -> 1.0)
            readonly property real currentRadius: MaterialThemeLoader.revealProgress * maxRadius

            // Screenshot of old desktop appearance
            Image {
                id: snapshotImage
                anchors.fill: parent
                source: MaterialThemeLoader.snapshotTimestamp !== ""
                    ? `file:///tmp/quickshell/media/theme_snapshots/${modelData.name}_${MaterialThemeLoader.snapshotTimestamp}.jpg`
                    : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                visible: false
            }

            // Expanding circular mask (the hole)
            Item {
                id: maskContainer
                anchors.fill: parent
                visible: false

                Rectangle {
                    x: transitionWindow.originX - transitionWindow.currentRadius
                    y: transitionWindow.originY - transitionWindow.currentRadius
                    width: transitionWindow.currentRadius * 2
                    height: transitionWindow.currentRadius * 2
                    radius: transitionWindow.currentRadius
                    color: "white"
                }
            }

            // Masked screenshot: hole reveals new live desktop beneath
            OpacityMask {
                anchors.fill: parent
                source: snapshotImage
                maskSource: maskContainer
                invert: true
                visible: transitionWindow.currentRadius < transitionWindow.maxRadius
            }

            // Expanding Light-Orb Ring & Glowing Boundary
            Rectangle {
                id: lightOrb
                x: transitionWindow.originX - transitionWindow.currentRadius
                y: transitionWindow.originY - transitionWindow.currentRadius
                width: transitionWindow.currentRadius * 2
                height: transitionWindow.currentRadius * 2
                radius: transitionWindow.currentRadius
                color: "transparent"
                border.width: 3
                border.color: MaterialThemeLoader.targetDark ? "#FFFFFF" : "#FFE58F"
                opacity: (transitionWindow.currentRadius > 8 && transitionWindow.currentRadius < transitionWindow.maxRadius - 30) ? 0.95 : 0.0

                // Outer soft aura glow
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 10
                    height: parent.height + 10
                    radius: width / 2
                    color: "transparent"
                    border.width: 5
                    border.color: MaterialThemeLoader.targetDark ? "#55FFFFFF" : "#55FFE58F"
                }

                // Inner soft aura glow
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - 6)
                    height: Math.max(0, parent.height - 6)
                    radius: width / 2
                    color: "transparent"
                    border.width: 3
                    border.color: MaterialThemeLoader.targetDark ? "#75FFFFFF" : "#75FFE58F"
                }
            }
        }
    }
}

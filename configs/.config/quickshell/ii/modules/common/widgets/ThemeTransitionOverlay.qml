import QtQuick
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

            visible: MaterialThemeLoader.isTransitioning || veil.opacity > 0.001

            Item {
                id: veilContainer
                anchors.fill: parent
                transformOrigin: Item.Center
                scale: MaterialThemeLoader.isTransitioning ? 1.0 : 1.06

                Behavior on scale {
                    NumberAnimation {
                        duration: 550
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    id: veil
                    anchors.fill: parent
                    color: MaterialThemeLoader.targetDark ? "#0A090D" : "#FAF5FF"
                    opacity: MaterialThemeLoader.isTransitioning ? 0.28 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: MaterialThemeLoader.isTransitioning ? 200 : 450
                            easing.type: MaterialThemeLoader.isTransitioning ? Easing.OutCubic : Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }
}

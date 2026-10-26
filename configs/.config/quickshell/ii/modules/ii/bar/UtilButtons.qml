import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        Loader {
            active: Config.options.bar.utilButtons.showScreenSnip
            visible: Config.options.bar.utilButtons.showScreenSnip
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "screenshot_region"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showScreenRecord
            visible: Config.options.bar.utilButtons.showScreenRecord
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached([Directories.recordScriptPath])
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "videocam"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showColorPicker
            visible: Config.options.bar.utilButtons.showColorPicker
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached(["hyprpicker", "-a"])
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "colorize"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showKeyboardToggle
            visible: Config.options.bar.utilButtons.showKeyboardToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: GlobalStates.oskOpen = !GlobalStates.oskOpen
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: "keyboard"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showMicToggle
            visible: Config.options.bar.utilButtons.showMicToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"])
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: Pipewire.defaultAudioSource?.audio?.muted ? "mic_off" : "mic"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showDarkModeToggle
            visible: Config.options.bar.utilButtons.showDarkModeToggle
            sourceComponent: CircleUtilButton {
                id: darkLightBtn
                Layout.alignment: Qt.AlignVCenter
                enabled: !MaterialThemeLoader.isSwitching
                opacity: MaterialThemeLoader.isSwitching ? 0.35 : 1.0
                pointingHandCursor: !MaterialThemeLoader.isSwitching

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                onClicked: event => {
                    if (!MaterialThemeLoader.isSwitching) {
                        MaterialThemeLoader.toggleLightDark()
                    }
                }

                Item {
                    id: iconContainer
                    implicitWidth: Appearance.font.pixelSize.large
                    implicitHeight: Appearance.font.pixelSize.large
                    anchors.centerIn: parent

                    property bool displayDark: MaterialThemeLoader.targetDark
                    readonly property bool targetDark: MaterialThemeLoader.targetDark

                    onTargetDarkChanged: {
                        zoomAnim.restart()
                    }

                    SequentialAnimation {
                        id: zoomAnim
                        ParallelAnimation {
                            NumberAnimation {
                                target: darkLightIcon
                                property: "scale"
                                to: 0.0
                                duration: 150
                                easing.type: Easing.InBack
                                easing.overshoot: 1.1
                            }
                            NumberAnimation {
                                target: darkLightIcon
                                property: "opacity"
                                to: 0.0
                                duration: 130
                                easing.type: Easing.InQuad
                            }
                        }
                        ScriptAction {
                            script: {
                                iconContainer.displayDark = iconContainer.targetDark
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: darkLightIcon
                                property: "scale"
                                from: 0.0
                                to: 1.0
                                duration: 250
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                            NumberAnimation {
                                target: darkLightIcon
                                property: "opacity"
                                from: 0.0
                                to: 1.0
                                duration: 200
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    MaterialSymbol {
                        id: darkLightIcon
                        anchors.centerIn: parent
                        horizontalAlignment: Qt.AlignHCenter
                        fill: 0
                        text: MaterialThemeLoader.isSwitching ? "sync" : (iconContainer.displayDark ? "light_mode" : "dark_mode")
                        iconSize: Appearance.font.pixelSize.large
                        color: MaterialThemeLoader.isSwitching ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer2

                        rotation: 0
                        NumberAnimation on rotation {
                            running: MaterialThemeLoader.isSwitching
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 350
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showPerformanceProfileToggle
            visible: Config.options.bar.utilButtons.showPerformanceProfileToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: event => {
                    if (PowerProfiles.hasPerformanceProfile) {
                        switch(PowerProfiles.profile) {
                            case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced
                            break;
                            case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance
                            break;
                            case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver
                            break;
                        }
                    } else {
                        PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced
                    }
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: switch(PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: return "energy_savings_leaf"
                        case PowerProfile.Balanced: return "airwave"
                        case PowerProfile.Performance: return "local_fire_department"
                    }
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }
    }
}

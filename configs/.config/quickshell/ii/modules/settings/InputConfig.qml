import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

ContentPage {
    id: root
    forceWidth: true

    property var detectedTouchpads: []
    property var detectedMice: []

    // Hyprland input config options - Mouse
    HyprlandConfigOption {
        id: optLeftHanded
        key: "input:left_handed"
    }

    HyprlandConfigOption {
        id: optSensitivity
        key: "input:sensitivity"
    }

    HyprlandConfigOption {
        id: optAccelProfile
        key: "input:accel_profile"
    }

    HyprlandConfigOption {
        id: optMouseNaturalScroll
        key: "input:natural_scroll"
    }

    HyprlandConfigOption {
        id: optMouseScrollFactor
        key: "input:scroll_factor"
    }

    HyprlandConfigOption {
        id: optFollowMouse
        key: "input:follow_mouse"
    }

    HyprlandConfigOption {
        id: optMouseRefocus
        key: "input:mouse_refocus"
    }

    // Hyprland input config options - Touchpad
    HyprlandConfigOption {
        id: optTouchpadTapToClick
        key: "input:touchpad:tap_to_click"
    }

    HyprlandConfigOption {
        id: optTouchpadTapAndDrag
        key: "input:touchpad:tap_and_drag"
    }

    HyprlandConfigOption {
        id: optTouchpadDragLock
        key: "input:touchpad:drag_lock"
    }

    HyprlandConfigOption {
        id: optTouchpadNaturalScroll
        key: "input:touchpad:natural_scroll"
    }

    HyprlandConfigOption {
        id: optTouchpadDisableWhileTyping
        key: "input:touchpad:disable_while_typing"
    }

    HyprlandConfigOption {
        id: optTouchpadClickfinger
        key: "input:touchpad:clickfinger_behavior"
    }

    HyprlandConfigOption {
        id: optTouchpadMiddleButton
        key: "input:touchpad:middle_button_emulation"
    }

    HyprlandConfigOption {
        id: optTouchpadScrollFactor
        key: "input:touchpad:scroll_factor"
    }

    // Debounce timers for sliders
    Timer {
        id: sensDebounce
        interval: 150
        repeat: false
        property real targetVal: 0.0
        onTriggered: optSensitivity.setValue(targetVal)
    }

    Timer {
        id: tpScrollDebounce
        interval: 150
        repeat: false
        property real targetVal: 0.7
        onTriggered: optTouchpadScrollFactor.setValue(targetVal)
    }

    Timer {
        id: mouseScrollDebounce
        interval: 150
        repeat: false
        property real targetVal: 1.0
        onTriggered: optMouseScrollFactor.setValue(targetVal)
    }

    // Fetch detected devices from Hyprland
    Process {
        id: devicesProc
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const touchpads = [];
                    const mice = [];
                    for (const m of (data.mice || [])) {
                        const name = m.name || "";
                        if (!name || name.includes("ydotoold") || name.includes("virtual"))
                            continue;
                        if (name.includes("touchpad")) {
                            touchpads.push(name);
                        } else {
                            mice.push(name);
                        }
                    }
                    root.detectedTouchpads = touchpads;
                    root.detectedMice = mice;
                } catch (e) {
                    console.log("[InputConfig] Failed to parse devices: " + e);
                }
            }
        }
    }

    Connections {
        target: HyprlandConfig
        function onReloaded() {
            devicesProc.running = true;
        }
    }

    // Detected hardware info notice
    NoticeBox {
        Layout.fillWidth: true
        materialIcon: "devices"
        text: {
            let parts = [];
            if (root.detectedTouchpads.length > 0) {
                parts.push(Translation.tr("Touchpad") + ": " + root.detectedTouchpads.join(", "));
            } else {
                parts.push(Translation.tr("Touchpad: No hardware touchpad detected"));
            }
            if (root.detectedMice.length > 0) {
                parts.push(Translation.tr("Mouse") + ": " + root.detectedMice.join(", "));
            } else {
                parts.push(Translation.tr("Mouse: No external mouse detected"));
            }
            return parts.join("\n");
        }
    }

    // Touchpad Section
    ContentSection {
        icon: "touch_app"
        title: Translation.tr("Touchpad")

        ConfigSwitch {
            buttonIcon: "touch_app"
            text: Translation.tr("Tap to click")
            checked: optTouchpadTapToClick.value ?? true
            onClicked: {
                optTouchpadTapToClick.setValue(checked);
            }
            StyledToolTip {
                text: Translation.tr("Tap touchpad to click instead of pressing down physically")
            }
        }

        ConfigSwitch {
            buttonIcon: "drag_pan"
            text: Translation.tr("Tap and drag")
            checked: optTouchpadTapAndDrag.value ?? true
            onClicked: {
                optTouchpadTapAndDrag.setValue(checked);
            }
            StyledToolTip {
                text: Translation.tr("Tap twice and quickly drag to select text or move windows")
            }
        }

        ConfigSwitch {
            buttonIcon: "lock_clock"
            text: Translation.tr("Drag lock")
            checked: Boolean(optTouchpadDragLock.value)
            onClicked: {
                optTouchpadDragLock.setValue(checked ? 1 : 0);
            }
            StyledToolTip {
                text: Translation.tr("Release finger while dragging and continue without losing selection")
            }
        }

        ConfigSwitch {
            buttonIcon: "swap_vert"
            text: Translation.tr("Natural scrolling (Reverse two-finger scroll)")
            checked: optTouchpadNaturalScroll.value ?? true
            onClicked: {
                optTouchpadNaturalScroll.setValue(checked);
            }
            StyledToolTip {
                text: Translation.tr("Two-finger scroll moves content in the same direction as your fingers")
            }
        }

        ConfigSwitch {
            buttonIcon: "keyboard"
            text: Translation.tr("Disable while typing")
            checked: optTouchpadDisableWhileTyping.value ?? true
            onClicked: {
                optTouchpadDisableWhileTyping.setValue(checked);
            }
            StyledToolTip {
                text: Translation.tr("Temporarily disables touchpad while keys are pressed to avoid accidental movement")
            }
        }

        ConfigSwitch {
            buttonIcon: "pan_tool"
            text: Translation.tr("Clickfinger behavior")
            checked: optTouchpadClickfinger.value ?? true
            onClicked: {
                optTouchpadClickfinger.setValue(checked);
            }
            StyledToolTip {
                text: Translation.tr("1 finger: Left click, 2 fingers: Right click, 3 fingers: Middle click")
            }
        }

        ConfigSwitch {
            buttonIcon: "call_to_action"
            text: Translation.tr("Middle click emulation")
            checked: optTouchpadMiddleButton.value ?? true
            onClicked: {
                optTouchpadMiddleButton.setValue(checked);
            }
            StyledToolTip {
                text: Translation.tr("Press left and right buttons simultaneously to middle click")
            }
        }

        // Touchpad Scroll Speed Slider
        RowLayout {
            spacing: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8

            OptionalMaterialSymbol {
                icon: "unfold_more"
                iconSize: Appearance.font.pixelSize.larger
            }
            StyledText {
                Layout.preferredWidth: 150
                text: Translation.tr("Touchpad scroll speed")
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledSlider {
                id: tpScrollSlider
                Layout.fillWidth: true
                configuration: StyledSlider.Configuration.XS
                usePercentTooltip: false
                tooltipContent: `${Math.round(value * 100)}%`
                from: 0.2
                to: 2.5
                stepSize: 0.05
                value: optTouchpadScrollFactor.value ?? 0.7
                onMoved: {
                    tpScrollDebounce.targetVal = Math.round(value * 100) / 100;
                    tpScrollDebounce.restart();
                }
            }
            StyledText {
                Layout.preferredWidth: 45
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(tpScrollSlider.value * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    // Mouse Section
    ContentSection {
        icon: "mouse"
        title: Translation.tr("Mouse")

        ContentSubsection {
            title: Translation.tr("Primary button")
            tooltip: Translation.tr("Sets the primary click button. Choose Right for left-handed mouse layout.")
            Layout.fillWidth: true

            ConfigSelectionArray {
                currentValue: optLeftHanded.value ? 1 : 0
                onSelected: newValue => {
                    optLeftHanded.setValue(newValue === 1);
                }
                options: [
                    {
                        displayName: Translation.tr("Left"),
                        icon: "mouse",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Right (Left-handed)"),
                        icon: "front_hand",
                        value: 1
                    }
                ]
            }
        }

        // Pointer Speed Slider
        RowLayout {
            spacing: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8

            OptionalMaterialSymbol {
                icon: "speed"
                iconSize: Appearance.font.pixelSize.larger
            }
            StyledText {
                Layout.preferredWidth: 150
                text: Translation.tr("Pointer speed")
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledSlider {
                id: sensSlider
                Layout.fillWidth: true
                configuration: StyledSlider.Configuration.XS
                usePercentTooltip: false
                tooltipContent: `${(value > 0 ? "+" : "") + Math.round(value * 100)}%`
                from: -1.0
                to: 1.0
                stepSize: 0.05
                value: optSensitivity.value ?? 0.0
                onMoved: {
                    sensDebounce.targetVal = Math.round(value * 100) / 100;
                    sensDebounce.restart();
                }
            }
            StyledText {
                Layout.preferredWidth: 45
                horizontalAlignment: Text.AlignRight
                text: `${(sensSlider.value > 0 ? "+" : "") + Math.round(sensSlider.value * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        ContentSubsection {
            title: Translation.tr("Acceleration profile")
            tooltip: Translation.tr("Adaptive accelerates with quick hand movements. Flat provides strict 1:1 speed, ideal for gaming.")
            Layout.fillWidth: true

            ConfigSelectionArray {
                currentValue: {
                    const v = optAccelProfile.value;
                    if (v === "flat") return "flat";
                    if (v === "adaptive") return "adaptive";
                    return "default";
                }
                onSelected: newValue => {
                    if (newValue === "default") {
                        optAccelProfile.reset();
                    } else {
                        optAccelProfile.setValue(newValue);
                    }
                }
                options: [
                    {
                        displayName: Translation.tr("Adaptive"),
                        icon: "trending_up",
                        value: "adaptive"
                    },
                    {
                        displayName: Translation.tr("Flat (Linear / Gaming)"),
                        icon: "straighten",
                        value: "flat"
                    },
                    {
                        displayName: Translation.tr("Default"),
                        icon: "restart_alt",
                        value: "default"
                    }
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "swap_vert"
            text: Translation.tr("Natural scrolling (Reverse mouse wheel)")
            checked: optMouseNaturalScroll.value ?? false
            onClicked: {
                optMouseNaturalScroll.setValue(checked);
            }
            StyledToolTip {
                text: Translation.tr("Reverses mouse wheel scrolling direction")
            }
        }

        // Mouse Wheel Scroll Factor Slider
        RowLayout {
            spacing: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8

            OptionalMaterialSymbol {
                icon: "unfold_more"
                iconSize: Appearance.font.pixelSize.larger
            }
            StyledText {
                Layout.preferredWidth: 150
                text: Translation.tr("Mouse wheel speed")
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledSlider {
                id: mouseScrollSlider
                Layout.fillWidth: true
                configuration: StyledSlider.Configuration.XS
                usePercentTooltip: false
                tooltipContent: `${Math.round(value * 100)}%`
                from: 0.2
                to: 3.0
                stepSize: 0.1
                value: optMouseScrollFactor.value ?? 1.0
                onMoved: {
                    mouseScrollDebounce.targetVal = Math.round(value * 100) / 100;
                    mouseScrollDebounce.restart();
                }
            }
            StyledText {
                Layout.preferredWidth: 45
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(mouseScrollSlider.value * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    // Cursor & Window Focus Behavior Section
    ContentSection {
        icon: "ads_click"
        title: Translation.tr("Cursor & Window Focus")

        ContentSubsection {
            title: Translation.tr("Window focus behavior")
            tooltip: Translation.tr("Determines whether window focus changes by moving the mouse or only when clicking.")
            Layout.fillWidth: true

            ConfigSelectionArray {
                currentValue: optFollowMouse.value ?? 1
                onSelected: newValue => {
                    optFollowMouse.setValue(newValue);
                }
                options: [
                    {
                        displayName: Translation.tr("Click to focus"),
                        icon: "ads_click",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Focus follows mouse"),
                        icon: "mouse",
                        value: 1
                    },
                    {
                        displayName: Translation.tr("Loose focus"),
                        icon: "filter_center_focus",
                        value: 2
                    },
                    {
                        displayName: Translation.tr("Strict focus"),
                        icon: "lock",
                        value: 3
                    }
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "recenter"
            text: Translation.tr("Refocus under cursor")
            checked: optMouseRefocus.value ?? true
            onClicked: {
                optMouseRefocus.setValue(checked);
            }
            StyledToolTip {
                text: Translation.tr("Focus the window currently under the cursor when the active window closes or is moved")
            }
        }
    }

    // Shell UI Scrolling Section
    ContentSection {
        icon: "swipe"
        title: Translation.tr("Shell UI Scrolling")

        ConfigSwitch {
            buttonIcon: "speed"
            text: Translation.tr("Faster touchpad scrolling in shell menus")
            checked: Config.options.interactions.scrolling.fasterTouchpadScroll
            onClicked: {
                Config.options.interactions.scrolling.fasterTouchpadScroll = checked;
            }
            StyledToolTip {
                text: Translation.tr("Accelerates scrolling in Quickshell menus and sidebars with touchpad")
            }
        }

        ConfigRow {
            uniform: true

            ConfigSpinBox {
                icon: "touch_app"
                text: Translation.tr("Touchpad UI scroll step")
                value: Config.options.interactions.scrolling.touchpadScrollFactor
                from: 50
                to: 1000
                stepSize: 50
                onValueChanged: {
                    Config.options.interactions.scrolling.touchpadScrollFactor = value;
                }
            }

            ConfigSpinBox {
                icon: "mouse"
                text: Translation.tr("Mouse UI scroll step")
                value: Config.options.interactions.scrolling.mouseScrollFactor
                from: 20
                to: 500
                stepSize: 10
                onValueChanged: {
                    Config.options.interactions.scrolling.mouseScrollFactor = value;
                }
            }
        }
    }
}

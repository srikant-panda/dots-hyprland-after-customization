import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ContentPage {
    id: root
    forceWidth: true

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "";
        let h = Math.floor(seconds / 3600);
        let m = Math.floor((seconds % 3600) / 60);
        if (h > 0) return `${h}h ${m}m`;
        return `${m}m`;
    }

    function getDeviceIcon(dev) {
        if (!dev) return "battery_android_full";
        let typeStr = String(dev.deviceType || "").toLowerCase();
        let modelStr = String(dev.model || "").toLowerCase();
        if (typeStr.indexOf("head") !== -1 || modelStr.indexOf("buds") !== -1 || modelStr.indexOf("head") !== -1 || modelStr.indexOf("ear") !== -1) {
            return "headphones";
        }
        if (typeStr.indexOf("mouse") !== -1 || modelStr.indexOf("mouse") !== -1) return "mouse";
        if (typeStr.indexOf("keyboard") !== -1 || modelStr.indexOf("keyboard") !== -1) return "keyboard";
        if (typeStr.indexOf("phone") !== -1) return "smartphone";
        if (typeStr.indexOf("tablet") !== -1) return "tablet";
        if (typeStr.indexOf("gamepad") !== -1 || typeStr.indexOf("joystick") !== -1) return "sports_esports";
        return "battery_android_full";
    }

    function updateIdleDaemon() {
        Quickshell.execDetached([
            "python3",
            CF.FileUtils.trimFileProtocol(`${Directories.config}/hypr/custom/scripts/update_hypridle.py`),
            "--lock", String(Config.options.power.lockTimeout),
            "--sleep", String(Config.options.power.sleepTimeout)
        ]);
    }

    // -------------------------------------------------------------
    // Section 1: Power Profiles
    // -------------------------------------------------------------
    ContentSection {
        icon: "speed"
        title: Translation.tr("Power Profile")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Active Performance Mode")
                tooltip: {
                    switch (PowerProfiles.profile) {
                        case PowerProfile.PowerSaver:
                            return Translation.tr("Power Saver reduces system performance and background activity to maximize battery runtime.");
                        case PowerProfile.Performance:
                            return Translation.tr("Performance mode maximizes CPU and system performance at the expense of higher energy usage.");
                        default:
                            return Translation.tr("Balanced provides standard performance with balanced power efficiency.");
                    }
                }
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: PowerProfiles.profile
                    onSelected: newValue => {
                        PowerProfiles.profile = newValue;
                    }
                    options: {
                        let opts = [
                            {
                                displayName: Translation.tr("Power Saver"),
                                icon: "energy_savings_leaf",
                                value: PowerProfile.PowerSaver
                            },
                            {
                                displayName: Translation.tr("Balanced"),
                                icon: "airwave",
                                value: PowerProfile.Balanced
                            }
                        ];
                        if (PowerProfiles.hasPerformanceProfile) {
                            opts.push({
                                displayName: Translation.tr("Performance"),
                                icon: "local_fire_department",
                                value: PowerProfile.Performance
                            });
                        }
                        return opts;
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------
    // Section 2: Laptop Lid Behavior (Single Display)
    // -------------------------------------------------------------
    ContentSection {
        icon: "laptop_chromebook"
        title: Translation.tr("Laptop Lid Behavior (Single Display)")

        NoticeBox {
            Layout.fillWidth: true
            text: Translation.tr("Controls what happens when the laptop lid is closed while using only the integrated display (no external monitors connected). Multi-monitor clamshell mode will continue to use external displays.")
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("On AC Power (Plugged In / Normal)")
                tooltip: Translation.tr("Action to take when lid is closed while connected to charger")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.power.lidActionAc || "nothing"
                    onSelected: newValue => {
                        Config.options.power.lidActionAc = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Sleep"),
                            icon: "bedtime",
                            value: "suspend"
                        },
                        {
                            displayName: Translation.tr("Lock only"),
                            icon: "lock",
                            value: "lock"
                        },
                        {
                            displayName: Translation.tr("Do nothing"),
                            icon: "visibility",
                            value: "nothing"
                        }
                    ]
                }
            }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("On Battery (Low Power / Unplugged)")
                tooltip: Translation.tr("Action to take when lid is closed while running on battery")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.power.lidActionBattery || "suspend"
                    onSelected: newValue => {
                        Config.options.power.lidActionBattery = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Sleep"),
                            icon: "bedtime",
                            value: "suspend"
                        },
                        {
                            displayName: Translation.tr("Lock only"),
                            icon: "lock",
                            value: "lock"
                        },
                        {
                            displayName: Translation.tr("Do nothing"),
                            icon: "visibility",
                            value: "nothing"
                        }
                    ]
                }
            }
        }
    }

    // -------------------------------------------------------------
    // Section 3: Screen Lock & System Sleep Intervals
    // -------------------------------------------------------------
    ContentSection {
        icon: "timer"
        title: Translation.tr("Display & Sleep Timeouts")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Auto-lock screen")
                tooltip: Translation.tr("Lock session after period of inactivity")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.power.lockTimeout ?? 300
                    onSelected: newValue => {
                        Config.options.power.lockTimeout = newValue;
                        root.updateIdleDaemon();
                    }
                    options: [
                        { displayName: Translation.tr("1 min"), icon: "schedule", value: 60 },
                        { displayName: Translation.tr("2 min"), icon: "schedule", value: 120 },
                        { displayName: Translation.tr("5 min"), icon: "schedule", value: 300 },
                        { displayName: Translation.tr("10 min"), icon: "schedule", value: 600 },
                        { displayName: Translation.tr("15 min"), icon: "schedule", value: 900 },
                        { displayName: Translation.tr("30 min"), icon: "schedule", value: 1800 },
                        { displayName: Translation.tr("Never"), icon: "timer_off", value: 0 }
                    ]
                }
            }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("System sleep interval")
                tooltip: Translation.tr("Suspend computer to RAM after period of inactivity")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.power.sleepTimeout ?? 900
                    onSelected: newValue => {
                        Config.options.power.sleepTimeout = newValue;
                        root.updateIdleDaemon();
                    }
                    options: [
                        { displayName: Translation.tr("5 min"), icon: "bedtime", value: 300 },
                        { displayName: Translation.tr("10 min"), icon: "bedtime", value: 600 },
                        { displayName: Translation.tr("15 min"), icon: "bedtime", value: 900 },
                        { displayName: Translation.tr("30 min"), icon: "bedtime", value: 1800 },
                        { displayName: Translation.tr("60 min"), icon: "bedtime", value: 3600 },
                        { displayName: Translation.tr("Never"), icon: "timer_off", value: 0 }
                    ]
                }
            }
        }
    }

    // -------------------------------------------------------------
    // Section 4: Battery & Connected Devices
    // -------------------------------------------------------------
    ContentSection {
        icon: "devices_other"
        title: Translation.tr("Battery & Connected Devices")

        // Main Laptop Battery Featured Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: mainBatCol.implicitHeight + 24
            radius: Appearance.rounding.windowRounding
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: mainBatCol
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    MaterialSymbol {
                        iconSize: 32
                        text: Battery.isCharging ? "battery_charging_full" : (Battery.isPluggedIn ? "battery_android_full" : "battery_android_full")
                        color: (Battery.percentage <= Config.options.battery.low / 100 && !Battery.isCharging)
                            ? Appearance.m3colors.m3error
                            : Appearance.colors.colPrimary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: Translation.tr("Laptop Battery (Primary)")
                            font {
                                family: Appearance.font.family.title
                                pixelSize: Appearance.font.pixelSize.title
                                weight: Font.Bold
                            }
                        }

                        StyledText {
                            text: {
                                if (Battery.chargeState == 4) return Translation.tr("Fully Charged • AC Connected");
                                if (Battery.isCharging) {
                                    let rate = Battery.energyRate > 0 ? ` (${Battery.energyRate.toFixed(1)}W)` : "";
                                    let time = root.formatTime(Battery.timeToFull);
                                    let timeStr = time.length > 0 ? ` • ${time} to full` : "";
                                    return Translation.tr("Charging%1%2").arg(rate).arg(timeStr);
                                }
                                let rate = Battery.energyRate > 0 ? ` (${Battery.energyRate.toFixed(1)}W)` : "";
                                let time = root.formatTime(Battery.timeToEmpty);
                                let timeStr = time.length > 0 ? ` • ${time} remaining` : "";
                                return Translation.tr("Discharging%1%2").arg(rate).arg(timeStr);
                            }
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }

                    StyledText {
                        text: `${Math.round(Battery.percentage * 100)}%`
                        font {
                            family: Appearance.font.family.title
                            pixelSize: 28
                            weight: Font.Bold
                        }
                        color: (Battery.percentage <= Config.options.battery.low / 100 && !Battery.isCharging)
                            ? Appearance.m3colors.m3error
                            : Appearance.colors.colOnLayer1
                    }
                }

                // Battery percentage bar
                StyledProgressBar {
                    Layout.fillWidth: true
                    value: Battery.percentage
                    highlightColor: (Battery.percentage <= Config.options.battery.low / 100 && !Battery.isCharging)
                        ? Appearance.m3colors.m3error
                        : Appearance.colors.colPrimary
                }

                // Extra details row (Health, Energy Rate)
                RowLayout {
                    Layout.fillWidth: true
                    visible: Battery.health > 0

                    StyledText {
                        text: Translation.tr("Battery Health: %1%").arg(Battery.health.toFixed(1))
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        visible: Battery.energyRate > 0
                        text: Translation.tr("Draw Rate: %1W").arg(Battery.energyRate.toFixed(2))
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }

        // Connected Peripheral Devices Subheading
        ContentSubsectionLabel {
            text: Translation.tr("Connected Peripherals & Accessories")
            Layout.topMargin: 8
        }

        // Peripherals list
        Repeater {
            model: {
                let list = [];
                let devs = UPower.devices.values;
                for (let i = 0; i < devs.length; ++i) {
                    let dev = devs[i];
                    // Skip laptop main battery and AC adapters
                    if (dev.isLaptopBattery) continue;
                    let nativePath = dev.nativePath || "";
                    if (nativePath.indexOf("ADP") !== -1 || nativePath.indexOf("line_power") !== -1) continue;
                    if (dev.percentage <= 0) continue;
                    list.push(dev);
                }
                return list;
            }

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                    }
                    spacing: 12

                    MaterialSymbol {
                        iconSize: 24
                        text: root.getDeviceIcon(modelData)
                        color: Appearance.colors.colPrimary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: modelData.model && modelData.model.length > 0 ? modelData.model : Translation.tr("Connected Device")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                        }

                        StyledText {
                            text: {
                                let pct = Math.round(modelData.percentage * 100);
                                return Translation.tr("Battery: %1% • Connected").arg(pct);
                            }
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }

                    // Device level progress bar
                    Rectangle {
                        implicitWidth: 100
                        implicitHeight: 8
                        radius: 4
                        color: Appearance.colors.colLayer2

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * Math.min(1.0, Math.max(0.0, modelData.percentage))
                            radius: 4
                            color: modelData.percentage <= 0.2 ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                        }
                    }

                    StyledText {
                        text: `${Math.round(modelData.percentage * 100)}%`
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Bold
                    }
                }
            }
        }

        // Fallback message if no extra devices connected
        StyledText {
            visible: {
                let devs = UPower.devices.values;
                let count = 0;
                for (let i = 0; i < devs.length; ++i) {
                    let dev = devs[i];
                    if (!dev.isLaptopBattery && (dev.nativePath || "").indexOf("ADP") === -1 && dev.percentage > 0) {
                        count++;
                    }
                }
                return count === 0;
            }
            text: Translation.tr("No other battery-powered devices (Bluetooth earbuds, mice, keyboards) currently detected.")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
            Layout.topMargin: 4
            Layout.bottomMargin: 8
        }
    }

    // -------------------------------------------------------------
    // Section 5: Battery Alerts & Protection
    // -------------------------------------------------------------
    ContentSection {
        icon: "battery_alert"
        title: Translation.tr("Battery Alerts & Protection")

        ConfigSpinBox {
            icon: "battery_alert"
            text: Translation.tr("Low battery warning threshold (%)")
            value: Config.options.battery.low
            from: 10
            to: 50
            stepSize: 5
            onValueChanged: {
                Config.options.battery.low = value;
            }
        }

        ConfigSpinBox {
            icon: "battery_very_low"
            text: Translation.tr("Critical battery warning threshold (%)")
            value: Config.options.battery.critical
            from: 2
            to: 15
            stepSize: 1
            onValueChanged: {
                Config.options.battery.critical = value;
            }
        }

        ConfigSwitch {
            buttonIcon: "bedtime"
            text: Translation.tr("Automatic suspend on critically low battery")
            checked: Config.options.battery.automaticSuspend
            onCheckedChanged: {
                Config.options.battery.automaticSuspend = checked;
            }
        }

        ConfigSpinBox {
            icon: "power_settings_new"
            text: Translation.tr("Automatic suspend threshold (%)")
            value: Config.options.battery.suspend
            from: 1
            to: 10
            stepSize: 1
            enabled: Config.options.battery.automaticSuspend
            onValueChanged: {
                Config.options.battery.suspend = value;
            }
        }

        ConfigSwitch {
            buttonIcon: "volume_up"
            text: Translation.tr("Play sound on power connect / disconnect / low battery")
            checked: Config.options.sounds.battery
            onCheckedChanged: {
                Config.options.sounds.battery = checked;
            }
        }
    }
}

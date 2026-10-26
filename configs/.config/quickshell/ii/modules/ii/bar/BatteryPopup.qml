import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    
    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        // Header
        StyledPopupHeaderRow {
            icon: "battery_android_full"
            label: Translation.tr("Battery")
        }

        StyledPopupValueRow {
            visible: {
                let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                let power = Battery.energyRate;
                return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
            }
            icon: "schedule"
            label: Battery.isCharging ? Translation.tr("Time to full:") : Translation.tr("Time to empty:")
            value: {
                function formatTime(seconds) {
                    var h = Math.floor(seconds / 3600);
                    var m = Math.floor((seconds % 3600) / 60);
                    if (h > 0)
                        return `${h}h, ${m}m`;
                    else
                        return `${m}m`;
                }
                if (Battery.isCharging)
                    return formatTime(Battery.timeToFull);
                else
                    return formatTime(Battery.timeToEmpty);
            }
        }

        StyledPopupValueRow {
            visible:  !(Battery.chargeState != 4 && Battery.energyRate == 0)
            icon: "bolt"
            label: {
                if (Battery.chargeState == 4) {
                    return Translation.tr("Fully charged");
                } else if (Battery.chargeState == 1) {
                    return Translation.tr("Charging:");
                } else {
                    return Translation.tr("Discharging:");
                }
            }
            value: {
                if (Battery.chargeState == 4) {
                    return "";
                } else {
                    return `${Battery.energyRate.toFixed(2)}W`;
                }
            }
        }

        RippleButton {
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 28
            buttonRadius: Appearance.rounding.small
            onClicked: {
                Quickshell.execDetached([
                    "bash", "-c",
                    "qs ipc -p ~/.config/quickshell/ii/settings.qml call settings openPage power 2>/dev/null || (export QS_SETTINGS_PAGE=power; qs -p ~/.config/quickshell/ii/settings.qml &)"
                ]);
            }
            contentItem: RowLayout {
                anchors.centerIn: parent
                spacing: 6
                MaterialSymbol {
                    text: "settings"
                    iconSize: 15
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    text: Translation.tr("Power Settings")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
    }
}

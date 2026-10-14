pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RippleButton {
    id: root

    property bool barHovered: false
    property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

    Behavior on colText {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false

    implicitWidth: 30
    implicitHeight: 28

    buttonRadius: Appearance.rounding.full
    colBackground: (barHovered || hovered) ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive

    toggled: popupLoader.active

    function togglePopup() {
        if (popupLoader.active) {
            popupLoader.item?.close();
            popupLoader.active = false;
        } else {
            popupLoader.active = true;
        }
    }

    onClicked: root.togglePopup()

    Connections {
        target: KdeConnectService
        function onTogglePopupRequested() {
            root.togglePopup();
        }
    }

    contentItem: Item {
        anchors.fill: parent

        MaterialSymbol {
            anchors.centerIn: parent
            text: KdeConnectService.connected ? "smartphone" : "phonelink_off"
            iconSize: Appearance.font.pixelSize.larger
            color: root.colText
        }

        // Notification badge
        Rectangle {
            visible: KdeConnectService.connected && KdeConnectService.notificationCount > 0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 2
            anchors.rightMargin: 1
            width: Math.max(badgeText.implicitWidth + 4, 12)
            height: 12
            radius: 6
            color: Appearance.m3colors.m3primary

            StyledText {
                id: badgeText
                anchors.centerIn: parent
                text: KdeConnectService.notificationCount > 9 ? "9+" : KdeConnectService.notificationCount.toString()
                font.pixelSize: 8
                font.bold: true
                color: Appearance.m3colors.m3onPrimary
            }
        }
    }

    property bool showTooltipTimedOut: false
    onHoveredChanged: {
        if (!hovered) showTooltipTimedOut = false;
    }
    Timer {
        running: root.hovered
        interval: 350
        onTriggered: root.showTooltipTimedOut = true
    }

    PopupToolTip {
        extraVisibleCondition: root.showTooltipTimedOut && !root.toggled
        text: {
            if (!KdeConnectService.connected) {
                return Translation.tr("KDE Connect (Disconnected)");
            }
            let dev = KdeConnectService.deviceName || Translation.tr("Device");
            let bat = KdeConnectService.batteryCharge >= 0 ? ` (${KdeConnectService.batteryCharge}%)` : "";
            let notifs = KdeConnectService.notificationCount > 0 ? ` • ${KdeConnectService.notificationCount} notifications` : "";
            return `KDE Connect: ${dev}${bat}${notifs}`;
        }
        anchorEdges: (!Config.options.bar.bottom && !Config.options.bar.vertical) ? Edges.Bottom : Edges.Top
    }

    Loader {
        id: popupLoader
        active: false
        sourceComponent: KdeConnectPopup {
            anchorItem: root
            onPopupClosed: popupLoader.active = false
        }
    }
}

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
        target: Cliphist
        function onTogglePopupRequested() {
            root.togglePopup();
        }
    }

    contentItem: Item {
        anchors.fill: parent

        MaterialSymbol {
            anchors.centerIn: parent
            text: Cliphist.privateMode ? "shield" : "content_paste"
            iconSize: Appearance.font.pixelSize.larger
            color: Cliphist.privateMode ? Appearance.m3colors.m3tertiary : root.colText
        }

        // Private mode indicator dot
        Rectangle {
            visible: Cliphist.privateMode
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 2
            anchors.rightMargin: 1
            width: 8
            height: 8
            radius: 4
            color: Appearance.m3colors.m3tertiary
            border.width: 1
            border.color: Appearance.colors.colLayer0
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
            let label = Translation.tr("Clipboard");
            if (Cliphist.privateMode) {
                label += " [Private Mode]";
            }
            if (Cliphist.entries.length > 0) {
                label += ` (${Cliphist.entries.length})`;
            }
            return label;
        }
        anchorEdges: (!Config.options.bar.bottom && !Config.options.bar.vertical) ? Edges.Bottom : Edges.Top
    }

    Loader {
        id: popupLoader
        active: false
        sourceComponent: ClipboardPopup {
            anchorItem: root
            onPopupClosed: popupLoader.active = false
        }
    }
}

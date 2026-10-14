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

    toggled: GlobalStates.overviewOpen && (LauncherSearch.query.startsWith(Config.options.search.prefix.clipboard))

    onPressed: {
        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "search", "clipboardToggle"]);
    }

    contentItem: Item {
        anchors.fill: parent
        MaterialSymbol {
            anchors.centerIn: parent
            text: "content_paste"
            iconSize: Appearance.font.pixelSize.larger
            color: root.colText
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
        text: Translation.tr("Clipboard") + (Cliphist.entries.length > 0 ? ` (${Cliphist.entries.length})` : "")
        anchorEdges: (!Config.options.bar.bottom && !Config.options.bar.vertical) ? Edges.Bottom : Edges.Top
    }
}

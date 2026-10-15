import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property bool barHovered: false
    property color colText: Appearance.colors.colOnLayer0

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false

    implicitWidth: pillBackground.implicitWidth
    implicitHeight: 28

    Rectangle {
        id: pillBackground
        anchors.fill: parent
        implicitWidth: contentRow.implicitWidth + 16
        implicitHeight: 28
        radius: Appearance.rounding.full
        color: (root.barHovered || mouseArea.containsMouse) ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            // Download (↓)
            RowLayout {
                spacing: 3
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    text: "arrow_downward"
                    iconSize: 13
                    color: Appearance.colors.colPrimary
                    font.weight: Font.Bold
                }

                StyledText {
                    text: NetworkSpeed.downloadSpeedString
                    font.family: Appearance.font.monospace ?? "monospace"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            // Separator divider
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 1
                implicitHeight: 12
                color: Appearance.colors.colOutlineVariant
            }

            // Upload (↑)
            RowLayout {
                spacing: 3
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    text: "arrow_upward"
                    iconSize: 13
                    color: Appearance.colors.colSecondary
                    font.weight: Font.Bold
                }

                StyledText {
                    text: NetworkSpeed.uploadSpeedString
                    font.family: Appearance.font.monospace ?? "monospace"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onExited: root.showTooltipTimedOut = false
            onClicked: {
                Quickshell.execDetached(["kcmshell6", "kcm_networkmanagement"]);
            }
        }
    }

    property bool showTooltipTimedOut: false
    Timer {
        running: mouseArea.containsMouse
        interval: 350
        onTriggered: root.showTooltipTimedOut = true
    }

    PopupToolTip {
        extraVisibleCondition: root.showTooltipTimedOut
        text: `↓ Download: ${NetworkSpeed.downloadSpeedString} (Total: ${NetworkSpeed.totalRxString})\n↑ Upload: ${NetworkSpeed.uploadSpeedString} (Total: ${NetworkSpeed.totalTxString})`
        anchorEdges: (!Config.options.bar.bottom && !Config.options.bar.vertical) ? Edges.Bottom : Edges.Top
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    implicitWidth: gridLayout.implicitWidth
    implicitHeight: gridLayout.implicitHeight
    property bool vertical: false
    property bool invertSide: false
    property bool trayOverflowOpen: false
    property bool showSeparator: true
    property bool showOverflowMenu: true
    property var activeMenu: null

    property list<var> pinnedItems: TrayService.pinnedItems
    property list<var> unpinnedItems: TrayService.unpinnedItems

    onUnpinnedItemsChanged: {
        if (unpinnedItems.length === 0 && root.trayOverflowOpen) {
            root.trayOverflowOpen = false;
        }
    }

    RowLayout {
        id: gridLayout
        anchors.fill: parent
        spacing: 6

        // Pinned Tray Apps (shown directly on the bar)
        Repeater {
            model: ScriptModel {
                values: root.pinnedItems
            }

            delegate: SysTrayItem {
                required property SystemTrayItem modelData
                item: modelData
                Layout.fillHeight: !root.vertical
                Layout.fillWidth: root.vertical
            }
        }

        // Chevron Arrow Button (Windows style: downward arrow, flips to upward when clicked)
        RippleButton {
            id: trayOverflowButton
            visible: root.showOverflowMenu && (root.unpinnedItems.length > 0 || SystemTray.items.values.length > 0)
            toggled: root.trayOverflowOpen
            property bool containsMouse: hovered

            downAction: () => root.trayOverflowOpen = !root.trayOverflowOpen

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            implicitWidth: 24
            implicitHeight: 24
            buttonRadius: 12
            colBackground: hovered ? Appearance.colors.colLayer1Hover : "transparent"
            colBackgroundToggled: Appearance.colors.colSecondaryContainer
            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
            colRippleToggled: Appearance.colors.colSecondaryContainerActive

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 18
                text: "keyboard_arrow_down"
                horizontalAlignment: Text.AlignHCenter
                color: root.trayOverflowOpen ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                rotation: root.trayOverflowOpen ? 180 : 0
                Behavior on rotation {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutQuad
                    }
                }
            }

            PopupToolTip {
                extraVisibleCondition: trayOverflowButton.containsMouse && !root.trayOverflowOpen
                text: root.unpinnedItems.length > 0
                    ? `Show background apps (${root.unpinnedItems.length})`
                    : "Background apps"
                anchorEdges: (!Config.options.bar.bottom && !Config.options.bar.vertical) ? Edges.Bottom : Edges.Top
            }
        }

        // Separator dot
        StyledText {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colSubtext
            text: "•"
            visible: root.showSeparator && (root.pinnedItems.length > 0 || root.unpinnedItems.length > 0)
        }
    }

    Loader {
        id: overflowPopupLoader
        active: root.trayOverflowOpen
        sourceComponent: SysTrayOverflowPopup {
            anchorItem: trayOverflowButton
            onPopupClosed: root.trayOverflowOpen = false
        }
    }
}

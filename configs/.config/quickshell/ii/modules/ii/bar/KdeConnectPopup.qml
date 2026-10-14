pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

PopupWindow {
    id: root

    required property Item anchorItem
    property real popupPadding: 10

    color: "transparent"
    visible: true

    signal popupClosed

    function open() {
        KdeConnectService.refresh();
        root.visible = true;
    }

    function close() {
        root.visible = false;
        root.popupClosed();
    }

    anchor {
        adjustment: PopupAdjustment.Slide
        window: root.anchorItem?.QsWindow?.window
        item: root.anchorItem
        gravity: Config.options.bar.vertical
            ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
            : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
        edges: Config.options.bar.vertical
            ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
            : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.visible
        windows: [root, root.anchorItem?.QsWindow?.window]
        onCleared: root.close()
    }

    implicitWidth: 350
    implicitHeight: Math.min(mainColumn.implicitHeight + popupPadding * 2 + 16, 540)

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        StyledRectangularShadow {
            target: popupCard
        }

        Rectangle {
            id: popupCard
            anchors.fill: parent
            anchors.margins: 6
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainer
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            clip: true

            ColumnLayout {
                id: mainColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 12
                }
                spacing: 12

                // Header row: < KDE Connect  [Settings] [Close]
                RowLayout {
                    Layout.fillWidth: true
                    height: 28
                    spacing: 6

                    MaterialSymbol {
                        text: "phonelink"
                        iconSize: 20
                        color: Appearance.m3colors.m3primary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "KDE Connect"
                        font.bold: true
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSurface
                    }

                    // Settings Button -> direct to kdeconnect-app
                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: 14
                        colBackground: hovered ? Appearance.colors.colLayer1Hover : "transparent"

                        onPressed: {
                            KdeConnectService.openSettings();
                            root.close();
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "settings"
                            iconSize: 18
                            color: Appearance.m3colors.m3onSurface
                        }

                        PopupToolTip {
                            text: "KDE Connect Settings"
                        }
                    }

                    // Close Button
                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: 14
                        colBackground: hovered ? Appearance.colors.colLayer1Hover : "transparent"

                        onPressed: root.close()

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 18
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.m3colors.m3outlineVariant
                    opacity: 0.5
                }

                // Connected Device Card
                Loader {
                    Layout.fillWidth: true
                    active: KdeConnectService.connected && KdeConnectService.primaryDevice !== null
                    visible: active

                    sourceComponent: ColumnLayout {
                        spacing: 8
                        Layout.fillWidth: true

                        // Device Name & Status indicators
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                Layout.fillWidth: true
                                text: KdeConnectService.deviceName
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.m3colors.m3onSurface
                                elide: Text.ElideRight
                            }

                            // Cellular Signal
                            RowLayout {
                                visible: KdeConnectService.cellularSignal >= 0
                                spacing: 2

                                MaterialSymbol {
                                    text: "signal_cellular_alt"
                                    iconSize: 16
                                    color: Appearance.m3colors.m3onSurfaceVariant
                                }

                                StyledText {
                                    text: KdeConnectService.cellularType
                                    font.pixelSize: 10
                                    color: Appearance.m3colors.m3onSurfaceVariant
                                }
                            }

                            // Battery Info
                            RowLayout {
                                visible: KdeConnectService.batteryCharge >= 0
                                spacing: 2

                                MaterialSymbol {
                                    text: KdeConnectService.isCharging ? "battery_charging_full" : "battery_android_full"
                                    iconSize: 16
                                    color: KdeConnectService.batteryCharge <= 15 ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSurfaceVariant
                                }

                                StyledText {
                                    text: `${KdeConnectService.batteryCharge}%`
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: KdeConnectService.batteryCharge <= 15 ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSurface
                                }
                            }
                        }

                        // Quick Actions Menu Bar (Matching screenshot actions)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // Share File
                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 32
                                buttonRadius: 8
                                colBackground: hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

                                onPressed: {
                                    KdeConnectService.shareFile();
                                    root.close();
                                }

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol { text: "share"; iconSize: 15 }
                                    StyledText { text: "Share"; font.pixelSize: 11; font.bold: true }
                                }

                                PopupToolTip { text: "Send file to device" }
                            }

                            // Ring Phone
                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 32
                                buttonRadius: 8
                                colBackground: hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

                                onPressed: {
                                    KdeConnectService.ring();
                                }

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol { text: "ring_volume"; iconSize: 15 }
                                    StyledText { text: "Ring"; font.pixelSize: 11; font.bold: true }
                                }

                                PopupToolTip { text: "Ring my phone" }
                            }

                            // Browse Device (SFTP)
                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 32
                                buttonRadius: 8
                                colBackground: hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

                                onPressed: {
                                    KdeConnectService.browse();
                                    root.close();
                                }

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol { text: "folder_open"; iconSize: 15 }
                                    StyledText { text: "Browse"; font.pixelSize: 11; font.bold: true }
                                }

                                PopupToolTip { text: "Browse device files" }
                            }

                            // SMS
                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 32
                                buttonRadius: 8
                                colBackground: hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

                                onPressed: {
                                    KdeConnectService.openSms();
                                    root.close();
                                }

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol { text: "chat"; iconSize: 15 }
                                    StyledText { text: "SMS"; font.pixelSize: 11; font.bold: true }
                                }

                                PopupToolTip { text: "SMS Messages" }
                            }
                        }
                    }
                }

                // If not connected
                Loader {
                    Layout.fillWidth: true
                    active: !KdeConnectService.connected
                    visible: active

                    sourceComponent: ColumnLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignHCenter

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No paired device connected"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurfaceVariant
                        }

                        RippleButton {
                            Layout.alignment: Qt.AlignHCenter
                            implicitHeight: 32
                            buttonRadius: 8
                            colBackground: Appearance.m3colors.m3primary

                            onPressed: {
                                KdeConnectService.openSettings();
                                root.close();
                            }

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                text: "Pair Device in KDE Connect"
                                font.pixelSize: 11
                                font.bold: true
                                color: Appearance.m3colors.m3onPrimary
                            }
                        }
                    }
                }

                // Notifications Header
                RowLayout {
                    Layout.fillWidth: true
                    visible: KdeConnectService.connected
                    spacing: 4

                    StyledText {
                        text: "Notifications:"
                        font.bold: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }

                    StyledText {
                        visible: KdeConnectService.notificationCount > 0
                        text: `(${KdeConnectService.notificationCount})`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3primary
                        font.bold: true
                    }
                }

                // Notifications List (Scrollable)
                ListView {
                    id: notifList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 260)
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds
                    visible: KdeConnectService.connected && KdeConnectService.notificationCount > 0

                    model: KdeConnectService.notifications

                    delegate: Rectangle {
                        id: notifItem
                        required property var modelData
                        readonly property string otpCode: (notifItem.modelData?.otp) || NotificationUtils.extractOtp((notifItem.modelData?.title || "") + " " + (notifItem.modelData?.text || ""))
                        property bool copiedOtp: false

                        Timer {
                            id: resetOtpTimer
                            interval: 1500
                            repeat: false
                            onTriggered: notifItem.copiedOtp = false
                        }

                        function copyOtp() {
                            if (!notifItem.otpCode) return;
                            Quickshell.clipboardText = notifItem.otpCode;
                            Quickshell.execDetached(["wl-copy", notifItem.otpCode]);
                            notifItem.copiedOtp = true;
                            resetOtpTimer.restart();
                        }

                        width: notifList.width
                        implicitHeight: itemRow.implicitHeight + 12
                        radius: 8
                        color: itemMouseArea.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        RowLayout {
                            id: itemRow
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 6
                            }
                            spacing: 8

                            // App Icon
                            Item {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                Layout.alignment: Qt.AlignTop

                                Image {
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    fillMode: Image.PreserveAspectFit
                                    visible: notifItem.modelData.iconPath && notifItem.modelData.iconPath.length > 0
                                    source: notifItem.modelData.iconPath ? `file://${notifItem.modelData.iconPath}` : ""
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    visible: !notifItem.modelData.iconPath || notifItem.modelData.iconPath.length === 0
                                    text: "notifications"
                                    iconSize: 18
                                    color: Appearance.m3colors.m3primary
                                }
                            }

                            // Notification Texts
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    Layout.fillWidth: true
                                    text: {
                                        const app = notifItem.modelData.appName || "";
                                        const title = notifItem.modelData.title || "";
                                        if (app && title) return `${app}: ${title}`;
                                        return app || title || "Notification";
                                    }
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: Appearance.m3colors.m3onSurface
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: notifItem.modelData.text || ""
                                    font.pixelSize: 10
                                    color: Appearance.m3colors.m3onSurfaceVariant
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                // OTP Copy Button showing actual OTP
                                RippleButton {
                                    id: notifOtpBtn
                                    visible: notifItem.otpCode.length > 0
                                    Layout.topMargin: 2
                                    implicitHeight: 24
                                    implicitWidth: notifOtpRow.implicitWidth + 16
                                    buttonRadius: 12
                                    colBackground: notifItem.copiedOtp ? Appearance.m3colors.m3primaryContainer : Appearance.colors.colLayer2
                                    colBackgroundHover: notifItem.copiedOtp ? Appearance.m3colors.m3primaryContainer : Appearance.colors.colLayer2Hover

                                    onPressed: notifItem.copyOtp()

                                    contentItem: RowLayout {
                                        id: notifOtpRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        MaterialSymbol {
                                            text: notifItem.copiedOtp ? "check" : "content_copy"
                                            iconSize: 13
                                            color: notifItem.copiedOtp ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
                                        }

                                        StyledText {
                                            text: notifItem.copiedOtp ? "Copied!" : notifItem.otpCode
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: notifItem.copiedOtp ? Appearance.font.family.main : Appearance.font.family.mono
                                            color: notifItem.copiedOtp ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
                                        }
                                    }

                                    PopupToolTip {
                                        text: notifItem.copiedOtp ? "Copied to clipboard" : `Copy OTP (${notifItem.otpCode})`
                                    }
                                }
                            }

                            // Dismiss button (X)
                            RippleButton {
                                id: dismissBtn
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                Layout.alignment: Qt.AlignTop
                                buttonRadius: 11
                                colBackground: hovered ? Appearance.m3colors.m3error : "transparent"

                                onPressed: {
                                    KdeConnectService.dismissNotification(KdeConnectService.deviceId, notifItem.modelData.id);
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 14
                                    color: dismissBtn.hovered ? Appearance.m3colors.m3onError : Appearance.m3colors.m3onSurfaceVariant
                                }

                                PopupToolTip {
                                    text: "Dismiss"
                                }
                            }
                        }
                    }
                }

                // If connected but no notifications
                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    visible: KdeConnectService.connected && KdeConnectService.notificationCount === 0
                    text: "No notifications"
                    font.pixelSize: 11
                    color: Appearance.m3colors.m3onSurfaceVariant
                    opacity: 0.7
                }
            }
        }
    }
}

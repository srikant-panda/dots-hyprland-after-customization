pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool connected: false
    property var devices: []
    property var primaryDevice: (devices && devices.length > 0) ? devices[0] : null

    property int notificationCount: primaryDevice ? (primaryDevice.notifications?.length ?? 0) : 0
    property var notifications: primaryDevice ? (primaryDevice.notifications ?? []) : []
    property int batteryCharge: primaryDevice?.battery?.charge ?? -1
    property bool isCharging: primaryDevice?.battery?.isCharging ?? false
    property int cellularSignal: primaryDevice?.cellular?.signal ?? -1
    property string cellularType: primaryDevice?.cellular?.type ?? ""
    property string deviceName: primaryDevice?.name ?? ""
    property string deviceId: primaryDevice?.id ?? ""

    property var shares: []
    property int shareCount: shares ? shares.length : 0

    readonly property string helperScript: FileUtils.trimFileProtocol(Quickshell.shellPath("scripts/kdeconnect/kdeconnect.py"))

    signal newShareReceived()
    signal togglePopupRequested()
    signal toggleSharePopupRequested()

    function refresh() {
        if (!getStatusProc.running) {
            getStatusProc.running = true;
        }
    }

    function ring(devId) {
        const id = devId || root.deviceId;
        if (!id) return;
        Quickshell.execDetached([root.helperScript, "ring", id]);
    }

    function browse(devId) {
        const id = devId || root.deviceId;
        if (!id) return;
        Quickshell.execDetached([root.helperScript, "browse", id]);
    }

    function dismissNotification(devId, notifId) {
        const id = devId || root.deviceId;
        if (!id || !notifId) return;
        Quickshell.execDetached([root.helperScript, "dismiss", id, notifId]);
        if (root.primaryDevice && root.primaryDevice.notifications) {
            root.primaryDevice.notifications = root.primaryDevice.notifications.filter(n => n.id !== notifId);
            root.notifications = root.primaryDevice.notifications;
            root.notificationCount = root.notifications.length;
        }
    }

    function dismissAllNotifications(devId) {
        const id = devId || root.deviceId;
        if (!id) return;
        Quickshell.execDetached([root.helperScript, "dismiss_all", id]);
        if (root.primaryDevice) {
            root.primaryDevice.notifications = [];
            root.notifications = [];
            root.notificationCount = 0;
        }
    }

    function shareFile(devId, filePath) {
        const id = devId || root.deviceId;
        if (!id) return;
        if (filePath) {
            Quickshell.execDetached([root.helperScript, "share", id, filePath]);
        } else {
            Quickshell.execDetached([root.helperScript, "share", id]);
        }
    }

    function sendClipboard(devId) {
        const id = devId || root.deviceId;
        if (!id) return;
        Quickshell.execDetached([root.helperScript, "clipboard", id]);
    }

    function openSms() {
        Quickshell.execDetached([root.helperScript, "sms"]);
    }

    function openSettings() {
        Quickshell.execDetached([root.helperScript, "settings"]);
    }

    function clearShares() {
        Quickshell.execDetached([root.helperScript, "clear_shares"]);
        root.shares = [];
        root.shareCount = 0;
    }

    function deleteShare(index) {
        Quickshell.execDetached([root.helperScript, "delete_share", index.toString()]);
        const updated = [...root.shares];
        updated.splice(index, 1);
        root.shares = updated;
        root.shareCount = updated.length;
    }

    Timer {
        interval: 3500
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        root.refresh();
        shareListenerProc.running = true;
    }

    Process {
        id: getStatusProc
        command: [root.helperScript, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.available = data.available ?? false;
                    root.connected = data.connected ?? false;
                    root.devices = data.devices ?? [];
                    root.shares = data.shares ?? [];
                    root.shareCount = data.shareCount ?? 0;

                    if (root.devices.length > 0) {
                        const dev = root.devices[0];
                        root.primaryDevice = dev;
                        root.deviceName = dev.name || "";
                        root.deviceId = dev.id || "";
                        root.notifications = dev.notifications || [];
                        root.notificationCount = root.notifications.length;
                        root.batteryCharge = dev.battery?.charge ?? -1;
                        root.isCharging = dev.battery?.isCharging ?? false;
                        root.cellularSignal = dev.cellular?.signal ?? -1;
                        root.cellularType = dev.cellular?.type ?? "";
                    } else {
                        root.primaryDevice = null;
                        root.deviceName = "";
                        root.deviceId = "";
                        root.notifications = [];
                        root.notificationCount = 0;
                        root.batteryCharge = -1;
                        root.isCharging = false;
                        root.cellularSignal = -1;
                        root.cellularType = "";
                    }
                } catch (e) {
                    console.error("[KdeConnectService] Error parsing status:", e);
                }
            }
        }
    }

    Process {
        id: shareListenerProc
        command: [root.helperScript, "daemon"]
    }

    IpcHandler {
        target: "kdeconnect"
        function refresh(): void {
            root.refresh();
        }
        function onShareReceived(): void {
            root.refresh();
            root.newShareReceived();
        }
        function toggle(): void {
            root.togglePopupRequested();
        }
        function toggleShares(): void {
            root.toggleSharePopupRequested();
        }
    }
}

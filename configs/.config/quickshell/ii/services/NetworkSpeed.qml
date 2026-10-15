pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property string downloadSpeedString: "0.0 KB/s"
    property string uploadSpeedString: "0.0 KB/s"

    property real totalRxBytes: 0
    property real totalTxBytes: 0
    property string totalRxString: "0 MB"
    property string totalTxString: "0 MB"

    property real prevRxBytes: -1
    property real prevTxBytes: -1
    property double lastTimestamp: 0

    function formatSpeed(bytesPerSec) {
        if (!bytesPerSec || isNaN(bytesPerSec) || bytesPerSec <= 0) {
            return "0.0 KB/s";
        }
        const kb = bytesPerSec / 1024;
        if (kb < 1024) {
            return (kb < 100 ? kb.toFixed(1) : kb.toFixed(0)) + " KB/s";
        }
        const mb = kb / 1024;
        if (mb < 1024) {
            return (mb < 100 ? mb.toFixed(1) : mb.toFixed(0)) + " MB/s";
        }
        const gb = mb / 1024;
        return gb.toFixed(2) + " GB/s";
    }

    function formatTotal(bytes) {
        if (!bytes || isNaN(bytes) || bytes <= 0) return "0 MB";
        const mb = bytes / (1024 * 1024);
        if (mb < 1024) return mb.toFixed(1) + " MB";
        const gb = mb / 1024;
        return gb.toFixed(2) + " GB";
    }

    FileView {
        id: fileNetDev
        path: "/proc/net/dev"
    }

    Timer {
        id: pollTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fileNetDev.reload();
            const content = fileNetDev.text();
            if (!content) return;

            const now = Date.now();
            let currentRx = 0;
            let currentTx = 0;

            const lines = content.split('\n');
            for (let i = 2; i < lines.length; i++) {
                const line = lines[i].trim();
                if (!line) continue;
                const colon = line.indexOf(':');
                if (colon === -1) continue;
                const iface = line.substring(0, colon).trim();
                if (iface === 'lo') continue;

                const tokens = line.substring(colon + 1).trim().split(/\s+/);
                if (tokens.length >= 9) {
                    currentRx += Number(tokens[0]) || 0;
                    currentTx += Number(tokens[8]) || 0;
                }
            }

            root.totalRxBytes = currentRx;
            root.totalTxBytes = currentTx;
            root.totalRxString = root.formatTotal(currentRx);
            root.totalTxString = root.formatTotal(currentTx);

            if (root.prevRxBytes >= 0 && root.lastTimestamp > 0) {
                const dt = Math.max(0.1, (now - root.lastTimestamp) / 1000);
                const rxDiff = Math.max(0, currentRx - root.prevRxBytes);
                const txDiff = Math.max(0, currentTx - root.prevTxBytes);

                root.downloadSpeed = rxDiff / dt;
                root.uploadSpeed = txDiff / dt;
                root.downloadSpeedString = root.formatSpeed(root.downloadSpeed);
                root.uploadSpeedString = root.formatSpeed(root.uploadSpeed);
            } else {
                root.downloadSpeedString = "0.0 KB/s";
                root.uploadSpeedString = "0.0 KB/s";
            }

            root.prevRxBytes = currentRx;
            root.prevTxBytes = currentTx;
            root.lastTimestamp = now;
        }
    }
}

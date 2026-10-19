pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    // property string cliphistBinary: FileUtils.trimFileProtocol(`${Directories.home}/.cargo/bin/stash`)
    property string cliphistBinary: "cliphist"
    property real pasteDelay: 0.05
    property string pressPasteCommand: "ydotool key -d 1 29:1 47:1 47:0 29:0"
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property list<string> entries: []
    property bool privateMode: false
    signal togglePopupRequested()

    function setPrivateMode(enabled: bool) {
        root.privateMode = enabled;
        if (enabled) {
            Quickshell.execDetached(["touch", "/tmp/cliphist_private_mode"]);
        } else {
            Quickshell.execDetached(["rm", "-f", "/tmp/cliphist_private_mode"]);
        }
    }

    function togglePrivateMode() {
        root.setPrivateMode(!root.privateMode);
    }

    Process {
        id: checkPrivateModeProc
        command: ["bash", "-c", "[ -f /tmp/cliphist_private_mode ] && echo 1 || echo 0"]
        stdout: SplitParser {
            onRead: (line) => {
                root.privateMode = (line.trim() === "1");
            }
        }
    }

    Component.onCompleted: {
        checkPrivateModeProc.running = true;
        root.refresh();
    }
    readonly property var preparedEntries: entries.map(a => ({
        name: Fuzzy.prepare(`${a.replace(/^\s*\S+\s+/, "")}`),
        entry: a
    }))
    function fuzzyQuery(search: string): var {
        if (search.trim() === "") {
            return entries;
        }
        if (root.sloppySearch) {
            const results = entries.slice(0, 100).map(str => ({
                entry: str,
                score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function entryIsImage(entry) {
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry))
    }

    function entryIsMedia(entry) {
        if (!entry) return false;
        if (entryIsImage(entry)) return true;
        const raw = entry.replace(/^\d+\t/, "").trim();
        const cleanPath = raw.replace(/^file:\/\//, "");
        return /\.(png|jpe?g|gif|webp|svg|bmp|ico|mp4|mkv|webm|avi|mov|mp3|wav|ogg|flac|m4a|aac|opus)$/i.test(cleanPath);
    }

    function copyPath(entry) {
        if (!entry) return;
        if (entryIsImage(entry)) {
            const entryNumberMatch = entry.match(/^(\d+)\t/);
            const entryNumber = entryNumberMatch ? entryNumberMatch[1] : "0";
            const extMatch = entry.match(/\b(png|jpe?g|gif|webp|bmp)\b/i);
            const ext = extMatch ? extMatch[1].toLowerCase() : "png";
            const outPath = `${Directories.cliphistDecode}/clip_${entryNumber}.${ext}`;
            const decodeCmd = root.cliphistBinary.includes("cliphist")
                ? `(printf '%s' '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode > '${outPath}' || ${root.cliphistBinary} decode ${entryNumber} > '${outPath}')`
                : `${root.cliphistBinary} decode ${entryNumber} > '${outPath}'`;
            const cmd = `mkdir -p '${Directories.cliphistDecode}' && ([ -s '${outPath}' ] || (${decodeCmd}; [ -s '${outPath}' ] || rm -f '${outPath}')) && printf '%s' '${outPath}' | wl-copy`;
            Quickshell.execDetached(["bash", "-c", cmd]);
            Quickshell.clipboardText = outPath;
        } else {
            const raw = entry.replace(/^\d+\t/, "").trim();
            const cleanPath = raw.replace(/^file:\/\//, "");
            Quickshell.execDetached(["bash", "-c", `printf '%s' '${StringUtils.shellSingleQuoteEscape(cleanPath)}' | wl-copy`]);
            Quickshell.clipboardText = cleanPath;
        }
    }

    function refresh() {
        readProc.buffer = []
        readProc.running = true
    }

    function copy(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy`]);
        }
    }

    function paste(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && wl-paste`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy; ${root.pressPasteCommand}`]);
        }
    }

    function superpaste(count, isImage = false) {
        // Find entries
        const targetEntries = entries.filter(entry => {
            if (!isImage) return true;
            return entryIsImage(entry);
        }).slice(0, count)
        const pasteCommands = [...targetEntries].reverse().map(entry => `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`)
        // Act
        Quickshell.execDetached(["bash", "-c", pasteCommands.join(` && sleep ${root.pasteDelay} && `)]);
    }

    Process {
        id: deleteProc
        property string entry: ""
        command: ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(deleteProc.entry)}' | ${root.cliphistBinary} delete`]
        function deleteEntry(entry) {
            deleteProc.entry = entry;
            deleteProc.running = true;
            deleteProc.entry = "";
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function deleteEntry(entry) {
        root.entries = root.entries.filter(e => e !== entry);
        deleteProc.deleteEntry(entry);
    }

    Process {
        id: wipeProc
        command: [root.cliphistBinary, "wipe"]
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function wipe() {
        root.entries = [];
        wipeProc.running = true;
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            if (!root.privateMode) {
                delayedUpdateTimer.restart()
            }
        }
    }

    Timer {
        id: delayedUpdateTimer
        interval: Config.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: {
            root.refresh()
        }
    }

    Process {
        id: readProc
        property list<string> buffer: []

        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: (line) => {
                readProc.buffer.push(line)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer
            } else {
                console.error("[Cliphist] Failed to refresh with code", exitCode, "and status", exitStatus)
            }
        }
    }

    IpcHandler {
        target: "cliphistService"

        function update(): void {
            if (!root.privateMode) {
                root.refresh()
            }
        }

        function toggle(): void {
            root.togglePopupRequested()
        }

        function wipe(): void {
            root.wipe()
        }

        function togglePrivate(): void {
            root.togglePrivateMode()
        }

        function copyPath(entry: string): void {
            root.copyPath(entry);
        }
    }
}

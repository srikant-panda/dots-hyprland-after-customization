//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ApplicationWindow {
    id: root
    property string firstRunFilePath: CF.FileUtils.trimFileProtocol(`${Directories.state}/user/first_run.txt`)
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property real contentPadding: 8
    property bool showNextTime: false
    property var pages: [
        {
            name: Translation.tr("Quick"),
            icon: "instant_mix",
            component: "modules/settings/QuickConfig.qml"
        },
        {
            name: Translation.tr("General"),
            icon: "browse",
            component: "modules/settings/GeneralConfig.qml"
        },
        {
            name: Translation.tr("Bar"),
            icon: "toast",
            iconRotation: 180,
            component: "modules/settings/BarConfig.qml"
        },
        {
            name: Translation.tr("Background"),
            icon: "texture",
            component: "modules/settings/BackgroundConfig.qml"
        },
        {
            name: Translation.tr("Interface"),
            icon: "bottom_app_bar",
            component: "modules/settings/InterfaceConfig.qml"
        },
        {
            name: Translation.tr("Mouse & Touchpad"),
            icon: "mouse",
            component: "modules/settings/InputConfig.qml"
        },
        {
            name: Translation.tr("Power Management"),
            icon: "battery_charging_full",
            component: "modules/settings/PowerConfig.qml"
        },
        {
            name: Translation.tr("Services"),
            icon: "settings",
            component: "modules/settings/ServicesConfig.qml"
        },
        {
            name: Translation.tr("Advanced"),
            icon: "construction",
            component: "modules/settings/AdvancedConfig.qml"
        },
        {
            name: Translation.tr("About"),
            icon: "info",
            component: "modules/settings/About.qml"
        }
    ]
    property int currentPage: 0

    function goToPage(nameOrIndex) {
        if (typeof nameOrIndex === "number") {
            if (nameOrIndex >= 0 && nameOrIndex < root.pages.length) {
                root.currentPage = nameOrIndex;
            }
            return;
        }
        let query = String(nameOrIndex).toLowerCase().trim();
        for (let i = 0; i < root.pages.length; ++i) {
            let page = root.pages[i];
            let pageName = (page.name || "").toLowerCase();
            let pageComp = (page.component || "").toLowerCase();
            if (pageName === query || pageComp.indexOf(query) !== -1 || (query === "power" && pageComp.indexOf("power") !== -1)) {
                root.currentPage = i;
                return;
            }
        }
    }

    IpcHandler {
        target: "settings"
        function openPage(nameOrIndex: string): void {
            root.goToPage(nameOrIndex);
            root.requestActivate();
            root.raise();
        }
    }

    property var searchIndex: [
        // Power Management (Page index 6)
        {
            title: Translation.tr("Power Profiles"),
            category: Translation.tr("Power Management"),
            pageIndex: 6,
            icon: "speed",
            keywords: ["power", "battery", "profile", "saver", "balanced", "performance", "cpu", "energy", "speed", "fan"]
        },
        {
            title: Translation.tr("Laptop Lid Behavior"),
            category: Translation.tr("Power Management"),
            pageIndex: 6,
            icon: "laptop_chromebook",
            keywords: ["lid", "laptop lid", "clamshell", "close lid", "sleep on lid", "lock on lid", "single monitor", "integrated monitor", "ignore"]
        },
        {
            title: Translation.tr("Lid Action on AC (Normal Power)"),
            category: Translation.tr("Power Management"),
            pageIndex: 6,
            icon: "power",
            keywords: ["ac", "charger", "plugged in", "normal power", "lid ac", "power level", "mains"]
        },
        {
            title: Translation.tr("Lid Action on Battery (Low Power)"),
            category: Translation.tr("Power Management"),
            pageIndex: 6,
            icon: "battery_charging_full",
            keywords: ["battery", "unplugged", "low power", "lid battery", "power level", "saver", "suspend"]
        },
        {
            title: Translation.tr("Auto-Lock Screen Duration"),
            category: Translation.tr("Power Management"),
            pageIndex: 6,
            icon: "schedule",
            keywords: ["auto lock", "screen lock", "lock timeout", "hyprlock", "lock duration", "idle lock", "inactivity lock"]
        },
        {
            title: Translation.tr("System Sleep / Suspend Interval"),
            category: Translation.tr("Power Management"),
            pageIndex: 6,
            icon: "bedtime",
            keywords: ["sleep", "suspend", "sleep interval", "sleep timeout", "idle sleep", "standby", "inactivity sleep"]
        },
        {
            title: Translation.tr("Connected Devices Battery"),
            category: Translation.tr("Power Management"),
            pageIndex: 6,
            icon: "devices_other",
            keywords: ["connected devices", "bluetooth battery", "headphones", "earbuds", "mouse battery", "keyboard battery", "peripherals", "stylus", "buds"]
        },
        {
            title: Translation.tr("Battery Level & Health"),
            category: Translation.tr("Power Management"),
            pageIndex: 6,
            icon: "battery_android_full",
            keywords: ["battery", "battery level", "health", "charging", "discharge", "rate", "watts", "percentage", "bat1"]
        },
        {
            title: Translation.tr("Low & Critical Battery Warnings"),
            category: Translation.tr("Power Management"),
            pageIndex: 6,
            icon: "battery_alert",
            keywords: ["battery alert", "low battery", "critical battery", "automatic suspend", "battery sound"]
        },

        // Mouse & Touchpad (Page index 5)
        {
            title: Translation.tr("Touchpad Tap to Click"),
            category: Translation.tr("Mouse & Touchpad"),
            pageIndex: 5,
            icon: "touch_app",
            keywords: ["touchpad", "tap", "click", "tap to click", "trackpad"]
        },
        {
            title: Translation.tr("Touchpad Natural Scrolling"),
            category: Translation.tr("Mouse & Touchpad"),
            pageIndex: 5,
            icon: "swap_vert",
            keywords: ["natural scroll", "reverse scroll", "scroll direction", "touchpad scrolling"]
        },
        {
            title: Translation.tr("Pointer Speed & Sensitivity"),
            category: Translation.tr("Mouse & Touchpad"),
            pageIndex: 5,
            icon: "mouse",
            keywords: ["sensitivity", "pointer speed", "cursor speed", "mouse speed", "acceleration", "accel profile"]
        },
        {
            title: Translation.tr("Disable Touchpad While Typing"),
            category: Translation.tr("Mouse & Touchpad"),
            pageIndex: 5,
            icon: "keyboard",
            keywords: ["disable while typing", "dwt", "palm rejection", "typing"]
        },
        {
            title: Translation.tr("Left-Handed Mouse Mode"),
            category: Translation.tr("Mouse & Touchpad"),
            pageIndex: 5,
            icon: "front_hand",
            keywords: ["left handed", "swap buttons", "mouse buttons", "handedness"]
        },

        // Bar (Page index 2)
        {
            title: Translation.tr("Top Bar Height & Sizing"),
            category: Translation.tr("Bar"),
            pageIndex: 2,
            icon: "straighten",
            keywords: ["bar height", "bar size", "top bar size", "thickness", "bar scale", "height", "size"]
        },
        {
            title: Translation.tr("Bar Position & Orientation"),
            category: Translation.tr("Bar"),
            pageIndex: 2,
            icon: "toast",
            keywords: ["bar position", "top bar", "bottom bar", "left bar", "vertical bar", "orientation"]
        },
        {
            title: Translation.tr("Bar Widgets & Indicators"),
            category: Translation.tr("Bar"),
            pageIndex: 2,
            icon: "widgets",
            keywords: ["battery indicator", "clock", "workspaces", "system tray", "resources", "cpu monitor", "ram monitor", "weather"]
        },

        // Quick (Page index 0)
        {
            title: Translation.tr("Dark / Light Mode & Theme"),
            category: Translation.tr("Quick"),
            pageIndex: 0,
            icon: "dark_mode",
            keywords: ["dark mode", "light mode", "theme", "toggle dark", "appearance", "night"]
        },
        {
            title: Translation.tr("Quick Accent Colors & Wallpaper"),
            category: Translation.tr("Quick"),
            pageIndex: 0,
            icon: "palette",
            keywords: ["wallpaper", "accent color", "material colors", "transparency", "opacity"]
        },

        // Background (Page index 3)
        {
            title: Translation.tr("Wallpaper & Lockscreen Background"),
            category: Translation.tr("Background"),
            pageIndex: 3,
            icon: "wallpaper",
            keywords: ["wallpaper", "background", "lockscreen", "slideshow", "dual monitor wallpaper", "blur"]
        },

        // Interface (Page index 4)
        {
            title: Translation.tr("Fonts & Typography"),
            category: Translation.tr("Interface"),
            pageIndex: 4,
            icon: "format_size",
            keywords: ["font", "fonts", "typography", "monospace", "google sans", "font size", "text size"]
        },
        {
            title: Translation.tr("Window Rounding & Styling"),
            category: Translation.tr("Interface"),
            pageIndex: 4,
            icon: "rounded_corner",
            keywords: ["rounding", "corner radius", "border radius", "window borders", "styling", "padding"]
        },

        // General (Page index 1)
        {
            title: Translation.tr("System Sounds & Audio Effects"),
            category: Translation.tr("General"),
            pageIndex: 1,
            icon: "volume_up",
            keywords: ["sounds", "sound effects", "battery sound", "audio", "feedback", "alerts"]
        },
        {
            title: Translation.tr("Clock, Date & Calendar Format"),
            category: Translation.tr("General"),
            pageIndex: 1,
            icon: "calendar_month",
            keywords: ["clock format", "date format", "12 hour", "24 hour", "calendar locale", "time format"]
        },
        {
            title: Translation.tr("Cheatsheet & Shortcuts"),
            category: Translation.tr("General"),
            pageIndex: 1,
            icon: "keyboard",
            keywords: ["cheatsheet", "shortcuts", "keybinds", "super key"]
        },

        // Services (Page index 7)
        {
            title: Translation.tr("AI Assistant Configuration"),
            category: Translation.tr("Services"),
            pageIndex: 7,
            icon: "neurology",
            keywords: ["ai", "gemini", "chatgpt", "system prompt", "llm", "assistant"]
        },
        {
            title: Translation.tr("Weather & Music Recognition"),
            category: Translation.tr("Services"),
            pageIndex: 7,
            icon: "cloud",
            keywords: ["weather", "music recognition", "shazam", "song identify", "api key"]
        },

        // Advanced (Page index 8)
        {
            title: Translation.tr("Configuration File & Tweaks"),
            category: Translation.tr("Advanced"),
            pageIndex: 8,
            icon: "construction",
            keywords: ["config file", "config.json", "json", "conflict killer", "debug"]
        },

        // About (Page index 9)
        {
            title: Translation.tr("System Information & Version"),
            category: Translation.tr("About"),
            pageIndex: 9,
            icon: "info",
            keywords: ["about", "system info", "version", "kernel", "distro", "quickshell"]
        }
    ]

    function getSearchResults(query) {
        if (!query || query.trim().length === 0) return [];
        let q = query.toLowerCase().trim();
        let qTokens = q.split(/\s+/).filter(t => t.length > 0);
        let results = [];

        for (let i = 0; i < root.searchIndex.length; ++i) {
            let item = root.searchIndex[i];
            let title = (item.title || "").toLowerCase();
            let cat = (item.category || "").toLowerCase();
            let keywords = item.keywords || [];

            let score = 0;
            if (title === q) score += 100;
            else if (title.startsWith(q)) score += 60;
            else if (title.indexOf(q) !== -1) score += 40;

            if (cat === q) score += 30;
            else if (cat.indexOf(q) !== -1) score += 20;

            let matchedTokens = 0;
            for (let t of qTokens) {
                let tokenMatched = false;
                if (title.indexOf(t) !== -1 || cat.indexOf(t) !== -1) {
                    score += 15;
                    tokenMatched = true;
                }
                for (let kw of keywords) {
                    let kwLower = kw.toLowerCase();
                    if (kwLower === t) {
                        score += 25;
                        tokenMatched = true;
                    } else if (kwLower.indexOf(t) !== -1) {
                        score += 10;
                        tokenMatched = true;
                    }
                }
                if (tokenMatched) matchedTokens++;
            }

            if (matchedTokens === qTokens.length || score >= 20) {
                results.push({
                    item: item,
                    score: score
                });
            }
        }

        results.sort((a, b) => b.score - a.score);
        return results.map(r => r.item).slice(0, 8);
    }

    visible: true
    onClosing: Qt.quit()
    title: "illogical-impulse Settings"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Config.readWriteDelay = 0 // Settings app always only sets one var at a time so delay isn't needed
        let envPage = Quickshell.env("QS_SETTINGS_PAGE");
        if (envPage && envPage.length > 0) {
            root.goToPage(envPage);
        }
    }

    minimumWidth: 750
    minimumHeight: 500
    width: 1100
    height: 750
    color: Appearance.m3colors.m3background

    ColumnLayout {
        anchors {
            fill: parent
            margins: contentPadding
        }

        Keys.onPressed: (event) => {
            if (event.modifiers === Qt.ControlModifier) {
                if (event.key === Qt.Key_F) {
                    searchInput.forceActiveFocus();
                    searchInput.selectAll();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_PageDown) {
                    root.currentPage = Math.min(root.currentPage + 1, root.pages.length - 1)
                    event.accepted = true;
                } 
                else if (event.key === Qt.Key_PageUp) {
                    root.currentPage = Math.max(root.currentPage - 1, 0)
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_Tab) {
                    root.currentPage = (root.currentPage + 1) % root.pages.length;
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_Backtab) {
                    root.currentPage = (root.currentPage - 1 + root.pages.length) % root.pages.length;
                    event.accepted = true;
                }
            }
        }

        Item { // Titlebar
            visible: Config.options?.windows.showTitlebar
            Layout.fillWidth: true
            Layout.fillHeight: false
            implicitHeight: Math.max(titleText.implicitHeight, windowControlsRow.implicitHeight, 38)
            z: 100

            StyledText {
                id: titleText
                anchors {
                    left: Config.options.windows.centerTitle ? undefined : parent.left
                    horizontalCenter: Config.options.windows.centerTitle ? parent.horizontalCenter : undefined
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                }
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("Settings")
                font {
                    family: Appearance.font.family.title
                    pixelSize: Appearance.font.pixelSize.title
                    variableAxes: Appearance.font.variableAxes.title
                }
            }

            // Search Box
            Rectangle {
                id: searchBox
                anchors {
                    right: windowControlsRow.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                implicitWidth: root.width > 900 ? (searchInput.activeFocus || searchInput.text.length > 0 ? 300 : 220) : (searchInput.activeFocus || searchInput.text.length > 0 ? 220 : 160)
                implicitHeight: 34
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer1
                border.width: searchInput.activeFocus ? 2 : 1
                border.color: searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer2

                Behavior on implicitWidth {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 8
                    }
                    spacing: 8

                    MaterialSymbol {
                        iconSize: 18
                        text: "search"
                        color: searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: Appearance.colors.colOnLayer1
                        selectionColor: Appearance.colors.colSecondaryContainer
                        selectedTextColor: Appearance.colors.colOnSecondaryContainer
                        font {
                            family: Appearance.font.family.main
                            pixelSize: Appearance.font.pixelSize.small
                        }
                        clip: true

                        StyledText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                            text: Translation.tr("Search settings... (Ctrl+F)")
                            color: Appearance.colors.colSubtext
                            font: searchInput.font
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                searchInput.text = "";
                                searchInput.focus = false;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                if (searchPopupList.count > 0) {
                                    searchPopupList.currentIndex = Math.min(searchPopupList.currentIndex + 1, searchPopupList.count - 1);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Up) {
                                if (searchPopupList.count > 0) {
                                    searchPopupList.currentIndex = Math.max(searchPopupList.currentIndex - 1, 0);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (searchPopupList.count > 0 && searchPopupList.currentIndex >= 0) {
                                    let match = searchPopupList.model[searchPopupList.currentIndex];
                                    if (match) {
                                        root.currentPage = match.pageIndex;
                                        searchInput.text = "";
                                        searchInput.focus = false;
                                        event.accepted = true;
                                    }
                                }
                            }
                        }
                    }

                    RippleButton {
                        visible: searchInput.text.length > 0
                        implicitWidth: 20
                        implicitHeight: 20
                        buttonRadius: Appearance.rounding.full
                        onClicked: {
                            searchInput.text = "";
                            searchInput.focus = true;
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            iconSize: 14
                            text: "close"
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                // Floating Dropdown Results Popup
                Rectangle {
                    id: searchDropdown
                    visible: searchInput.text.trim().length > 0 && searchPopupList.count > 0
                    anchors {
                        top: parent.bottom
                        topMargin: 8
                        right: parent.right
                    }
                    width: Math.max(searchBox.width, 360)
                    implicitHeight: Math.min(380, searchPopupList.contentHeight + 16)
                    radius: Appearance.rounding.windowRounding
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer2
                    z: 9999

                    StyledRectangularShadow {
                        target: searchDropdown
                    }

                    ListView {
                        id: searchPopupList
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        clip: true
                        model: root.getSearchResults(searchInput.text)
                        currentIndex: 0

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: searchPopupList.width
                            implicitHeight: 52
                            radius: Appearance.rounding.small
                            color: (index === searchPopupList.currentIndex || matchMouseArea.containsMouse)
                                ? Appearance.colors.colLayer2
                                : "transparent"

                            MouseArea {
                                id: matchMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.currentPage = modelData.pageIndex;
                                    searchInput.text = "";
                                    searchInput.focus = false;
                                }
                            }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 12
                                    rightMargin: 12
                                }
                                spacing: 12

                                MaterialSymbol {
                                    iconSize: 22
                                    text: modelData.icon || "settings"
                                    color: Appearance.colors.colPrimary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        text: modelData.title
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnLayer1
                                    }

                                    StyledText {
                                        text: modelData.category
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                    }
                                }

                                MaterialSymbol {
                                    iconSize: 16
                                    text: "arrow_forward"
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }
                }
            }

            RowLayout { // Window controls row
                id: windowControlsRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                RippleButton {
                    buttonRadius: Appearance.rounding.full
                    implicitWidth: 35
                    implicitHeight: 35
                    onClicked: root.close()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: "close"
                        iconSize: 20
                    }
                }
            }
        }

        RowLayout { // Window content with navigation rail and content pane
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: contentPadding
            Item {
                id: navRailWrapper
                Layout.fillHeight: true
                Layout.margins: 5
                implicitWidth: navRail.expanded ? 150 : fab.baseSize
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                NavigationRail { // Window content with navigation rail and content pane
                    id: navRail
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: 10
                    expanded: root.width > 900
                    
                    NavigationRailExpandButton {
                        focus: root.visible
                    }

                    FloatingActionButton {
                        id: fab
                        property bool justCopied: false
                        iconText: justCopied ? "check" : "edit"
                        buttonText: justCopied ? Translation.tr("Path copied") : Translation.tr("Config file")
                        expanded: navRail.expanded
                        downAction: () => {
                            Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`);
                        }
                        altAction: () => {
                            Quickshell.clipboardText = CF.FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                            fab.justCopied = true;
                            revertTextTimer.restart()
                        }

                        Timer {
                            id: revertTextTimer
                            interval: 1500
                            onTriggered: {
                                fab.justCopied = false;
                            }
                        }

                        StyledToolTip {
                            text: Translation.tr("Open the shell config file\nAlternatively right-click to copy path")
                        }
                    }

                    NavigationRailTabArray {
                        currentIndex: root.currentPage
                        expanded: navRail.expanded
                        Repeater {
                            model: root.pages
                            NavigationRailButton {
                                required property var index
                                required property var modelData
                                toggled: root.currentPage === index
                                onPressed: root.currentPage = index;
                                expanded: navRail.expanded
                                buttonIcon: modelData.icon
                                buttonIconRotation: modelData.iconRotation || 0
                                buttonText: modelData.name
                                showToggledHighlight: false
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
            Rectangle { // Content container
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.windowRounding - root.contentPadding

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    opacity: 1.0

                    active: Config.ready
                    Component.onCompleted: {
                        source = root.pages[root.currentPage].component
                    }

                    Connections {
                        target: root
                        function onCurrentPageChanged() {
                            switchAnim.complete();
                            switchAnim.start();
                        }
                    }

                    SequentialAnimation {
                        id: switchAnim

                        NumberAnimation {
                            target: pageLoader
                            properties: "opacity"
                            from: 1
                            to: 0
                            duration: 100
                            easing.type: Appearance.animation.elementMoveExit.type
                            easing.bezierCurve: Appearance.animationCurves.emphasizedFirstHalf
                        }
                        ParallelAnimation {
                            PropertyAction {
                                target: pageLoader
                                property: "source"
                                value: root.pages[root.currentPage].component
                            }
                            PropertyAction {
                                target: pageLoader
                                property: "anchors.topMargin"
                                value: 20
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: pageLoader
                                properties: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                                easing.type: Appearance.animation.elementMoveEnter.type
                                easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                            }
                            NumberAnimation {
                                target: pageLoader
                                properties: "anchors.topMargin"
                                to: 0
                                duration: 200
                                easing.type: Appearance.animation.elementMoveEnter.type
                                easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                            }
                        }
                    }
                }
            }
        }
    }
}

import "." as MenuUi
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: menuWindow

    property var theme: null
    property bool opened: false
    property var navigationStack: []
    property alias activeCategory: menuController.activeCategory
    property alias activeSubmenu: menuController.activeSubmenu
    property alias isLoading: menuController.isLoading
    property string searchQuery: ""
    property string pendingCommand: ""
    property string confirmCommand: ""
    property var activeSearchInput: null
    property var activeResultsFlick: null
    property var activeCategoryFlick: null
    property int selectedIndex: 0
    property bool suppressHoverSelection: false
    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#1b1613"
    readonly property string shellPath: "~/.config/quickshell/vellum_shell/shell.qml"
    readonly property var quickActions: [{
        "name": "Apps",
        "icon": "󰀻",
        "command": "quickshell ipc --path " + shellPath + " call launcher toggle",
        "path": "Start"
    }, {
        "name": "Clipboard",
        "icon": "",
        "command": "quickshell ipc --path " + shellPath + " call clipboard toggle",
        "path": "Start"
    }, {
        "name": "Appearance",
        "icon": "󰸌",
        "command": "quickshell ipc --path " + shellPath + " call style wallpaper",
        "path": "Style / Appearance Studio"
    }, {
        "name": "Network",
        "icon": "",
        "command": "quickshell ipc --path " + shellPath + " call network toggle",
        "path": "Setup"
    }, {
        "name": "Lock",
        "icon": "",
        "command": "quickshell ipc --path " + shellPath + " call lock lock",
        "path": "System"
    }, {
        "name": "Power",
        "icon": "󰐥",
        "sub": menuDataSource.powerActions,
        "path": "System"
    }]
    readonly property var searchResults: buildSearchResults(searchQuery)
    readonly property var localResults: buildLocalResults(searchQuery)
    readonly property var visibleItems: {
        if (searchQuery.trim() !== "" && activeCategory !== "")
            return localResults;

        if (searchQuery.trim() !== "")
            return searchResults;

        if (isLoading)
            return [];

        if (activeCategory !== "")
            return activeSubmenu;

        return quickActions;
    }
    property alias currentDynamicIcon: menuController.currentDynamicIcon
    property alias currentDynamicCommandPrefix: menuController.currentDynamicCommandPrefix
    property alias currentDynamicPath: menuController.currentDynamicPath
    property alias currentDynamicType: menuController.currentDynamicType
    property var menuData: menuDataSource.items

    function normalize(value) {
        return (value || "").toString().toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
    }

    function words(value) {
        var normalized = normalize(value);
        return normalized === "" ? [] : normalized.split(/\s+/);
    }

    function itemPath(item) {
        return item.path ? item.path : activeCategory;
    }

    function cloneItem(item, path) {
        var copy = {
        };
        for (var key in item) copy[key] = item[key]
        copy.path = path;
        return copy;
    }

    function collectItems(items, path, result) {
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            var nextPath = path === "" ? item.name : path + " / " + item.name;
            result.push(cloneItem(item, path));
            if (item.sub)
                collectItems(item.sub, nextPath, result);

        }
    }

    function searchScore(item, queryWords) {
        var name = normalize(item.name);
        var path = normalize(item.path);
        var full = (name + " " + path).trim();
        var score = 0;
        for (var i = 0; i < queryWords.length; i++) {
            var word = queryWords[i];
            if (name === word)
                score += 120;
            else if (name.startsWith(word))
                score += 80;
            else if (name.indexOf(word) >= 0)
                score += 45;
            else if (path.indexOf(word) >= 0)
                score += 20;
            else if (full.indexOf(word) >= 0)
                score += 10;
            else
                return 0;
        }
        if (item.command)
            score += 8;

        if (item.dynamic)
            score += 5;

        return score;
    }

    function buildSearchResults(query) {
        var queryWords = words(query);
        if (queryWords.length === 0)
            return [];

        var all = [];
        collectItems(menuData, "", all);
        var matches = [];
        for (var i = 0; i < all.length; i++) {
            var score = searchScore(all[i], queryWords);
            if (score > 0)
                matches.push({
                "item": all[i],
                "score": score
            });

        }
        matches.sort((a, b) => {
            return b.score - a.score || a.item.name.localeCompare(b.item.name);
        });
        var result = [];
        for (var j = 0; j < matches.length && j < 40; j++) result.push(matches[j].item)
        return result;
    }

    function buildLocalResults(query) {
        var queryWords = words(query);
        if (queryWords.length === 0)
            return activeSubmenu;

        var matches = [];
        for (var i = 0; i < activeSubmenu.length; i++) {
            var score = searchScore(activeSubmenu[i], queryWords);
            if (score > 0)
                matches.push({
                "item": activeSubmenu[i],
                "score": score
            });

        }
        matches.sort((a, b) => {
            return b.score - a.score || a.item.name.localeCompare(b.item.name);
        });
        var result = [];
        for (var j = 0; j < matches.length && j < 40; j++) result.push(matches[j].item)
        return result;
    }

    function resetMenu() {
        menuController.cancelDynamic();
        confirmTimer.stop();
        confirmCommand = "";
        navigationStack = [];
        activeCategory = "";
        activeSubmenu = [];
        suppressHoverSelection = false;
        searchQuery = "";
        if (activeSearchInput)
            activeSearchInput.text = "";

        if (activeCategoryFlick)
            activeCategoryFlick.contentY = 0;

        selectedIndex = 0;
    }

    function goBack() {
        if (navigationStack.length > 0) {
            var prev = navigationStack.pop();
            activeCategory = prev.category;
            activeSubmenu = prev.submenu;
        } else {
            activeCategory = "";
            activeSubmenu = [];
        }
    }

    function openSub(category, submenu) {
        if (activeCategory !== "")
            navigationStack.push({
            "category": activeCategory,
            "submenu": activeSubmenu
        });

        activeCategory = category;
        activeSubmenu = submenu;
        searchQuery = "";
        if (activeSearchInput)
            activeSearchInput.text = "";

    }

    function openItem(item) {
        if (!item || isLoading)
            return ;

        if (item.sub) {
            openSub(item.name, item.sub);
        } else if (item.dynamic) {
            if (activeCategory !== "" && activeCategory !== item.name)
                navigationStack.push({
                "category": activeCategory,
                "submenu": activeSubmenu
            });

            activeCategory = item.name;
            searchQuery = "";
            if (activeSearchInput)
                activeSearchInput.text = "";

            fetchDynamic(item.dynamic.cmd, item.dynamic.icon, item.dynamic.prefix, item.path || activeCategory);
        } else if (item.keybindings) {
            if (activeCategory !== "" && activeCategory !== item.name)
                navigationStack.push({
                "category": activeCategory,
                "submenu": activeSubmenu
            });

            activeCategory = item.name;
            searchQuery = "";
            if (activeSearchInput)
                activeSearchInput.text = "";

            fetchKeybindings(item.path || activeCategory);
        } else if (item.command) {
            if (item.confirm && confirmCommand !== item.command) {
                confirmCommand = item.command;
                confirmTimer.restart();
                return;
            }
            confirmCommand = "";
            if (shouldDelayForCapture(item.command)) {
                pendingCommand = item.command;
                menuWindow.opened = false;
                delayedCommandTimer.restart();
            } else {
                execute(item.command);
                menuWindow.opened = false;
            }
        }
    }

    function activateSelected() {
        if (visibleItems.length === 0)
            return ;

        openItem(visibleItems[Math.max(0, Math.min(selectedIndex, visibleItems.length - 1))]);
    }

    function loadDynamicOutput(output) {
        menuController.loadDynamicOutput(output);
    }

    function loadKeybindingsOutput(output) {
        menuController.loadKeybindingsOutput(output);
    }

    function modMaskLabel(mask) {
        return menuController.modMaskLabel(mask);
    }

    function keyLabel(binding) {
        return menuController.keyLabel(binding);
    }

    function loadKeybindingsJson(output) {
        menuController.loadKeybindingsJson(output);
    }

    function fetchDynamic(cmd, icon, prefix, path) {
        menuController.fetchDynamic(cmd, icon, prefix, path);
    }

    function fetchKeybindings(path) {
        menuController.fetchKeybindings(path);
    }

    function ensureSelectedVisible() {
        if (activeResultsFlick && activeResultsFlick.ensureIndexVisible)
            activeResultsFlick.ensureIndexVisible(selectedIndex);
    }

    function clampResultsScroll() {
        if (!activeResultsFlick)
            return ;

        var maxY = Math.max(0, activeResultsFlick.contentHeight - activeResultsFlick.height);
        activeResultsFlick.contentY = Math.max(0, Math.min(activeResultsFlick.contentY, maxY));
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            menuWindow.opened = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers === Qt.ControlModifier)) {
            suppressHoverSelection = true;
            selectedIndex = Math.min(selectedIndex + 1, Math.max(visibleItems.length - 1, 0));
            ensureSelectedVisible();
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers === Qt.ControlModifier)) {
            suppressHoverSelection = true;
            selectedIndex = Math.max(selectedIndex - 1, 0);
            ensureSelectedVisible();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateSelected();
            event.accepted = true;
        } else if ((event.key === Qt.Key_Left || event.key === Qt.Key_Backspace) && activeCategory !== "" && searchQuery === "") {
            goBack();
            event.accepted = true;
        }
    }

    function execute(cmd) {
        proc.command = ["sh", "-c", cmd];
        proc.running = true;
    }

    function shouldDelayForCapture(cmd) {
        return cmd.indexOf("capture-") !== -1 || cmd.indexOf("screenrecord") !== -1;
    }

    onSearchQueryChanged: {
        confirmCommand = "";
        suppressHoverSelection = false;
        selectedIndex = 0;
        if (activeResultsFlick)
            activeResultsFlick.contentY = 0;

    }
    onActiveSubmenuChanged: {
        confirmCommand = "";
        suppressHoverSelection = false;
        selectedIndex = 0;
        if (activeResultsFlick)
            activeResultsFlick.contentY = 0;

    }
    onSelectedIndexChanged: confirmCommand = ""
    onVisibleItemsChanged: {
        selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(visibleItems.length - 1, 0)));
        clampResultsScroll();
    }
    onOpenedChanged: {
        if (opened)
            focusTimer.start();
        else
            resetMenu();
    }
    visible: opened || content.opacity > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.menu"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? 1 : 0 // 1 = Exclusive, 0 = None

    MenuUi.MenuController {
        id: menuController
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Timer {
        id: focusTimer

        interval: 100
        onTriggered: {
            if (activeSearchInput)
                activeSearchInput.forceActiveFocus();

        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: menuWindow.opened
        onClicked: menuWindow.opened = false
    }

    Item {
        id: content

        anchors.centerIn: parent
        enabled: menuWindow.opened
        width: Math.min(840, menuWindow.width - 32)
        height: Math.min(500, Math.max(350, 220 + Math.min(visibleItems.length, 6) * 46), menuWindow.height - 40)
        opacity: menuWindow.opened ? 1 : 0
        scale: menuWindow.opened ? 1 : 0.96

        Behavior on height {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        transform: Translate {
            y: menuWindow.opened ? 0 : 12

            Behavior on y {
                NumberAnimation {
                    duration: menuWindow.opened ? 240 : 120
                    easing.type: menuWindow.opened ? Easing.OutQuart : Easing.InQuad
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 1
            radius: 0
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => {
                    return mouse.accepted = true;
                }
            }

            Loader {
                id: paletteLoader

                anchors.fill: parent
                source: "MenuPaletteView.qml"
                onLoaded: item.host = menuWindow
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: panelAccent
                border.width: 1
                z: 2
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: menuWindow.opened ? 160 : 110
                easing.type: menuWindow.opened ? Easing.OutQuart : Easing.InQuad
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: menuWindow.opened ? 260 : 130
                easing.type: menuWindow.opened ? Easing.OutQuart : Easing.InQuad
            }

        }

    }

    Process {
        id: proc
    }

    Timer {
        id: delayedCommandTimer

        interval: 260
        onTriggered: {
            if (pendingCommand !== "") {
                var command = pendingCommand;
                pendingCommand = "";
                execute(command);
            }
        }
    }

    Timer {
        id: confirmTimer

        interval: 2200
        onTriggered: confirmCommand = ""
    }

    MenuData {
        id: menuDataSource
    }

}

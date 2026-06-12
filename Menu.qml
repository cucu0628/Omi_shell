import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: menuWindow
    
    property var theme: null
    property bool opened: false
    
    property var navigationStack: []
    property string activeCategory: ""
    property var activeSubmenu: []
    property bool isLoading: false
    property string searchQuery: ""
    property string pendingCommand: ""

    property int selectedIndex: 0

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"
    readonly property string inkBg: "#1b1613"

    readonly property var quickActions: [
        { name: "Apps", icon: "󰀻", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call launcher toggle", path: "Start" },
        { name: "Keybindings", icon: "", keybindings: true, path: "Learn" },
        { name: "Theme", icon: "󰸌", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call style theme", path: "Style" },
        { name: "Wifi", icon: "", command: "omarchy-launch-wifi", path: "Setup" },
        { name: "Lock", icon: "", command: "uwsm-app -- quickshell --path ~/.config/quickshell/LockShell.qml", path: "System" },
        { name: "Power", icon: "󰐥", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call power toggle", path: "System" }
    ]

    readonly property var searchResults: buildSearchResults(searchQuery)
    readonly property var localResults: buildLocalResults(searchQuery)

    readonly property var visibleItems: {
        if (searchQuery.trim() !== "" && activeCategory !== "") return localResults
        if (searchQuery.trim() !== "") return searchResults
        if (isLoading) return []
        if (activeCategory !== "") return activeSubmenu
        return quickActions
    }

    onSearchQueryChanged: {
        selectedIndex = 0
        resultsFlick.contentY = 0
    }
    onActiveSubmenuChanged: {
        selectedIndex = 0
        resultsFlick.contentY = 0
    }
    onVisibleItemsChanged: {
        selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(visibleItems.length - 1, 0)))
        clampResultsScroll()
    }

    function normalize(value) {
        return (value || "").toString().toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
    }

    function words(value) {
        var normalized = normalize(value)
        return normalized === "" ? [] : normalized.split(/\s+/)
    }

    function itemPath(item) {
        return item.path ? item.path : activeCategory
    }

    function cloneItem(item, path) {
        var copy = {}
        for (var key in item) copy[key] = item[key]
        copy.path = path
        return copy
    }

    function collectItems(items, path, result) {
        for (var i = 0; i < items.length; i++) {
            var item = items[i]
            var nextPath = path === "" ? item.name : path + " / " + item.name
            result.push(cloneItem(item, path))
            if (item.sub) collectItems(item.sub, nextPath, result)
        }
    }

    function searchScore(item, queryWords) {
        var name = normalize(item.name)
        var path = normalize(item.path)
        var full = (name + " " + path).trim()
        var score = 0

        for (var i = 0; i < queryWords.length; i++) {
            var word = queryWords[i]
            if (name === word) score += 120
            else if (name.startsWith(word)) score += 80
            else if (name.indexOf(word) >= 0) score += 45
            else if (path.indexOf(word) >= 0) score += 20
            else if (full.indexOf(word) >= 0) score += 10
            else return 0
        }

        if (item.command) score += 8
        if (item.dynamic) score += 5
        return score
    }

    function buildSearchResults(query) {
        var queryWords = words(query)
        if (queryWords.length === 0) return []

        var all = []
        collectItems(menuData, "", all)

        var matches = []
        for (var i = 0; i < all.length; i++) {
            var score = searchScore(all[i], queryWords)
            if (score > 0) matches.push({ item: all[i], score: score })
        }

        matches.sort((a, b) => b.score - a.score || a.item.name.localeCompare(b.item.name))

        var result = []
        for (var j = 0; j < matches.length && j < 40; j++) result.push(matches[j].item)
        return result
    }

    function buildLocalResults(query) {
        var queryWords = words(query)
        if (queryWords.length === 0) return activeSubmenu

        var matches = []
        for (var i = 0; i < activeSubmenu.length; i++) {
            var score = searchScore(activeSubmenu[i], queryWords)
            if (score > 0) matches.push({ item: activeSubmenu[i], score: score })
        }

        matches.sort((a, b) => b.score - a.score || a.item.name.localeCompare(b.item.name))

        var result = []
        for (var j = 0; j < matches.length && j < 40; j++) result.push(matches[j].item)
        return result
    }

    onOpenedChanged: {
        if (opened) {
            focusTimer.start()
        } else {
            resetMenu()
        }
    }

    function resetMenu() {
        navigationStack = []
        activeCategory = ""
        activeSubmenu = []
        isLoading = false
        searchQuery = ""
        searchInput.text = ""
        categoryFlick.contentY = 0
        selectedIndex = 0
    }

    function goBack() {
        if (navigationStack.length > 0) {
            var prev = navigationStack.pop()
            activeCategory = prev.category
            activeSubmenu = prev.submenu
        } else {
            activeCategory = ""
            activeSubmenu = []
        }
    }

    function openSub(category, submenu) {
        if (activeCategory !== "") {
            navigationStack.push({category: activeCategory, submenu: activeSubmenu})
        }
        activeCategory = category
        activeSubmenu = submenu
        searchQuery = ""
    }

    function openItem(item) {
        if (!item) return
        if (item.sub) {
            openSub(item.name, item.sub)
        } else if (item.dynamic) {
            if (activeCategory !== "" && activeCategory !== item.name) {
                navigationStack.push({category: activeCategory, submenu: activeSubmenu})
            }
            activeCategory = item.name
            searchQuery = ""
            fetchDynamic(item.dynamic.cmd, item.dynamic.icon, item.dynamic.prefix, item.path || activeCategory)
        } else if (item.keybindings) {
            if (activeCategory !== "" && activeCategory !== item.name) {
                navigationStack.push({category: activeCategory, submenu: activeSubmenu})
            }
            activeCategory = item.name
            searchQuery = ""
            searchInput.text = ""
            fetchKeybindings(item.path || activeCategory)
        } else if (item.command) {
            if (shouldDelayForCapture(item.command)) {
                pendingCommand = item.command
                menuWindow.opened = false
                delayedCommandTimer.restart()
            } else {
                execute(item.command)
                menuWindow.opened = false
            }
        }
    }

    function activateSelected() {
        if (visibleItems.length === 0) return
        openItem(visibleItems[Math.max(0, Math.min(selectedIndex, visibleItems.length - 1))])
    }

    Process {
        id: dynamicFetcher
        onExited: (exitCode) => {
            isLoading = false
            dynamicTimeout.stop()
            if (exitCode !== 0) activeSubmenu = []
        }

        stdout: StdioCollector {
            onStreamFinished: loadDynamicOutput(this.text || "")
        }
    }

    Timer {
        id: dynamicTimeout
        interval: 3500
        onTriggered: {
            isLoading = false
            if (activeSubmenu.length === 0) activeSubmenu = []
        }
    }
    
    property string currentDynamicIcon: ""
    property string currentDynamicCommandPrefix: ""
    property string currentDynamicPath: ""
    property string currentDynamicType: "default"

    function loadDynamicOutput(output) {
        if (currentDynamicType === "keybindings") {
            loadKeybindingsOutput(output)
            return
        }

        var out = (output || "").trim()
        if (out === "") {
            activeSubmenu = []
            return
        }

        var lines = out.split("\n")
        var newSub = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line !== "") {
                var displayName = line
                var value = line
                if (line.includes("/")) {
                    displayName = line.split("/").pop().replace(/\.[^/.]+$/, "").replace(/[-_]/g, " ")
                    displayName = displayName.replace(/\w\S*/g, (txt) => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase())
                }

                newSub.push({
                    name: displayName,
                    icon: currentDynamicIcon,
                    path: currentDynamicPath,
                    command: currentDynamicCommandPrefix + " \"" + value + "\""
                })
            }
        }
        activeSubmenu = newSub
    }

    function loadKeybindingsOutput(output) {
        var out = (output || "").trim()
        if (out === "") {
            activeSubmenu = []
            return
        }

        if (out.charAt(0) === "[") {
            loadKeybindingsJson(out)
            return
        }

        var lines = out.split("\n")
        var newSub = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "") continue

            var arrowIndex = line.indexOf("→")
            var shortcut = arrowIndex >= 0 ? line.slice(0, arrowIndex).trim() : line
            var action = arrowIndex >= 0 ? line.slice(arrowIndex + 1).trim() : ""

            newSub.push({
                name: shortcut,
                icon: "",
                path: action,
                readonly: true
            })
        }
        activeSubmenu = newSub
    }

    function modMaskLabel(mask) {
        var parts = []
        if (mask & 64) parts.push("SUPER")
        if (mask & 4) parts.push("CTRL")
        if (mask & 8) parts.push("ALT")
        if (mask & 1) parts.push("SHIFT")
        return parts.join(" + ")
    }

    function keyLabel(binding) {
        if (binding.key && binding.key !== "") return binding.key.replace("mouse:272", "LEFT MOUSE BUTTON").replace("mouse:273", "RIGHT MOUSE BUTTON")
        if (binding.keycode && binding.keycode !== 0) return "keycode " + binding.keycode
        return ""
    }

    function loadKeybindingsJson(output) {
        var parsed = []
        try {
            parsed = JSON.parse(output)
        } catch (error) {
            activeSubmenu = []
            return
        }

        var newSub = []
        for (var i = 0; i < parsed.length; i++) {
            var binding = parsed[i]
            var modifiers = modMaskLabel(binding.modmask || 0)
            var key = keyLabel(binding)
            var shortcut = modifiers !== "" && key !== "" ? modifiers + " + " + key : key
            var action = binding.description && binding.description !== "" ? binding.description : ((binding.dispatcher || "") + (binding.arg ? " " + binding.arg : ""))

            if (shortcut === "" && action === "") continue

            newSub.push({
                name: shortcut,
                icon: "",
                path: action,
                readonly: true
            })
        }
        activeSubmenu = newSub
    }

    function fetchDynamic(cmd, icon, prefix, path) {
        isLoading = true
        activeSubmenu = []
        currentDynamicIcon = icon
        currentDynamicCommandPrefix = prefix
        currentDynamicPath = path || activeCategory
        currentDynamicType = "default"
        dynamicTimeout.restart()
        dynamicFetcher.command = ["sh", "-c", cmd]
        dynamicFetcher.running = true
    }

    function fetchKeybindings(path) {
        isLoading = true
        activeSubmenu = []
        currentDynamicPath = path || activeCategory
        currentDynamicType = "keybindings"
        dynamicTimeout.restart()
        dynamicFetcher.command = ["hyprctl", "binds", "-j"]
        dynamicFetcher.running = true
    }
    
    visible: opened || content.opacity > 0
    color: "transparent"
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.menu"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? 1 : 0 // 1 = Exclusive, 0 = None

    Timer {
        id: focusTimer
        interval: 100
        onTriggered: searchInput.forceActiveFocus()
    }

    function ensureSelectedVisible() {
        var itemHeight = 67
        var top = selectedIndex * itemHeight
        var bottom = top + itemHeight
        var maxY = Math.max(0, resultsFlick.contentHeight - resultsFlick.height)
        if (top < resultsFlick.contentY) {
            resultsFlick.contentY = Math.max(0, Math.min(top, maxY))
        } else if (bottom > resultsFlick.contentY + resultsFlick.height) {
            resultsFlick.contentY = Math.max(0, Math.min(bottom - resultsFlick.height, maxY))
        }
    }

    function clampResultsScroll() {
        var maxY = Math.max(0, resultsFlick.contentHeight - resultsFlick.height)
        resultsFlick.contentY = Math.max(0, Math.min(resultsFlick.contentY, maxY))
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            menuWindow.opened = false
            event.accepted = true
        } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers === Qt.ControlModifier)) {
            selectedIndex = Math.min(selectedIndex + 1, Math.max(visibleItems.length - 1, 0))
            ensureSelectedVisible()
            event.accepted = true
        } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers === Qt.ControlModifier)) {
            selectedIndex = Math.max(selectedIndex - 1, 0)
            ensureSelectedVisible()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateSelected()
            event.accepted = true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: menuWindow.opened = false
    }

    Item {
        id: content
        anchors.centerIn: parent
        
        width: mainContainer.width
        height: mainContainer.height
        
        opacity: menuWindow.opened ? 1 : 0
        scale: menuWindow.opened ? 1 : 0.98
        
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

        Rectangle {
            id: mainContainer
            width: Math.min(820, menuWindow.width - 40)
            height: Math.min(560, menuWindow.height - 60)
            color: panelBg
            border.color: panelAccent
            border.width: 2
            radius: 0
            clip: true

            Rectangle {
                width: 210
                height: 210
                radius: 105
                x: parent.width - 125
                y: -95
                color: panelAccent
                opacity: 0.13
            }

            Rectangle {
                width: 160
                height: 160
                radius: 80
                x: -70
                y: parent.height - 75
                color: "#f0b35a"
                opacity: 0.10
            }
            
            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Row {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 22

                Column {
                    id: sidebar
                    width: Math.min(215, parent.width * 0.32)
                    height: parent.height
                    spacing: 16

                    Column {
                        spacing: 3
                        Text {
                            text: "KOMOREBI"
                            color: panelAccent
                            font.pixelSize: 10
                            font.letterSpacing: 5
                            font.bold: true
                        }
                        Text {
                            text: "Omarchy Menu"
                            color: panelFg
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "静かな操作 / calm control"
                            color: mutedFg
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 46
                        radius: 0
                        color: inkBg
                        border.color: searchInput.activeFocus ? panelAccent : mutedFg
                        border.width: searchInput.activeFocus ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            text: "⌕"
                            color: panelAccent
                            font.pixelSize: 18
                            anchors.left: parent.left
                            anchors.leftMargin: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            anchors.left: parent.left
                            anchors.leftMargin: 40
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height - 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: panelFg
                            font.pixelSize: 15
                            focus: menuWindow.opened
                            onTextChanged: searchQuery = text
                            Keys.onPressed: (event) => handleKey(event)

                            Text {
                                text: "Search everything..."
                                color: mutedFg
                                visible: parent.text === ""
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Text {
                        text: "ICHIRAN"
                        color: panelAccent
                        font.pixelSize: 10
                        font.letterSpacing: 4
                        font.bold: true
                    }

                    Flickable {
                        id: categoryFlick
                        width: parent.width
                        height: parent.height - 190
                        contentHeight: categoryColumn.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: categoryColumn
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: menuData

                                Rectangle {
                                    width: categoryColumn.width
                                    height: 40
                                    radius: 0
                                    color: (catMouse.containsMouse || activeCategory === modelData.name) ? inkBg : "transparent"
                                    border.color: activeCategory === modelData.name && searchQuery === "" ? panelAccent : "transparent"
                                    border.width: activeCategory === modelData.name && searchQuery === "" ? 1 : 0
                                    opacity: catMouse.containsMouse || activeCategory === modelData.name ? 1 : 0.72
                                    scale: 1

                                    Behavior on color { ColorAnimation { duration: 110 } }
                                    Behavior on border.width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                    Rectangle {
                                        width: 3
                                        height: parent.height
                                        anchors.left: parent.left
                                        color: panelAccent
                                        opacity: catMouse.containsMouse || activeCategory === modelData.name ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 10

                                        Text {
                                            text: modelData.icon
                                            font.family: "omarchy"
                                            font.pixelSize: 16
                                            color: activeCategory === modelData.name && searchQuery === "" ? panelAccent : panelFg
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: modelData.name
                                            color: activeCategory === modelData.name && searchQuery === "" ? panelAccent : panelFg
                                            font.pixelSize: 13
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: catMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.sub) openSub(modelData.name, modelData.sub)
                                            else openItem(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width - sidebar.width - 22
                    height: parent.height
                    spacing: 14

                    Row {
                        width: parent.width
                        height: 36
                        spacing: 12

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 0
                            color: "transparent"
                            border.color: mutedFg
                            border.width: 1
                            visible: activeCategory !== "" && searchQuery === ""

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "omarchy"
                                font.pixelSize: 13
                                color: panelFg
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: goBack()
                            }
                        }

                        Column {
                            width: parent.width - 130
                            spacing: 1

                            Text {
                                text: searchQuery.trim() !== "" ? "SEARCH" : (activeCategory === "" ? "QUICK ACTIONS" : "CATEGORY")
                                color: panelAccent
                                font.pixelSize: 10
                                font.letterSpacing: 4
                                font.bold: true
                            }

                            Text {
                                text: searchQuery.trim() !== "" ? visibleItems.length + " result" + (visibleItems.length === 1 ? "" : "s") : (activeCategory === "" ? "Start here" : activeCategory)
                                color: panelFg
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            text: "↑↓ enter esc"
                            color: mutedFg
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: panelAccent
                        opacity: 0.45
                    }

                    Item {
                        width: parent.width
                        height: parent.height - 65

                        Text {
                            visible: isLoading
                            anchors.centerIn: parent
                            text: "Loading..."
                            color: panelAccent
                            font.pixelSize: 15
                        }

                        Text {
                            visible: !isLoading && visibleItems.length === 0
                            anchors.centerIn: parent
                            text: searchQuery.trim() !== "" ? "No matches" : "Choose a category"
                            color: mutedFg
                            font.pixelSize: 15
                        }

                        Flickable {
                            id: resultsFlick
                            anchors.fill: parent
                            contentHeight: resultsColumn.height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            visible: !isLoading && visibleItems.length > 0
                            interactive: contentHeight > height

                            Column {
                                id: resultsColumn
                                width: parent.width
                                spacing: 9

                            Repeater {
                                model: visibleItems

                                Rectangle {
                                    width: resultsColumn.width
                                    height: 58
                                    radius: 0
                                    color: resultMouse.containsMouse || index === selectedIndex ? inkBg : "transparent"
                                    border.color: index === selectedIndex ? panelAccent : "transparent"
                                    border.width: index === selectedIndex ? 1 : 0
                                    scale: 1

                                    Behavior on color { ColorAnimation { duration: 110 } }
                                    Behavior on border.width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                                    Rectangle {
                                        width: 3
                                        height: parent.height
                                        anchors.left: parent.left
                                        color: panelAccent
                                        opacity: resultMouse.containsMouse || index === selectedIndex ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 12
                                        spacing: 13

                                        Text {
                                            text: modelData.icon || "•"
                                            font.family: "omarchy"
                                            font.pixelSize: 19
                                            color: index === selectedIndex ? panelAccent : panelFg
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Column {
                                            width: parent.width - 75
                                            spacing: 2
                                            anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                                text: modelData.name
                                                font.pixelSize: 14
                                                font.weight: Font.DemiBold
                                                color: index === selectedIndex ? panelAccent : panelFg
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }

                                            Text {
                                                text: itemPath(modelData)
                                                font.pixelSize: 11
                                                color: mutedFg
                                                opacity: index === selectedIndex ? 0.9 : 1
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }
                                        }

                                        Text {
                                            text: modelData.sub ? "›" : ""
                                            font.pixelSize: 22
                                            color: panelAccent
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: resultMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: selectedIndex = index
                                        onClicked: {
                                            selectedIndex = index
                                            openItem(modelData)
                                        }
                                    }
                                }
                            }
                            }
                        }
                    }
                }
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
                var command = pendingCommand
                pendingCommand = ""
                execute(command)
            }
        }
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function execute(cmd) {
        if (cmd.startsWith("xdg-terminal-exec")) {
            var terminalCmd = cmd.replace(/^xdg-terminal-exec\s*/, "")
            proc.command = ["sh", "-c", "omarchy-launch-floating-terminal-with-presentation " + shellQuote(terminalCmd)]
        } else {
            proc.command = ["sh", "-c", cmd]
        }
        proc.running = true
    }

    function shouldDelayForCapture(cmd) {
        return cmd.indexOf("omarchy-capture-") !== -1 || cmd.indexOf("screenrecord") !== -1
    }

    MenuData { id: menuDataSource }
    property var menuData: menuDataSource.items
}

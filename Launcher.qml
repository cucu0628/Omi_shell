import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets

PanelWindow {
    id: launcherWindow

    property var theme: null
    property bool opened: false
    property string query: ""
    property int selectedIndex: 0
    property string calcResult: ""
    property var launchStats: ({})

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"
    readonly property string inkBg: "#1b1613"
    readonly property bool calcMode: query.trim().startsWith("=")
    readonly property bool commandMode: query.trim().startsWith(">")
    readonly property bool webMode: query.trim().startsWith("?")
    readonly property bool emojiMode: query.trim().startsWith(":")
    readonly property string calcExpression: calcMode ? query.trim().slice(1).trim() : ""
    readonly property string commandText: commandMode ? query.trim().slice(1).trim() : ""
    readonly property string webQuery: webMode ? query.trim().slice(1).trim() : ""
    readonly property string emojiQuery: emojiMode ? query.trim().slice(1).trim() : ""
    readonly property var appResults: buildAppResults(query)
    readonly property var visibleItems: calcMode ? calcItems() : (commandMode ? commandItems() : (webMode ? webItems() : (emojiMode ? emojiItems() : appResults)))

    readonly property var aliases: [
        { name: "browser", terms: ["web", "internet"], command: "xdg-open https://www.google.com", icon: "󰖟", subtitle: "Open default browser" },
        { name: "terminal", terms: ["term", "shell"], command: "xdg-terminal-exec", icon: "", subtitle: "Open terminal" },
        { name: "files", terms: ["file", "folder", "nautilus"], command: "xdg-open $HOME", icon: "", subtitle: "Open home folder" },
        { name: "settings", terms: ["control", "preferences"], command: "quickshell ipc --path ~/.config/quickshell/shell.qml call menu toggle", icon: "", subtitle: "Open Quickshell menu" }
    ]

    readonly property var emojis: [
        { emoji: "😀", name: "grinning face", keywords: "smile happy grin" },
        { emoji: "😄", name: "smiling eyes", keywords: "smile happy laugh" },
        { emoji: "😂", name: "tears of joy", keywords: "laugh lol joy funny" },
        { emoji: "🤣", name: "rolling laughing", keywords: "laugh rofl funny" },
        { emoji: "🙂", name: "slightly smiling", keywords: "smile" },
        { emoji: "😉", name: "wink", keywords: "flirt joke" },
        { emoji: "😊", name: "blush", keywords: "smile happy cute" },
        { emoji: "😍", name: "heart eyes", keywords: "love heart" },
        { emoji: "😘", name: "kiss", keywords: "love kiss" },
        { emoji: "😎", name: "cool", keywords: "sunglasses awesome" },
        { emoji: "🤔", name: "thinking", keywords: "think hmm question" },
        { emoji: "🙃", name: "upside down", keywords: "sarcasm silly" },
        { emoji: "😅", name: "sweat smile", keywords: "nervous relief" },
        { emoji: "😭", name: "loudly crying", keywords: "cry sad tears" },
        { emoji: "😡", name: "angry", keywords: "mad rage" },
        { emoji: "😴", name: "sleeping", keywords: "sleep tired" },
        { emoji: "🤯", name: "mind blown", keywords: "shock wow" },
        { emoji: "🥳", name: "party", keywords: "celebrate birthday" },
        { emoji: "👍", name: "thumbs up", keywords: "yes ok good approve" },
        { emoji: "👎", name: "thumbs down", keywords: "no bad reject" },
        { emoji: "👏", name: "clapping", keywords: "clap applause" },
        { emoji: "🙏", name: "folded hands", keywords: "please thanks pray" },
        { emoji: "💪", name: "flexed biceps", keywords: "strong muscle" },
        { emoji: "🔥", name: "fire", keywords: "hot lit flame" },
        { emoji: "✨", name: "sparkles", keywords: "shine magic clean" },
        { emoji: "💯", name: "hundred", keywords: "100 perfect" },
        { emoji: "✅", name: "check mark", keywords: "done yes complete" },
        { emoji: "❌", name: "cross mark", keywords: "no fail error" },
        { emoji: "⚠️", name: "warning", keywords: "alert caution" },
        { emoji: "❤️", name: "red heart", keywords: "love heart" },
        { emoji: "💔", name: "broken heart", keywords: "sad heartbreak" },
        { emoji: "🎉", name: "party popper", keywords: "celebrate party" },
        { emoji: "🚀", name: "rocket", keywords: "launch fast ship" },
        { emoji: "💡", name: "light bulb", keywords: "idea tip" },
        { emoji: "🐛", name: "bug", keywords: "bug issue error" },
        { emoji: "📌", name: "pushpin", keywords: "pin mark" },
        { emoji: "📎", name: "paperclip", keywords: "attach clip" },
        { emoji: "📅", name: "calendar", keywords: "date schedule" },
        { emoji: "⏰", name: "alarm clock", keywords: "time reminder" },
        { emoji: "☕", name: "coffee", keywords: "drink cafe" },
        { emoji: "🍕", name: "pizza", keywords: "food" },
        { emoji: "🍺", name: "beer", keywords: "drink cheers" },
        { emoji: "🌙", name: "moon", keywords: "night dark" },
        { emoji: "☀️", name: "sun", keywords: "day light" },
        { emoji: "⭐", name: "star", keywords: "favorite rating" },
        { emoji: "⚡", name: "zap", keywords: "fast power lightning" },
        { emoji: "🔒", name: "lock", keywords: "secure private" },
        { emoji: "🔓", name: "unlock", keywords: "open" },
        { emoji: "🧠", name: "brain", keywords: "think smart ai" },
        { emoji: "🤖", name: "robot", keywords: "bot ai" }
    ]

    Component.onCompleted: loadLaunchStats()

    onOpenedChanged: {
        if (opened) {
            focusTimer.start()
        } else {
            resetLauncher()
        }
    }

    onQueryChanged: {
        selectedIndex = 0
        resultsFlick.contentY = 0
        if (calcMode && calcExpression !== "") {
            calcTimer.restart()
        } else {
            calcTimer.stop()
            calcResult = ""
        }
    }

    onVisibleItemsChanged: {
        selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(visibleItems.length - 1, 0)))
        clampResultsScroll()
    }

    function resetLauncher() {
        query = ""
        searchInput.text = ""
        selectedIndex = 0
        calcResult = ""
        resultsFlick.contentY = 0
        calcTimer.stop()
    }

    function normalize(value) {
        return (value || "").toString().toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
    }

    function words(value) {
        var normalized = normalize(value)
        return normalized === "" ? [] : normalized.split(/\s+/)
    }

    function scoreApp(app, queryWords) {
        var name = normalize(app.name)
        var generic = normalize(app.genericName)
        var comment = normalize(app.comment)
        var id = normalize(app.id)
        var haystack = (name + " " + generic + " " + comment + " " + id).trim()
        var score = appStatScore(app)

        for (var i = 0; i < queryWords.length; i++) {
            var word = queryWords[i]
            if (name === word) score += 130
            else if (name.startsWith(word)) score += 90
            else if (name.indexOf(word) >= 0) score += 55
            else if (generic.indexOf(word) >= 0) score += 30
            else if (id.indexOf(word) >= 0) score += 20
            else if (haystack.indexOf(word) >= 0) score += 10
            else return 0
        }

        return score
    }

    function buildAppResults(value) {
        if (calcMode || commandMode || webMode || emojiMode) return []

        var queryWords = words(value)
        var apps = DesktopEntries.applications.values
        var matches = []

        for (var i = 0; i < apps.length; i++) {
            var app = apps[i]
            var score = queryWords.length === 0 ? 1 + appStatScore(app) : scoreApp(app, queryWords)
            if (score > 0) matches.push({ app: app, score: score })
        }

        for (var a = 0; a < aliases.length; a++) {
            var aliasScore = scoreAlias(aliases[a], queryWords)
            if (aliasScore > 0) matches.push({ item: { type: "alias", alias: aliases[a] }, score: aliasScore })
        }

        matches.sort((a, b) => b.score - a.score || itemSortName(a).localeCompare(itemSortName(b)))

        var result = []
        for (var j = 0; j < matches.length && j < 200; j++) result.push(matches[j].item || { type: "app", app: matches[j].app })
        return result
    }

    function appStatScore(app) {
        var key = app.id || app.name
        var stat = launchStats[key]
        if (!stat) return 0
        return Math.min(60, (stat.count || 0) * 4) + Math.max(0, 30 - Math.floor((Date.now() / 1000 - (stat.last || 0)) / 86400))
    }

    function itemSortName(match) {
        if (match.app) return match.app.name
        if (match.item && match.item.type === "alias") return match.item.alias.name
        return ""
    }

    function scoreAlias(alias, queryWords) {
        if (queryWords.length === 0) return 0
        var haystack = normalize(alias.name + " " + alias.terms.join(" "))
        var score = 15
        for (var i = 0; i < queryWords.length; i++) {
            var word = queryWords[i]
            if (alias.name === word) score += 140
            else if (alias.name.startsWith(word)) score += 100
            else if (haystack.indexOf(word) >= 0) score += 45
            else return 0
        }
        return score
    }

    function calcItems() {
        if (calcExpression === "") return [{ type: "hint", title: "Type an expression", subtitle: "Example: =sqrt(144) + 8" }]
        if (calcResult === "") return [{ type: "hint", title: "Calculating...", subtitle: calcExpression }]
        return [{ type: "calc", title: calcResult, subtitle: calcExpression }]
    }

    function commandItems() {
        if (commandText === "") return [{ type: "hint", title: "Run a command", subtitle: "Example: >hyprctl reload" }]
        return [{ type: "command", title: commandText, subtitle: "Run in shell" }]
    }

    function webItems() {
        if (webQuery === "") return [{ type: "hint", title: "Search the web", subtitle: "Example: ?quickshell widgets" }]
        return [{ type: "web", title: webQuery, subtitle: "Search with default browser" }]
    }

    function emojiItems() {
        var queryWords = words(emojiQuery)
        var result = []
        if (queryWords.length === 0) {
            for (var i = 0; i < emojis.length && i < 40; i++) result.push({ type: "emoji", emoji: emojis[i] })
            return result
        }

        var matches = []
        for (var j = 0; j < emojis.length; j++) {
            var emoji = emojis[j]
            var haystack = normalize(emoji.name + " " + emoji.keywords)
            var score = 0
            for (var k = 0; k < queryWords.length; k++) {
                var word = queryWords[k]
                if (normalize(emoji.name) === word) score += 100
                else if (normalize(emoji.name).startsWith(word)) score += 70
                else if (haystack.indexOf(word) >= 0) score += 35
                else {
                    score = 0
                    break
                }
            }
            if (score > 0) matches.push({ emoji: emoji, score: score })
        }
        matches.sort((a, b) => b.score - a.score || a.emoji.name.localeCompare(b.emoji.name))
        for (var m = 0; m < matches.length && m < 40; m++) result.push({ type: "emoji", emoji: matches[m].emoji })
        return result
    }

    function itemTitle(item) {
        if (item.type === "app") return item.app.name
        if (item.type === "alias") return item.alias.name
        if (item.type === "emoji") return item.emoji.emoji + "  " + item.emoji.name
        return item.title
    }

    function itemSubtitle(item) {
        if (item.type === "app") return item.app.genericName || item.app.comment || item.app.id
        if (item.type === "alias") return item.alias.subtitle
        if (item.type === "emoji") return ":" + item.emoji.keywords
        return item.subtitle
    }

    function itemIcon(item) {
        if (item.type === "calc") return "󰃬"
        if (item.type === "hint") return "󰋼"
        if (item.type === "command") return ""
        if (item.type === "web") return "󰖟"
        if (item.type === "alias") return item.alias.icon
        if (item.type === "emoji") return item.emoji.emoji
        return ""
    }

    function appIconSource(app) {
        if (!app) return ""

        var candidates = []
        if (app.icon !== "") candidates.push(app.icon)
        if (app.id !== "") candidates.push(app.id.replace(/\.desktop$/, ""))
        if (app.name !== "") candidates.push(app.name.toLowerCase().replace(/\s+/g, "-"))

        for (var i = 0; i < candidates.length; i++) {
            var icon = candidates[i]
            if (!icon || icon === "") continue
            if (icon.startsWith("/")) return "file://" + icon
            if (icon.startsWith("file:")) return icon

            var path = Quickshell.iconPath(icon, true)
            if (path !== "") return path
        }

        return ""
    }

    function activateSelected() {
        if (visibleItems.length === 0) return
        var item = visibleItems[Math.max(0, Math.min(selectedIndex, visibleItems.length - 1))]

        if (item.type === "app") {
            item.app.execute()
            recordLaunch(item.app.id || item.app.name)
            opened = false
        } else if (item.type === "calc" && calcResult !== "") {
            copyProcess.command = ["sh", "-c", "printf %s " + shellQuote(calcResult) + " | wl-copy"]
            copyProcess.running = true
            opened = false
        } else if (item.type === "command" && commandText !== "") {
            runProcess.command = ["sh", "-c", commandText]
            runProcess.running = true
            opened = false
        } else if (item.type === "web" && webQuery !== "") {
            runProcess.command = ["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(webQuery)]
            runProcess.running = true
            opened = false
        } else if (item.type === "alias") {
            runProcess.command = ["sh", "-c", item.alias.command]
            runProcess.running = true
            opened = false
        } else if (item.type === "emoji") {
            copyProcess.command = ["sh", "-c", "printf %s " + shellQuote(item.emoji.emoji) + " | wl-copy"]
            copyProcess.running = true
            opened = false
        }
    }

    function loadLaunchStats() {
        statsLoader.command = ["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\"; awk -F '\\t' '{ c[$1]++; l[$1]=$2 } END { for (id in c) printf \"%s\\t%d\\t%s\\n\", id, c[id], l[id] }' \"$HOME/.cache/quickshell/launcher-frecent.tsv\" 2>/dev/null"]
        statsLoader.running = true
    }

    function parseLaunchStats(output) {
        var stats = {}
        var lines = (output || "").trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("\t")
            if (parts.length >= 3 && parts[0] !== "") stats[parts[0]] = { count: parseInt(parts[1]) || 0, last: parseInt(parts[2]) || 0 }
        }
        launchStats = stats
    }

    function recordLaunch(id) {
        if (!id || id === "") return
        var now = Math.floor(Date.now() / 1000)
        var stats = launchStats
        var current = stats[id] || { count: 0, last: 0 }
        current.count = current.count + 1
        current.last = now
        stats[id] = current
        launchStats = stats
        statsWriter.command = ["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\"; printf '%s\\t%s\\n' " + shellQuote(id) + " " + shellQuote(now.toString()) + " >> \"$HOME/.cache/quickshell/launcher-frecent.tsv\""]
        statsWriter.running = true
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function ensureSelectedVisible() {
        var itemHeight = 62
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
            opened = false
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

    visible: opened || content.opacity > 0
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.launcher"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? 1 : 0

    Timer {
        id: focusTimer
        interval: 80
        onTriggered: searchInput.forceActiveFocus()
    }

    Timer {
        id: calcTimer
        interval: 120
        onTriggered: {
            calcProcess.command = ["qalc", "-t", calcExpression]
            calcProcess.running = true
        }
    }

    Process {
        id: calcProcess
        stdout: StdioCollector {
            onStreamFinished: calcResult = (this.text || "").trim().split("\n")[0] || ""
        }
    }

    Process {
        id: copyProcess
    }

    Process { id: runProcess }
    Process { id: statsWriter }
    Process { id: statsLoader; stdout: StdioCollector { onStreamFinished: parseLaunchStats(this.text || "") } }

    MouseArea {
        anchors.fill: parent
        onClicked: opened = false
    }

    Item {
        id: content
        anchors.centerIn: parent
        width: Math.min(700, launcherWindow.width - 40)
        height: Math.min(480, launcherWindow.height - 60)
        opacity: opened ? 1 : 0
        scale: opened ? 1 : 0.98

        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 2
            radius: 0
            clip: true

            Rectangle {
                width: 170
                height: 170
                radius: 85
                x: parent.width - 95
                y: -80
                color: panelAccent
                opacity: 0.13
            }

            Rectangle {
                width: 130
                height: 130
                radius: 65
                x: -55
                y: parent.height - 55
                color: "#f0b35a"
                opacity: 0.10
            }

            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Row {
                    width: parent.width
                    height: 48
                    spacing: 18

                    Column {
                        width: 190
                        spacing: 2

                        Text {
                            text: "KIDO"
                            color: panelAccent
                            font.pixelSize: 10
                            font.letterSpacing: 5
                            font.bold: true
                        }

                        Text {
                            text: "App Launcher"
                            color: panelFg
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        width: parent.width - 208
                        height: 44
                        radius: 0
                        color: inkBg
                        border.color: searchInput.activeFocus ? panelAccent : mutedFg
                        border.width: searchInput.activeFocus ? 2 : 1
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            text: calcMode ? "=" : (commandMode ? ">" : (webMode ? "?" : (emojiMode ? ":" : "⌕")))
                            color: panelAccent
                            font.pixelSize: 18
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            anchors.left: parent.left
                            anchors.leftMargin: 42
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height - 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: panelFg
                            font.pixelSize: 15
                            focus: opened
                            onTextChanged: query = text
                            Keys.onPressed: event => handleKey(event)

                            Text {
                                text: "Search apps, :emoji, =calc, ?web, >command"
                                color: mutedFg
                                visible: parent.text === ""
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 20

                    Text {
                        anchors.left: parent.left
                        text: calcMode ? "CALCULATOR" : (commandMode ? "COMMAND" : (webMode ? "WEB SEARCH" : (emojiMode ? "EMOJI / " + visibleItems.length : "APPLICATIONS / " + visibleItems.length)))
                        color: panelAccent
                        font.pixelSize: 10
                        font.letterSpacing: 4
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        text: "↑↓ enter esc"
                        color: mutedFg
                        font.pixelSize: 11
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
                    height: parent.height - 102

                    Text {
                        visible: visibleItems.length === 0
                        anchors.centerIn: parent
                        text: "No matches"
                        color: mutedFg
                        font.pixelSize: 15
                    }

                    Flickable {
                        id: resultsFlick
                        anchors.fill: parent
                        contentHeight: resultsColumn.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        visible: visibleItems.length > 0
                        interactive: contentHeight > height

                        Column {
                            id: resultsColumn
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: visibleItems

                                Rectangle {
                                    width: resultsColumn.width
                                    height: 54
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

                                        Item {
                                            width: 30
                                            height: 30
                                            anchors.verticalCenter: parent.verticalCenter

                                            IconImage {
                                                id: appIcon
                                                anchors.fill: parent
                                                source: modelData.type === "app" ? appIconSource(modelData.app) : ""
                                                visible: source !== ""
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: itemIcon(modelData)
                                                font.family: modelData.type === "emoji" ? "sans-serif" : "omarchy"
                                                font.pixelSize: modelData.type === "emoji" ? 22 : 19
                                                color: index === selectedIndex ? panelAccent : panelFg
                                                visible: modelData.type !== "app"
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰣆"
                                                font.family: "omarchy"
                                                font.pixelSize: 18
                                                color: index === selectedIndex ? panelAccent : panelFg
                                                visible: modelData.type === "app" && appIcon.source === ""
                                            }
                                        }

                                        Column {
                                            width: parent.width - 58
                                            spacing: 2
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                text: itemTitle(modelData)
                                                font.pixelSize: 14
                                                font.weight: Font.DemiBold
                                                color: index === selectedIndex ? panelAccent : panelFg
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }

                                            Text {
                                                text: itemSubtitle(modelData)
                                                font.pixelSize: 11
                                                color: mutedFg
                                                opacity: index === selectedIndex ? 0.9 : 1
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }
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
                                            activateSelected()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: mutedFg
                        opacity: resultsFlick.visible && resultsFlick.interactive ? 0.18 : 0
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 2
                        height: resultsFlick.visible && resultsFlick.contentHeight > 0 ? Math.max(24, parent.height * resultsFlick.visibleArea.heightRatio) : 0
                        y: resultsFlick.visible ? resultsFlick.visibleArea.yPosition * parent.height : 0
                        color: panelAccent
                        opacity: resultsFlick.visible && resultsFlick.interactive ? 0.9 : 0
                        Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}

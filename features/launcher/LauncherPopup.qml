import "." as LauncherUi
import "../../ui" as SharedUi
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: launcherWindow

    property var theme: null
    property bool opened: false
    property string query: ""
    property int selectedIndex: 0
    property string calcResult: ""
    property bool suppressHoverSelection: false
    property var applications: []
    property var projects: []
    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#1b1613"
    readonly property bool calcMode: query.trim().startsWith("=")
    readonly property bool projectMode: query.trim().startsWith(">")
    readonly property bool webMode: query.trim().startsWith("?")
    readonly property bool emojiMode: query.trim().startsWith(":")
    readonly property bool hasQuery: query.trim() !== ""
    readonly property string calcExpression: calcMode ? query.trim().slice(1).trim() : ""
    readonly property string projectQuery: projectMode ? query.trim().slice(1).trim() : ""
    readonly property string webQuery: webMode ? query.trim().slice(1).trim() : ""
    readonly property string emojiQuery: emojiMode ? query.trim().slice(1).trim() : ""
    readonly property string modeTitle: calcMode ? "CALCULATOR" : (projectMode ? "PROJECTS" : (webMode ? "WEB SEARCH" : (emojiMode ? "EMOJI" : "APPLICATIONS")))
    readonly property var appResults: buildAppResults(query)
    readonly property var visibleItems: calcMode ? calcItems() : (projectMode ? projectItems() : (webMode ? webItems() : (emojiMode ? emojiItems() : appResults)))
    readonly property real resultsHeight: visibleItems.length > 0 ? visibleItems.length * 50 - 4 : 46
    readonly property var aliases: [{
        "name": "browser",
        "terms": ["web", "internet"],
        "command": "xdg-open https://www.google.com",
        "icon": "󰖟",
        "subtitle": "Open default browser"
    }, {
        "name": "terminal",
        "terms": ["term", "shell"],
        "command": "kitty",
        "icon": "",
        "subtitle": "Open terminal"
    }, {
        "name": "files",
        "terms": ["file", "folder", "nautilus"],
        "command": "xdg-open $HOME",
        "icon": "",
        "subtitle": "Open home folder"
    }, {
        "name": "settings",
        "terms": ["control", "preferences", "menu"],
        "command": "quickshell ipc --path ~/.config/quickshell/vellum_shell/shell.qml call menu toggle",
        "icon": "",
        "subtitle": "Open shell menu"
    }]
    readonly property var emojis: [{
        "emoji": "😀",
        "name": "grinning face",
        "keywords": "smile happy grin"
    }, {
        "emoji": "😄",
        "name": "smiling eyes",
        "keywords": "smile happy laugh"
    }, {
        "emoji": "😂",
        "name": "tears of joy",
        "keywords": "laugh lol joy funny"
    }, {
        "emoji": "🤣",
        "name": "rolling laughing",
        "keywords": "laugh rofl funny"
    }, {
        "emoji": "🙂",
        "name": "slightly smiling",
        "keywords": "smile"
    }, {
        "emoji": "😉",
        "name": "wink",
        "keywords": "flirt joke"
    }, {
        "emoji": "😊",
        "name": "blush",
        "keywords": "smile happy cute"
    }, {
        "emoji": "😍",
        "name": "heart eyes",
        "keywords": "love heart"
    }, {
        "emoji": "😘",
        "name": "kiss",
        "keywords": "love kiss"
    }, {
        "emoji": "😎",
        "name": "cool",
        "keywords": "sunglasses awesome"
    }, {
        "emoji": "🤔",
        "name": "thinking",
        "keywords": "think hmm question"
    }, {
        "emoji": "🙃",
        "name": "upside down",
        "keywords": "sarcasm silly"
    }, {
        "emoji": "😅",
        "name": "sweat smile",
        "keywords": "nervous relief"
    }, {
        "emoji": "😭",
        "name": "loudly crying",
        "keywords": "cry sad tears"
    }, {
        "emoji": "😡",
        "name": "angry",
        "keywords": "mad rage"
    }, {
        "emoji": "😴",
        "name": "sleeping",
        "keywords": "sleep tired"
    }, {
        "emoji": "🤯",
        "name": "mind blown",
        "keywords": "shock wow"
    }, {
        "emoji": "🥳",
        "name": "party",
        "keywords": "celebrate birthday"
    }, {
        "emoji": "👍",
        "name": "thumbs up",
        "keywords": "yes ok good approve"
    }, {
        "emoji": "👎",
        "name": "thumbs down",
        "keywords": "no bad reject"
    }, {
        "emoji": "👏",
        "name": "clapping",
        "keywords": "clap applause"
    }, {
        "emoji": "🙏",
        "name": "folded hands",
        "keywords": "please thanks pray"
    }, {
        "emoji": "💪",
        "name": "flexed biceps",
        "keywords": "strong muscle"
    }, {
        "emoji": "🔥",
        "name": "fire",
        "keywords": "hot lit flame"
    }, {
        "emoji": "✨",
        "name": "sparkles",
        "keywords": "shine magic clean"
    }, {
        "emoji": "💯",
        "name": "hundred",
        "keywords": "100 perfect"
    }, {
        "emoji": "✅",
        "name": "check mark",
        "keywords": "done yes complete"
    }, {
        "emoji": "❌",
        "name": "cross mark",
        "keywords": "no fail error"
    }, {
        "emoji": "⚠️",
        "name": "warning",
        "keywords": "alert caution"
    }, {
        "emoji": "❤️",
        "name": "red heart",
        "keywords": "love heart"
    }, {
        "emoji": "💔",
        "name": "broken heart",
        "keywords": "sad heartbreak"
    }, {
        "emoji": "🎉",
        "name": "party popper",
        "keywords": "celebrate party"
    }, {
        "emoji": "🚀",
        "name": "rocket",
        "keywords": "launch fast ship"
    }, {
        "emoji": "💡",
        "name": "light bulb",
        "keywords": "idea tip"
    }, {
        "emoji": "🐛",
        "name": "bug",
        "keywords": "bug issue error"
    }, {
        "emoji": "📌",
        "name": "pushpin",
        "keywords": "pin mark"
    }, {
        "emoji": "📎",
        "name": "paperclip",
        "keywords": "attach clip"
    }, {
        "emoji": "📅",
        "name": "calendar",
        "keywords": "date schedule"
    }, {
        "emoji": "⏰",
        "name": "alarm clock",
        "keywords": "time reminder"
    }, {
        "emoji": "☕",
        "name": "coffee",
        "keywords": "drink cafe"
    }, {
        "emoji": "🍕",
        "name": "pizza",
        "keywords": "food"
    }, {
        "emoji": "🍺",
        "name": "beer",
        "keywords": "drink cheers"
    }, {
        "emoji": "🌙",
        "name": "moon",
        "keywords": "night dark"
    }, {
        "emoji": "☀️",
        "name": "sun",
        "keywords": "day light"
    }, {
        "emoji": "⭐",
        "name": "star",
        "keywords": "favorite rating"
    }, {
        "emoji": "⚡",
        "name": "zap",
        "keywords": "fast power lightning"
    }, {
        "emoji": "🔒",
        "name": "lock",
        "keywords": "secure private"
    }, {
        "emoji": "🔓",
        "name": "unlock",
        "keywords": "open"
    }, {
        "emoji": "🧠",
        "name": "brain",
        "keywords": "think smart ai"
    }, {
        "emoji": "🤖",
        "name": "robot",
        "keywords": "bot ai"
    }]

    function refreshApplications() {
        applications = DesktopEntries.applications.values.slice();
    }

    function refreshProjects() {
        if (projectsProcess.running)
            return ;

        projectsProcess.command = ["sh", "-c", "find \"$HOME/Projects\" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print 2>/dev/null | sort -f"];
        projectsProcess.running = true;
    }

    function parseProjects(output) {
        var lines = (output || "").trim().split("\n");
        var result = [];
        for (var i = 0; i < lines.length; i++) {
            var path = lines[i].trim();
            if (path === "")
                continue;

            result.push({
                "type": "project",
                "title": path.slice(path.lastIndexOf("/") + 1),
                "subtitle": path,
                "path": path
            });
        }
        projects = result;
    }

    function resetLauncher() {
        suppressHoverSelection = false;
        query = "";
        searchField.text = "";
        selectedIndex = 0;
        calcResult = "";
        resultsList.contentY = 0;
        calcTimer.stop();
    }

    function normalize(value) {
        return (value || "").toString().toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
    }

    function words(value) {
        var normalized = normalize(value);
        return normalized === "" ? [] : normalized.split(/\s+/);
    }

    function scoreApp(app, queryWords) {
        var name = normalize(app.name);
        var generic = normalize(app.genericName);
        var comment = normalize(app.comment);
        var id = normalize(app.id);
        var haystack = (name + " " + generic + " " + comment + " " + id).trim();
        var score = appStatScore(app);
        for (var i = 0; i < queryWords.length; i++) {
            var word = queryWords[i];
            if (name === word)
                score += 130;
            else if (name.startsWith(word))
                score += 90;
            else if (name.indexOf(word) >= 0)
                score += 55;
            else if (generic.indexOf(word) >= 0)
                score += 30;
            else if (id.indexOf(word) >= 0)
                score += 20;
            else if (haystack.indexOf(word) >= 0)
                score += 10;
            else
                return 0;
        }
        return score;
    }

    function buildAppResults(value) {
        if (calcMode || projectMode || webMode || emojiMode)
            return [];

        var queryWords = words(value);
        if (queryWords.length === 0)
            return [];

        var apps = applications;
        var matches = [];
        for (var i = 0; i < apps.length; i++) {
            var app = apps[i];
            var score = scoreApp(app, queryWords);
            if (score > 0)
                matches.push({
                "app": app,
                "score": score
            });

        }
        for (var a = 0; a < aliases.length; a++) {
            var aliasScore = scoreAlias(aliases[a], queryWords);
            if (aliasScore > 0)
                matches.push({
                "item": {
                    "type": "alias",
                    "alias": aliases[a]
                },
                "score": aliasScore
            });

        }
        matches.sort((a, b) => {
            return b.score - a.score || itemSortName(a).localeCompare(itemSortName(b));
        });
        var result = [];
        for (var j = 0; j < matches.length && j < 50; j++) result.push(matches[j].item || {
            "type": "app",
            "app": matches[j].app
        })
        return result;
    }

    function appStatScore(app) {
        return frecencyStore.score(app);
    }

    function itemSortName(match) {
        if (match.app)
            return match.app.name;

        if (match.item && match.item.type === "alias")
            return match.item.alias.name;

        return "";
    }

    function scoreAlias(alias, queryWords) {
        if (queryWords.length === 0)
            return 0;

        var haystack = normalize(alias.name + " " + alias.terms.join(" "));
        var score = 15;
        for (var i = 0; i < queryWords.length; i++) {
            var word = queryWords[i];
            if (alias.name === word)
                score += 140;
            else if (alias.name.startsWith(word))
                score += 100;
            else if (haystack.indexOf(word) >= 0)
                score += 45;
            else
                return 0;
        }
        return score;
    }

    function calcItems() {
        if (calcExpression === "")
            return [{
            "type": "hint",
            "title": "Type an expression",
            "subtitle": "Example: =sqrt(144) + 8"
        }];

        if (calcResult === "")
            return [{
            "type": "hint",
            "title": "Calculating...",
            "subtitle": calcExpression
        }];

        return [{
            "type": "calc",
            "title": calcResult,
            "subtitle": calcExpression
        }];
    }

    function projectItems() {
        var queryWords = words(projectQuery);
        var result = [];
        for (var i = 0; i < projects.length; i++) {
            var project = projects[i];
            var haystack = normalize(project.title + " " + project.path);
            var matches = true;
            for (var j = 0; j < queryWords.length; j++) {
                if (haystack.indexOf(queryWords[j]) === -1) {
                    matches = false;
                    break;
                }
            }
            if (matches)
                result.push(project);
        }
        return result;
    }

    function webItems() {
        if (webQuery === "")
            return [{
            "type": "hint",
            "title": "Search the web",
            "subtitle": "Example: ?quickshell widgets"
        }];

        return [{
            "type": "web",
            "title": webQuery,
            "subtitle": "Search with default browser"
        }];
    }

    function emojiItems() {
        var queryWords = words(emojiQuery);
        var result = [];
        if (queryWords.length === 0) {
            for (var i = 0; i < emojis.length && i < 40; i++) result.push({
                "type": "emoji",
                "emoji": emojis[i]
            })
            return result;
        }
        var matches = [];
        for (var j = 0; j < emojis.length; j++) {
            var emoji = emojis[j];
            var haystack = normalize(emoji.name + " " + emoji.keywords);
            var score = 0;
            for (var k = 0; k < queryWords.length; k++) {
                var word = queryWords[k];
                if (normalize(emoji.name) === word) {
                    score += 100;
                } else if (normalize(emoji.name).startsWith(word)) {
                    score += 70;
                } else if (haystack.indexOf(word) >= 0) {
                    score += 35;
                } else {
                    score = 0;
                    break;
                }
            }
            if (score > 0)
                matches.push({
                "emoji": emoji,
                "score": score
            });

        }
        matches.sort((a, b) => {
            return b.score - a.score || a.emoji.name.localeCompare(b.emoji.name);
        });
        for (var m = 0; m < matches.length && m < 40; m++) result.push({
            "type": "emoji",
            "emoji": matches[m].emoji
        })
        return result;
    }

    function itemTitle(item) {
        if (!item)
            return "";

        if (item.type === "app")
            return item.app ? (item.app.name || item.app.id || "Application") : "Application";

        if (item.type === "alias")
            return item.alias ? item.alias.name : "";

        if (item.type === "emoji")
            return item.emoji ? item.emoji.emoji + "  " + item.emoji.name : "";

        return item.title || "";
    }

    function itemSubtitle(item) {
        if (!item)
            return "";

        if (item.type === "app")
            return item.app ? (item.app.genericName || item.app.comment || item.app.id || "") : "";

        if (item.type === "alias")
            return item.alias ? item.alias.subtitle : "";

        if (item.type === "emoji")
            return item.emoji ? ":" + item.emoji.keywords : "";

        return item.subtitle || "";
    }

    function itemIcon(item) {
        if (!item)
            return "";

        if (item.type === "calc")
            return "󰃬";

        if (item.type === "hint")
            return "󰋼";

        if (item.type === "project")
            return "󰉋";

        if (item.type === "web")
            return "󰖟";

        if (item.type === "alias")
            return item.alias ? item.alias.icon : "";

        if (item.type === "emoji")
            return item.emoji ? item.emoji.emoji : "";

        return "";
    }

    function activateSelected() {
        if (visibleItems.length === 0)
            return ;

        var item = visibleItems[Math.max(0, Math.min(selectedIndex, visibleItems.length - 1))];
        if (item.type === "app") {
            item.app.execute();
            frecencyStore.record(item.app.id || item.app.name);
            opened = false;
        } else if (item.type === "calc" && calcResult !== "") {
            copyProcess.command = ["sh", "-c", "printf %s " + shellQuote(calcResult) + " | wl-copy"];
            copyProcess.running = true;
            opened = false;
        } else if (item.type === "project" && item.path) {
            runProcess.command = ["code", item.path];
            runProcess.running = true;
            opened = false;
        } else if (item.type === "web" && webQuery !== "") {
            runProcess.command = ["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(webQuery)];
            runProcess.running = true;
            opened = false;
        } else if (item.type === "alias") {
            runProcess.command = ["sh", "-c", item.alias.command];
            runProcess.running = true;
            opened = false;
        } else if (item.type === "emoji") {
            copyProcess.command = ["sh", "-c", "printf %s " + shellQuote(item.emoji.emoji) + " | wl-copy"];
            copyProcess.running = true;
            opened = false;
        }
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'";
    }

    function modeActive(prefix) {
        if (prefix === "=")
            return calcMode;

        if (prefix === ">")
            return projectMode;

        if (prefix === "?")
            return webMode;

        if (prefix === ":")
            return emojiMode;

        return !calcMode && !projectMode && !webMode && !emojiMode;
    }

    function selectMode(prefix) {
        searchField.text = prefix;
        query = prefix;
        searchField.forceInputFocus();
    }

    function cycleMode(reverse) {
        var prefixes = ["", ":", "=", "?", ">"];
        var current = 0;
        for (var i = 0; i < prefixes.length; i++) {
            if (modeActive(prefixes[i])) {
                current = i;
                break;
            }
        }
        var direction = reverse ? -1 : 1;
        selectMode(prefixes[(current + direction + prefixes.length) % prefixes.length]);
    }

    function ensureSelectedVisible() {
        if (visibleItems.length > 0)
            resultsList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function clampResultsScroll() {
        var maxY = Math.max(0, resultsList.contentHeight - resultsList.height);
        resultsList.contentY = Math.max(0, Math.min(resultsList.contentY, maxY));
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            cycleMode(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier));
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            opened = false;
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
        }
    }

    onOpenedChanged: {
        if (opened) {
            refreshApplications();
            refreshProjects();
            focusTimer.start();
        } else {
            resetLauncher();
        }
    }
    Component.onCompleted: {
        refreshApplications();
        refreshProjects();
    }
    onQueryChanged: {
        suppressHoverSelection = false;
        selectedIndex = 0;
        resultsList.contentY = 0;
        if (calcMode && calcExpression !== "") {
            calcTimer.restart();
        } else {
            calcTimer.stop();
            calcResult = "";
        }
    }
    onVisibleItemsChanged: {
        selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(visibleItems.length - 1, 0)));
        clampResultsScroll();
    }
    visible: opened || content.opacity > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.launcher"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? 1 : 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Timer {
        id: focusTimer

        interval: 80
        onTriggered: searchField.forceInputFocus()
    }

    Timer {
        id: calcTimer

        interval: 120
        onTriggered: {
            calcProcess.command = ["qalc", "-t", calcExpression];
            calcProcess.running = true;
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

    Process {
        id: runProcess
    }

    Process {
        id: projectsProcess

        stdout: StdioCollector {
            onStreamFinished: launcherWindow.parseProjects(this.text || "")
        }
    }

    LauncherUi.FrecencyStore {
        id: frecencyStore
    }

    LauncherUi.DesktopIconResolver {
        id: iconResolver
    }

    MouseArea {
        anchors.fill: parent
        enabled: opened
        onClicked: opened = false
    }

    Item {
        id: content

        anchors.centerIn: parent
        enabled: opened
        width: Math.min(840, launcherWindow.width - 32)
        height: hasQuery ? Math.min(500, launcherWindow.height - 40, 215 + Math.max(46, resultsHeight)) : 154
        opacity: opened ? 1 : 0
        scale: opened ? 1 : 0.96
        transform: Translate {
            y: launcherWindow.opened ? 0 : 12

            Behavior on y {
                NumberAnimation {
                    duration: launcherWindow.opened ? 240 : 120
                    easing.type: launcherWindow.opened ? Easing.OutQuart : Easing.InQuad
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

            Column {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                anchors.topMargin: 18
                anchors.bottomMargin: 14
                spacing: 8

                Row {
                    width: parent.width
                    height: 30
                    spacing: 10

                    Rectangle {
                        width: 30
                        height: 30
                        color: panelAccent

                        Text {
                            anchors.centerIn: parent
                            text: "󰀻"
                            color: panelBg
                            font.family: "Symbols Nerd Font Mono"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "VELLUM SHELL"
                            color: panelFg
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 3
                        }

                        Text {
                            text: "Application launcher"
                            color: mutedFg
                            font.pixelSize: 9
                        }

                    }

                }

                SharedUi.SearchField {
                    id: searchField

                    width: parent.width
                    height: 48
                    opened: launcherWindow.opened
                    indicator: calcMode ? "=" : (projectMode ? ">" : (webMode ? "?" : (emojiMode ? ":" : "⌕")))
                    placeholder: projectMode ? "Search projects in ~/Projects..." : "Search applications..."
                    inputLeftMargin: 44
                    inputVerticalPadding: 12
                    surface: inkBg
                    foreground: panelFg
                    accent: panelAccent
                    muted: mutedFg
                    onTextEdited: (text) => {
                        return query = text;
                    }
                    onKeyPressed: (event) => {
                        return handleKey(event);
                    }
                }

                Grid {
                    width: parent.width
                    height: 28
                    columns: 5
                    columnSpacing: 6

                    Repeater {
                        model: [{
                            "label": "APPS",
                            "prefix": ""
                        }, {
                            "label": "EMOJI",
                            "prefix": ":"
                        }, {
                            "label": "CALC",
                            "prefix": "="
                        }, {
                            "label": "WEB",
                            "prefix": "?"
                        }, {
                            "label": "PROJECTS",
                            "prefix": ">"
                        }]

                        Rectangle {
                            readonly property bool activeMode: modeActive(modelData.prefix)

                            width: (parent.width - 24) / 5
                            height: 27
                            color: activeMode || modeMouse.containsMouse ? inkBg : "transparent"
                            border.color: activeMode ? panelAccent : mutedFg
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: (index + 1).toString().padStart(2, "0")
                                    color: panelAccent
                                    font.family: "monospace"
                                    font.pixelSize: 8
                                }

                                Text {
                                    text: modelData.label
                                    color: activeMode ? panelFg : mutedFg
                                    font.family: "monospace"
                                    font.pixelSize: 8
                                    font.letterSpacing: 1
                                }

                            }

                            MouseArea {
                                id: modeMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selectMode(modelData.prefix)
                            }

                        }

                    }

                }

                Item {
                    visible: hasQuery
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        text: modeTitle + "  /  " + visibleItems.length
                        color: panelAccent
                        font.pixelSize: 8
                        font.letterSpacing: 2
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        text: "TAB  MODE    ↑↓  SELECT    ENTER  RUN    ESC  CLOSE"
                        color: mutedFg
                        font.family: "monospace"
                        font.pixelSize: 8
                    }

                }

                Rectangle {
                    visible: hasQuery
                    width: parent.width
                    height: 1
                    color: panelAccent
                    opacity: 0.45
                }

                Item {
                    visible: hasQuery
                    width: parent.width
                    height: parent.height - 173

                    Text {
                        visible: visibleItems.length === 0
                        anchors.centerIn: parent
                        text: projectMode ? "No projects found in ~/Projects" : "NO RESULTS"
                        color: mutedFg
                        font.pixelSize: 10
                    }

                    ListView {
                        id: resultsList

                        anchors.fill: parent
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        visible: visibleItems.length > 0
                        interactive: contentHeight > height
                        model: launcherWindow.opened ? visibleItems : []
                        spacing: 4
                        reuseItems: true
                        cacheBuffer: 92

                        delegate: LauncherUi.LauncherResultRow {
                                    width: ListView.view.width
                                    result: modelData
                                    resultIndex: index
                                    selected: index === selectedIndex
                                    hoverSelectionEnabled: !suppressHoverSelection
                                    title: itemTitle(modelData)
                                    subtitle: itemSubtitle(modelData)
                                    glyph: itemIcon(modelData)
                                    appIconSource: modelData.type === "app" ? iconResolver.resolve(modelData.app) : ""
                                    appFallbackIcon: iconResolver.fallbackIcon(modelData.app)
                                    foregroundColor: panelFg
                                    accentColor: panelAccent
                                    mutedColor: mutedFg
                                    selectionColor: inkBg
                                    onHoverRequested: (rowIndex) => {
                                        return selectedIndex = rowIndex;
                                    }
                                    onActivationRequested: (rowIndex) => {
                                        suppressHoverSelection = false;
                                        selectedIndex = rowIndex;
                                        activateSelected();
                                    }
                        }

                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: mutedFg
                        opacity: resultsList.visible && resultsList.interactive ? 0.18 : 0
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 2
                        height: resultsList.visible && resultsList.contentHeight > 0 ? Math.max(24, parent.height * resultsList.visibleArea.heightRatio) : 0
                        y: resultsList.visible ? resultsList.visibleArea.yPosition * parent.height : 0
                        color: panelAccent
                        opacity: resultsList.visible && resultsList.interactive ? 0.9 : 0

                        Behavior on y {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

            }

        }

        Behavior on height {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: launcherWindow.opened ? 160 : 110
                easing.type: launcherWindow.opened ? Easing.OutQuart : Easing.InQuad
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: launcherWindow.opened ? 260 : 130
                easing.type: launcherWindow.opened ? Easing.OutQuart : Easing.InQuad
            }

        }

    }

}

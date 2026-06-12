import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: clipboardWindow

    property var theme: null
    property bool opened: false
    property string query: ""
    property int selectedIndex: 0
    property var entries: []
    property var visibleItems: filterEntries(query)

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"
    readonly property string inkBg: "#1b1613"
    readonly property var selectedItem: visibleItems.length > 0 ? visibleItems[Math.max(0, Math.min(selectedIndex, visibleItems.length - 1))] : null

    onOpenedChanged: {
        if (opened) {
            resetClipboard()
            refreshClipboard()
            focusTimer.start()
        } else {
            resetClipboard()
        }
    }

    onQueryChanged: {
        selectedIndex = 0
        resultsFlick.contentY = 0
    }

    onVisibleItemsChanged: {
        selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(visibleItems.length - 1, 0)))
        clampResultsScroll()
    }

    function resetClipboard() {
        query = ""
        searchInput.text = ""
        selectedIndex = 0
        resultsFlick.contentY = 0
    }

    function refreshClipboard() {
        fetcher.command = ["elephant", "query", "clipboard;;256"]
        fetcher.running = true
    }

    function normalize(value) {
        return (value || "").toString().toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
    }

    function filterEntries(value) {
        var words = normalize(value).split(/\s+/).filter((word) => word !== "")
        if (words.length === 0) return entries

        var result = []
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i]
            var haystack = normalize(entry.title + " " + entry.subtitle + " " + entry.preview)
            var matched = true
            for (var j = 0; j < words.length; j++) {
                if (haystack.indexOf(words[j]) < 0) {
                    matched = false
                    break
                }
            }
            if (matched) result.push(entry)
        }
        return result
    }

    function unescapeField(value) {
        return (value || "").replace(/\\n/g, "\n").replace(/\\t/g, "\t").replace(/\\"/g, "\"").replace(/\\\\/g, "\\")
    }

    function field(block, name) {
        var match = block.match(new RegExp(name + ':"((?:\\\\.|[^"\\\\])*)"'))
        return match ? unescapeField(match[1]) : ""
    }

    function isImagePreview(path) {
        var lower = (path || "").toLowerCase()
        return lower.endsWith(".png") || lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".webp") || lower.endsWith(".gif")
    }

    function compactText(value) {
        return (value || "").replace(/\s+/g, " ").trim()
    }

    function previewSource(path) {
        if (!path) return ""
        if (path.startsWith("file:")) return path
        if (path.startsWith("/")) return "file://" + path
        return path
    }

    function parseOutput(output) {
        var lines = (output || "").split("\n")
        var parsed = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line.indexOf("item:{") < 0) continue

            var identifier = field(line, "identifier")
            var text = field(line, "text")
            var subtext = field(line, "subtext")
            var preview = field(line, "preview")
            var image = isImagePreview(preview)
            var compact = compactText(text)
            var title = compact !== "" ? compact : (image ? "Image clipboard" : "Clipboard item")

            if (identifier === "") continue
            parsed.push({
                identifier: identifier,
                title: title,
                text: text,
                subtitle: subtext,
                preview: preview,
                isImage: image
            })
        }
        entries = parsed
    }

    function activateSelected() {
        if (!selectedItem) return
        activateProcess.command = ["elephant", "activate", "clipboard;" + selectedItem.identifier + ";copy;;;"]
        activateProcess.running = true
        opened = false
    }

    function deleteSelected() {
        if (!selectedItem) return
        var removedId = selectedItem.identifier
        deleteProcess.command = ["elephant", "activate", "clipboard;" + removedId + ";remove;;;"]
        deleteProcess.running = true

        var nextEntries = []
        for (var i = 0; i < entries.length; i++) {
            if (entries[i].identifier !== removedId) nextEntries.push(entries[i])
        }
        entries = nextEntries
        selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(visibleItems.length - 1, 0)))
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
        } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            deleteSelected()
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
    WlrLayershell.namespace: "quickshell.clipboard"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? 1 : 0

    Timer {
        id: focusTimer
        interval: 80
        onTriggered: searchInput.forceActiveFocus()
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: parseOutput(this.text || "")
        }
    }

    Process {
        id: activateProcess
    }

    Process { id: deleteProcess }

    MouseArea {
        anchors.fill: parent
        onClicked: opened = false
    }

    Item {
        id: content
        anchors.centerIn: parent
        width: Math.min(860, clipboardWindow.width - 40)
        height: Math.min(480, clipboardWindow.height - 60)
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
                width: 190
                height: 190
                radius: 95
                x: parent.width - 105
                y: -95
                color: panelAccent
                opacity: 0.13
            }

            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                Row {
                    width: parent.width
                    height: 56
                    spacing: 18

                    Column {
                        id: headerTitle
                        width: Math.min(255, parent.width * 0.34)
                        spacing: 3
                        Text {
                            text: "KIRITORI"
                            color: panelAccent
                            font.pixelSize: 10
                            font.letterSpacing: 5
                            font.bold: true
                        }
                        Text {
                            text: "Clipboard"
                            color: panelFg
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "切り取り / paste memory"
                            color: mutedFg
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        width: parent.width - headerTitle.width - 18
                        height: 46
                        radius: 0
                        color: inkBg
                        border.color: searchInput.activeFocus ? panelAccent : mutedFg
                        border.width: searchInput.activeFocus ? 2 : 1
                        anchors.verticalCenter: parent.verticalCenter

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
                            focus: clipboardWindow.opened
                            onTextChanged: query = text
                            Keys.onPressed: (event) => handleKey(event)

                            Text {
                                text: "Search clipboard..."
                                color: mutedFg
                                visible: parent.text === ""
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: panelAccent
                    opacity: 0.45
                }

                Row {
                    width: parent.width
                    height: parent.height - 72
                    spacing: 16

                    Item {
                        id: listPane
                        width: Math.max(280, Math.min(500, parent.width * 0.62))
                        height: parent.height

                        Text {
                            visible: visibleItems.length === 0
                            anchors.centerIn: parent
                            text: "No clipboard matches"
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
                                        color: index === selectedIndex ? panelAccent : (resultMouse.containsMouse ? inkBg : "transparent")
                                        scale: 1

                                        Behavior on color { ColorAnimation { duration: 110 } }

                                        Rectangle {
                                            width: 3
                                            height: parent.height
                                            anchors.left: parent.left
                                            color: index === selectedIndex ? panelBg : panelAccent
                                            opacity: resultMouse.containsMouse || index === selectedIndex ? 1 : 0
                                        }

                                        Row {
                                            anchors.fill: parent
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 12
                                            spacing: 13

                                            Text {
                                                text: modelData.isImage ? "" : ""
                                                font.family: "omarchy"
                                                font.pixelSize: 18
                                                color: index === selectedIndex ? panelBg : panelFg
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Column {
                                                width: parent.width - 52
                                                spacing: 2
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    text: modelData.title
                                                    color: index === selectedIndex ? panelBg : panelFg
                                                    font.pixelSize: 14
                                                    font.weight: Font.DemiBold
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: modelData.subtitle
                                                    color: index === selectedIndex ? panelBg : mutedFg
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
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
                    }

                    Rectangle {
                        width: 1
                        height: parent.height
                        color: panelAccent
                        opacity: 0.28
                    }

                    Rectangle {
                        width: parent.width - listPane.width - 17
                        height: parent.height
                        color: inkBg
                        border.width: 0
                        radius: 0
                        clip: true

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            Text {
                                text: selectedItem && selectedItem.isImage ? "IMAGE PREVIEW" : "PREVIEW"
                                color: panelAccent
                                font.pixelSize: 10
                                font.letterSpacing: 4
                                font.bold: true
                            }

                            Rectangle {
                                width: parent.width
                                height: 248
                                color: panelBg
                                border.width: 0
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    source: selectedItem && selectedItem.isImage ? previewSource(selectedItem.preview) : ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    visible: source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - 24
                                    text: selectedItem ? (selectedItem.isImage ? "Image preview unavailable" : selectedItem.text) : "Select an item"
                                    color: mutedFg
                                    font.pixelSize: 13
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 12
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: !selectedItem || !selectedItem.isImage
                                }
                            }

                            Text {
                                text: selectedItem ? selectedItem.subtitle : ""
                                color: mutedFg
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: selectedItem && selectedItem.isImage ? selectedItem.preview : "Enter copies / Delete removes"
                                color: mutedFg
                                font.pixelSize: 11
                                wrapMode: Text.WrapAnywhere
                                width: parent.width
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}

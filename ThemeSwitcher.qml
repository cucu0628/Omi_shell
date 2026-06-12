import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: switcher

    property var theme: null
    property bool opened: false
    property string mode: "theme"
    property string query: ""
    property int selectedIndex: 0
    property var items: []
    property var themeItems: []
    property var visibleItems: filterItems(query)
    readonly property var selectedItem: visibleItems.length > 0 ? visibleItems[Math.max(0, Math.min(selectedIndex, visibleItems.length - 1))] : null

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"
    readonly property string inkBg: "#1b1613"

    onOpenedChanged: {
        if (opened) {
            resetSwitcher()
            loadMode()
            focusTimer.start()
        } else {
            resetSwitcher()
        }
    }

    onQueryChanged: {
        selectedIndex = 0
        listFlick.contentY = 0
        carouselFlick.contentX = 0
    }

    onVisibleItemsChanged: {
        selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(visibleItems.length - 1, 0)))
        clampListScroll()
    }

    function resetSwitcher() {
        query = ""
        themeSearchInput.text = ""
        stackSearchInput.text = ""
        selectedIndex = 0
        listFlick.contentY = 0
    }

    function loadMode() {
        if (mode === "theme" && themeItems.length > 0) {
            items = themeItems
            return
        }

        items = []
        if (mode === "theme") {
            loader.command = ["sh", "-c", "omarchy theme list | while IFS= read -r name; do slug=$(printf '%s' \"$name\" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'); dir=\"$HOME/.config/omarchy/themes/$slug\"; [ -d \"$dir\" ] || dir=\"$HOME/.local/share/omarchy/themes/$slug\"; printf '%s|%s|%s\\n' \"$name\" \"$dir/preview.png\" \"$dir\"; done"]
        } else {
            loader.command = ["sh", "-c", "theme=$(readlink -f \"$HOME/.config/omarchy/current/theme\"); current=$(readlink -f \"$HOME/.config/omarchy/current/background\"); find \"$theme/backgrounds\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort | while IFS= read -r path; do name=$(basename \"$path\"); marker=''; [ \"$path\" = \"$current\" ] && marker='current'; printf '%s|%s|%s\\n' \"$name\" \"$path\" \"$marker\"; done"]
        }
        loader.running = true
    }

    function parseItems(output) {
        var lines = (output || "").trim().split("\n")
        var parsed = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line.trim() === "") continue
            var parts = line.split("|")
            parsed.push({ name: parts[0] || "", preview: parts[1] || "", meta: parts[2] || "" })
        }
        items = parsed
        if (mode === "theme") themeItems = parsed
    }

    function normalize(value) {
        return (value || "").toString().toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
    }

    function filterItems(value) {
        var needle = normalize(value)
        if (needle === "") return items
        var result = []
        for (var i = 0; i < items.length; i++) {
            if (normalize(items[i].name).indexOf(needle) >= 0) result.push(items[i])
        }
        return result
    }

    function previewSource(path) {
        if (!path) return ""
        if (path.startsWith("file:")) return path
        if (path.startsWith("/")) return "file://" + path
        return path
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function activateSelected() {
        if (!selectedItem) return
        if (mode === "theme") applyProcess.command = ["sh", "-c", "omarchy theme set " + shellQuote(selectedItem.name)]
        else applyProcess.command = ["sh", "-c", "omarchy theme bg set " + shellQuote(selectedItem.preview)]
        applyProcess.running = true
        opened = false
    }

    function ensureSelectedVisible() {
        var cardStep = stackCardWidth + stackCardSpacing
        var leadingPadding = Math.max(0, (carouselFlick.width - stackCardWidth) / 2)
        var centerX = leadingPadding + selectedIndex * cardStep + stackCardWidth / 2 - carouselFlick.width / 2
        var maxX = Math.max(0, carouselFlick.contentWidth - carouselFlick.width)
        carouselFlick.contentX = Math.max(0, Math.min(centerX, maxX))
    }

    function clampListScroll() {
        var maxY = Math.max(0, listFlick.contentHeight - listFlick.height)
        listFlick.contentY = Math.max(0, Math.min(listFlick.contentY, maxY))
        var maxX = Math.max(0, carouselFlick.contentWidth - carouselFlick.width)
        carouselFlick.contentX = Math.max(0, Math.min(carouselFlick.contentX, maxX))
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
        } else if (event.key === Qt.Key_Right) {
            selectedIndex = Math.min(selectedIndex + 1, Math.max(visibleItems.length - 1, 0))
            ensureSelectedVisible()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
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

    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.theme-switcher"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? 1 : 0

    Timer { id: focusTimer; interval: 80; onTriggered: stackSearchInput.forceActiveFocus() }
    Process { id: loader; stdout: StdioCollector { onStreamFinished: parseItems(this.text || "") } }
    Process { id: applyProcess }

    readonly property real stackCardWidth: Math.max(520, Math.min(760, content.width * 0.42))
    readonly property real stackCardHeight: Math.max(292, Math.min(430, stackCardWidth * 0.56, content.height * 0.42))
    readonly property real stackCardSpacing: -Math.min(520, stackCardWidth * 0.68)

    Rectangle {
        anchors.fill: parent
        color: panelBg
        opacity: content.opacity > 0 ? 0.93 * content.opacity : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    }

    MouseArea { anchors.fill: parent; onClicked: opened = false }

    Item {
        id: content
        anchors.centerIn: parent
        width: switcher.width
        height: switcher.height
        opacity: opened ? 1 : 0
        scale: opened ? 1 : 0.98
        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "transparent"
            border.width: 0
            radius: 0
            clip: true

            Rectangle { width: 230; height: 230; radius: 115; x: parent.width - 130; y: -105; color: panelAccent; opacity: 0 }
            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14
                visible: false

                Row {
                    width: parent.width
                    height: 58
                    spacing: 18

                    Column {
                        width: 280
                        spacing: 3
                        Text { text: mode === "theme" ? "IRO" : "KABE"; color: panelAccent; font.pixelSize: 10; font.letterSpacing: 5; font.bold: true }
                        Text { text: mode === "theme" ? "Theme Director" : "Wallpaper Director"; color: panelFg; font.pixelSize: 24; font.weight: Font.DemiBold }
                        Text { text: mode === "theme" ? "色 / inspect atmosphere" : "壁 / inspect background"; color: mutedFg; font.pixelSize: 11 }
                    }

                    Rectangle {
                        width: parent.width - 298
                        height: 46
                        radius: 0
                        color: inkBg
                        border.color: themeSearchInput.activeFocus ? panelAccent : mutedFg
                        border.width: themeSearchInput.activeFocus ? 2 : 1
                        anchors.verticalCenter: parent.verticalCenter

                        Text { text: "⌕"; color: panelAccent; font.pixelSize: 18; anchors.left: parent.left; anchors.leftMargin: 13; anchors.verticalCenter: parent.verticalCenter }

                        TextInput {
                            id: themeSearchInput
                            anchors.left: parent.left
                            anchors.leftMargin: 40
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height - 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: panelFg
                            font.pixelSize: 15
                            focus: switcher.opened && mode === "theme"
                            onTextChanged: query = text
                            Keys.onPressed: (event) => handleKey(event)
                            Text { text: mode === "theme" ? "Search themes..." : "Search wallpapers..."; color: mutedFg; visible: parent.text === ""; anchors.fill: parent; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: panelAccent; opacity: 0.45 }

                Row {
                    width: parent.width
                    height: parent.height - 74
                    spacing: 18

                    Column {
                        width: 300
                        height: parent.height
                        spacing: 10

                        Text { text: visibleItems.length + " OPTIONS"; color: panelAccent; font.pixelSize: 10; font.letterSpacing: 4; font.bold: true }

                        Flickable {
                            id: listFlick
                            width: parent.width
                            height: parent.height - 24
                            contentHeight: listColumn.height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentHeight > height

                            Column {
                                id: listColumn
                                width: parent.width
                                spacing: 6

                                Repeater {
                                    model: visibleItems
                                    Rectangle {
                                        width: listColumn.width
                                        height: 48
                                        color: itemMouse.containsMouse || index === selectedIndex ? inkBg : "transparent"
                                        border.color: index === selectedIndex ? panelAccent : "transparent"
                                        border.width: index === selectedIndex ? 1 : 0
                                        radius: 0

                                        Rectangle { width: 3; height: parent.height; anchors.left: parent.left; color: panelAccent; opacity: itemMouse.containsMouse || index === selectedIndex ? 1 : 0 }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 14
                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name
                                            color: index === selectedIndex ? panelAccent : panelFg
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: mode === "wallpaper" && modelData.meta === "current" ? "CURRENT" : ""
                                            color: panelAccent
                                            font.pixelSize: 9
                                            font.bold: true
                                        }

                                        MouseArea { id: itemMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: selectedIndex = index; onClicked: { selectedIndex = index; activateSelected() } }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { width: 1; height: parent.height; color: panelAccent; opacity: 0.26 }

                    Item {
                        width: parent.width - 319
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            color: inkBg
                            border.color: panelAccent
                            border.width: 1
                            radius: 0
                            clip: true

                            Image {
                                id: heroImage
                                anchors.fill: parent
                                anchors.margins: 14
                                source: selectedItem ? previewSource(selectedItem.preview) : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                cache: true
                                sourceSize.width: width * 1.25
                                sourceSize.height: height * 1.25
                            }

                            Rectangle { anchors.fill: parent; color: panelBg; opacity: heroImage.status === Image.Ready ? 0 : 0.7 }
                            Text { anchors.centerIn: parent; text: heroImage.status === Image.Loading ? "Loading preview..." : "No preview"; color: mutedFg; font.pixelSize: 14; visible: heroImage.status !== Image.Ready }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 82
                                color: panelBg
                                opacity: 0.94
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 22
                                anchors.right: parent.right
                                anchors.rightMargin: 22
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 16
                                spacing: 4

                                Text { text: selectedItem ? selectedItem.name : "No selection"; color: panelFg; font.pixelSize: 22; font.weight: Font.DemiBold; elide: Text.ElideRight; width: parent.width }
                                Text { text: mode === "theme" ? "Enter applies theme" : "Enter applies wallpaper"; color: mutedFg; font.pixelSize: 12; width: parent.width }
                            }
                        }
                    }
                }
            }

            Item {
                anchors.fill: parent
                anchors.margins: 24
                visible: true

                Column {
                    anchors.fill: parent
                    spacing: 18

                    Column {
                        width: parent.width
                        height: 40
                        spacing: 4

                        Text {
                            width: parent.width
                            text: mode === "theme" ? "Theme stack" : "Wallpaper stack"
                            color: panelFg
                            opacity: 0.42
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.letterSpacing: 4
                            style: Text.Outline
                            styleColor: Qt.rgba(0, 0, 0, 0.85)
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: Math.min(220, parent.width * 0.18)
                            height: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: panelAccent
                            opacity: 0.55
                        }

                        Text {
                            width: parent.width
                            text: visibleItems.length + (mode === "theme" ? " themes" : " backgrounds") + (mode === "wallpaper" && selectedItem && selectedItem.meta === "current" ? " / current" : "")
                            color: panelFg
                            opacity: 0.78
                            font.pixelSize: 13
                            style: Text.Outline
                            styleColor: Qt.rgba(0, 0, 0, 0.85)
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Flickable {
                        id: carouselFlick
                        width: parent.width
                        height: stackCardHeight + 156
                        contentWidth: wallpaperRow.x + wallpaperRow.width + wallpaperRow.x
                        contentHeight: height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentWidth > width

                        Behavior on contentX { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                        Row {
                            id: wallpaperRow
                            height: parent.height
                            spacing: stackCardSpacing
                            x: Math.max(0, (carouselFlick.width - stackCardWidth) / 2)

                            Repeater {
                                model: visibleItems

                                Item {
                                    property int distanceFromSelected: Math.abs(index - selectedIndex)
                                    property int relativeIndex: index - selectedIndex
                                    property int stackOffset: Math.max(-3, Math.min(3, relativeIndex))

                                    width: stackCardWidth
                                    height: carouselFlick.height
                                    z: index === selectedIndex ? 100 : 50 - distanceFromSelected
                                    scale: index === selectedIndex ? 1 : Math.max(0.86, 0.98 - distanceFromSelected * 0.035)
                                    opacity: index === selectedIndex ? 1 : Math.max(0.42, 0.78 - distanceFromSelected * 0.12)
                                    Behavior on scale { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

                                    Rectangle {
                                        anchors.centerIn: parent
                                        anchors.horizontalCenterOffset: stackOffset * -42
                                        anchors.verticalCenterOffset: distanceFromSelected * 28
                                        width: stackCardWidth
                                        height: stackCardHeight
                                        color: inkBg
                                        border.color: "transparent"
                                        border.width: 0
                                        radius: 0
                                        clip: true

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.leftMargin: 18
                                            anchors.topMargin: 22
                                            color: "#000000"
                                            opacity: index === selectedIndex ? 0.32 : 0.18
                                            z: -1
                                        }

                                        Image {
                                            anchors.fill: parent
                                            source: previewSource(modelData.preview)
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                            asynchronous: true
                                            cache: true
                                            sourceSize.width: width * 1.15
                                            sourceSize.height: height * 1.15
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 66
                                            color: Qt.rgba(0, 0, 0, 0.74)
                                            opacity: 1
                                            visible: index === selectedIndex || wallpaperMouse.containsMouse || modelData.meta === "current"
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 18
                                            anchors.right: parent.right
                                            anchors.rightMargin: 18
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 34
                                            text: modelData.name
                                            color: "#ffffff"
                                            font.pixelSize: 16
                                            font.weight: Font.DemiBold
                                            style: Text.Outline
                                            styleColor: Qt.rgba(0, 0, 0, 0.85)
                                            elide: Text.ElideRight
                                            visible: index === selectedIndex || wallpaperMouse.containsMouse || modelData.meta === "current"
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 18
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 13
                                            text: mode === "wallpaper" && modelData.meta === "current" ? "CURRENT" : "ENTER APPLIES"
                                            color: panelAccent
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.letterSpacing: 2
                                            visible: index === selectedIndex || wallpaperMouse.containsMouse || modelData.meta === "current"
                                        }

                                        MouseArea {
                                            id: wallpaperMouse
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

                        Text {
                            anchors.centerIn: parent
                            text: loader.running ? (mode === "theme" ? "Loading themes..." : "Loading wallpapers...") : (mode === "theme" ? "No themes found" : "No wallpapers found")
                            color: mutedFg
                            font.pixelSize: 18
                            visible: visibleItems.length === 0
                        }
                    }

                    Item { width: 1; height: Math.max(0, parent.height - 40 - carouselFlick.height - searchBox.height - 42) }

                    Rectangle {
                        id: searchBox
                        width: Math.min(460, parent.width * 0.34)
                        height: 42
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 0
                        color: "transparent"

                        Text { text: "⌕"; color: panelAccent; font.pixelSize: 17; anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: stackSearchInput.activeFocus ? 2 : 1
                            color: stackSearchInput.activeFocus ? panelAccent : Qt.rgba(1, 1, 1, 0.62)
                        }

                        TextInput {
                            id: stackSearchInput
                            anchors.left: parent.left
                            anchors.leftMargin: 34
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height - 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: panelFg
                            font.pixelSize: 13
                            focus: switcher.opened
                            onTextChanged: query = text
                            Keys.onPressed: (event) => handleKey(event)
                            Text { text: mode === "theme" ? "Search themes..." : "Search wallpapers..."; color: panelFg; opacity: 0.72; visible: parent.text === ""; anchors.fill: parent; verticalAlignment: Text.AlignVCenter }
                        }
                    }

                    Item { width: 1; height: 1 }
                }
            }
        }
    }
}

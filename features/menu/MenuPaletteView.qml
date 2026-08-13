import "../../ui" as SharedUi
import QtQuick

Item {
    id: root

    property var host: null
    readonly property color bg: host ? host.panelBg : "#15110f"
    readonly property color fg: host ? host.panelFg : "#f1e7d0"
    readonly property color accent: host ? host.panelAccent : "#d7472f"
    readonly property color muted: host ? host.mutedFg : "#9f8f7c"
    readonly property color surface: host ? host.inkBg : "#1b1613"
    readonly property bool readonlyResults: host !== null && host.visibleItems.length > 0 && host.visibleItems[0].readonly === true

    function connectView() {
        if (!host)
            return ;

        host.activeSearchInput = searchInput;
        host.activeResultsFlick = resultsFlick;
        host.activeCategoryFlick = null;
        searchInput.text = host.searchQuery;
        if (host.opened)
            searchInput.forceActiveFocus();

    }

    onHostChanged: connectView()
    Component.onCompleted: connectView()

    Rectangle {
        anchors.fill: parent
        color: root.bg

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
                    color: root.accent

                    Text {
                        anchors.centerIn: parent
                        text: "󰍉"
                        color: root.bg
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                }

                Column {
                    width: parent.width - 150
                    spacing: 1

                    Text {
                        text: "VELLUM SHELL"
                        color: root.fg
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 3
                    }

                    Text {
                        text: root.host && root.host.activeCategory !== "" ? root.host.activeCategory : "Command palette"
                        color: root.muted
                        font.pixelSize: 9
                    }

                }

                Rectangle {
                    width: 100
                    height: 28
                    visible: root.host && root.host.activeCategory !== "" && root.host.searchQuery === ""
                    color: backMouse.containsMouse ? root.surface : "transparent"
                    border.color: root.muted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "←  BACK"
                        color: backMouse.containsMouse ? root.fg : root.muted
                        font.pixelSize: 9
                    }

                    MouseArea {
                        id: backMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.host.goBack()
                    }

                }

            }

            SharedUi.SearchField {
                id: searchInput

                width: parent.width
                height: 48
                opened: root.host ? root.host.opened : false
                indicator: "⌕"
                placeholder: "Search commands..."
                inputLeftMargin: 44
                inputVerticalPadding: 12
                foreground: root.fg
                accent: root.accent
                muted: root.muted
                surface: root.surface
                onTextEdited: (text) => {
                    if (root.host)
                        root.host.searchQuery = text;

                }
                onKeyPressed: (event) => {
                    if (root.host)
                        root.host.handleKey(event);

                }
            }

            Grid {
                width: parent.width
                height: 58
                columns: 5
                columnSpacing: 6
                rowSpacing: 4

                Repeater {
                    model: root.host ? root.host.menuData : []

                    Rectangle {
                        width: (parent.width - 24) / 5
                        height: 27
                        color: root.host.activeCategory === modelData.name || categoryMouse.containsMouse ? root.surface : "transparent"
                        border.color: root.host.activeCategory === modelData.name ? root.accent : root.muted
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                text: (index + 1).toString().padStart(2, "0")
                                color: root.accent
                                font.family: "monospace"
                                font.pixelSize: 8
                            }

                            Text {
                                text: modelData.name.toUpperCase()
                                color: root.host.activeCategory === modelData.name ? root.fg : root.muted
                                font.family: "monospace"
                                font.pixelSize: 8
                                font.letterSpacing: 1
                            }

                        }

                        MouseArea {
                            id: categoryMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.host.openItem(modelData)
                        }

                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.muted
                opacity: 0.35
            }

            Item {
                width: parent.width
                height: parent.height - 187

                Text {
                    anchors.centerIn: parent
                    visible: root.host && root.host.isLoading
                    text: "LOADING..."
                    color: root.accent
                    font.pixelSize: 10
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.host && !root.host.isLoading && root.host.visibleItems.length === 0
                    text: root.host.searchQuery !== "" ? "NO RESULTS" : "EMPTY"
                    color: root.muted
                    font.pixelSize: 10
                }

                Flickable {
                    id: resultsFlick

                    function ensureIndexVisible(index) {
                        var item = resultsRepeater.itemAt(index)
                        if (!item) return

                        var top = item.y
                        var bottom = top + item.height
                        var maxY = Math.max(0, contentHeight - height)
                        if (top < contentY)
                            contentY = Math.max(0, Math.min(top, maxY))
                        else if (bottom > contentY + height)
                            contentY = Math.max(0, Math.min(bottom - height, maxY))
                    }

                    anchors.fill: parent
                    contentHeight: resultsColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height
                    visible: root.host && !root.host.isLoading && root.host.visibleItems.length > 0

                    Column {
                        id: resultsColumn

                        width: parent.width
                        spacing: 4

                        Repeater {
                            id: resultsRepeater

                            model: root.host ? root.host.visibleItems : []

                            Rectangle {
                                width: resultsColumn.width
                                height: 42
                                color: index === root.host.selectedIndex || resultMouse.containsMouse ? root.surface : "transparent"

                                Rectangle {
                                    width: 3
                                    height: parent.height
                                    color: root.accent
                                    opacity: index === root.host.selectedIndex ? 1 : 0
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 11

                                    Text {
                                        width: 24
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (index + 1).toString().padStart(2, "0")
                                        color: root.muted
                                        font.family: "monospace"
                                        font.pixelSize: 8
                                    }

                                    Text {
                                        width: 24
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.icon || "・"
                                        color: index === root.host.selectedIndex ? root.accent : root.muted
                                        font.family: "Symbols Nerd Font Mono"
                                        font.pixelSize: 14
                                    }

                                    Column {
                                        width: parent.width - (modelData.readonly ? 82 : 166)
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            text: modelData.name
                                            color: root.fg
                                            font.family: "monospace"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.readonly ? (modelData.path || "") : ""
                                            visible: text !== ""
                                            color: root.muted
                                            font.family: "monospace"
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        width: modelData.readonly ? 0 : 84
                                        visible: !modelData.readonly
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: root.host.confirmCommand !== "" && root.host.confirmCommand === modelData.command ? "CONFIRM  ↵" : (index === root.host.selectedIndex ? "ENTER  ↵" : (modelData.sub ? "OPEN  →" : "RUN  ↗"))
                                        color: index === root.host.selectedIndex ? root.accent : root.muted
                                        font.family: "monospace"
                                        font.pixelSize: 8
                                    }

                                }

                                MouseArea {
                                    id: resultMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: modelData.readonly ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    onEntered: {
                                        if (!root.host.suppressHoverSelection) root.host.selectedIndex = index
                                    }
                                    onPositionChanged: {
                                        root.host.suppressHoverSelection = false
                                        root.host.selectedIndex = index
                                    }
                                    onClicked: {
                                        root.host.suppressHoverSelection = false
                                        root.host.selectedIndex = index
                                        root.host.openItem(modelData)
                                    }
                                }

                            }

                        }

                    }

                }

            }

            Row {
                width: parent.width
                height: 10
                spacing: 20

                Text {
                    text: "↑↓  SELECT"
                    color: root.muted
                    font.family: "monospace"
                    font.pixelSize: 8
                }

                Text {
                    text: root.readonlyResults ? "TYPE  FILTER" : "ENTER  RUN"
                    color: root.muted
                    font.family: "monospace"
                    font.pixelSize: 8
                }

                Text {
                    text: "←  BACK"
                    color: root.muted
                    font.family: "monospace"
                    font.pixelSize: 8
                }

                Text {
                    text: "ESC  CLOSE"
                    color: root.muted
                    font.family: "monospace"
                    font.pixelSize: 8
                }

            }

        }

    }

}

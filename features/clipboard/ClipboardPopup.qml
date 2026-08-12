import "." as ClipboardUi
import "../../ui" as SharedUi
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: clipboardWindow

    required property var clipboardController
    property var theme: null
    property bool opened: false
    property string query: ""
    property int selectedIndex: 0
    property bool suppressHoverSelection: false
    readonly property color panelBg: theme ? theme.background : "#15110f"
    readonly property color panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property color panelAccent: theme ? theme.accent : "#d7472f"
    readonly property color mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property color inkBg: theme && theme.surface ? theme.surface : "#1b1613"
    readonly property var visibleItems: filterEntries(query)
    readonly property var selectedItem: visibleItems.length > 0 ? visibleItems[Math.max(0, Math.min(selectedIndex, visibleItems.length - 1))] : null

    function resetClipboard() {
        suppressHoverSelection = false;
        query = "";
        searchInput.text = "";
        selectedIndex = 0;
        resultsList.contentY = 0;
    }

    function refreshClipboard() {
        clipboardController.refreshClipboard();
    }

    function filterEntries(value) {
        return clipboardController.filterEntries(value);
    }

    function activateSelected() {
        if (!selectedItem)
            return ;

        clipboardController.activate(selectedItem);
        opened = false;
    }

    function deleteSelected() {
        if (!selectedItem)
            return ;

        clipboardController.remove(selectedItem);
        selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(visibleItems.length - 1, 0)));
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
        if (event.key === Qt.Key_Escape) {
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
        } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            deleteSelected();
            event.accepted = true;
        }
    }

    onOpenedChanged: {
        if (opened) {
            resetClipboard();
            refreshClipboard();
            focusTimer.start();
        } else {
            resetClipboard();
        }
    }
    onQueryChanged: {
        suppressHoverSelection = false;
        selectedIndex = 0;
        resultsList.contentY = 0;
    }
    onVisibleItemsChanged: {
        selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(visibleItems.length - 1, 0)));
        clampResultsScroll();
    }
    visible: opened || content.opacity > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.clipboard"
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
        onTriggered: searchInput.forceInputFocus()
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
        width: Math.min(840, clipboardWindow.width - 32)
        height: Math.min(500, clipboardWindow.height - 40)
        opacity: opened ? 1 : 0
        scale: opened ? 1 : 0.96
        transform: Translate {
            y: clipboardWindow.opened ? 0 : 12

            Behavior on y {
                NumberAnimation {
                    duration: clipboardWindow.opened ? 240 : 120
                    easing.type: clipboardWindow.opened ? Easing.OutQuart : Easing.InQuad
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
                anchors.margins: 22
                spacing: 8

                Row {
                    width: parent.width
                    height: 36
                    spacing: 10

                    Rectangle {
                        width: 36
                        height: 36
                        color: panelAccent

                        Text {
                            anchors.centerIn: parent
                            text: "貼"
                            color: panelBg
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                    }

                    Column {
                        width: parent.width - 166
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "CLIPBOARD"
                            color: panelFg
                            font.pixelSize: 12
                            font.letterSpacing: 3
                            font.bold: true
                        }

                        Text {
                            text: "貼り付け履歴  /  paste memory"
                            color: mutedFg
                            font.pixelSize: 9
                        }

                    }

                    Text {
                        width: 110
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: "DEL  REMOVE    ENTER  PASTE"
                        color: mutedFg
                        font.family: "monospace"
                        font.pixelSize: 8
                    }

                }

                SharedUi.SearchField {
                    id: searchInput

                    width: parent.width
                    height: 48
                    foreground: clipboardWindow.panelFg
                    accent: clipboardWindow.panelAccent
                    muted: clipboardWindow.mutedFg
                    surface: clipboardWindow.inkBg
                    opened: clipboardWindow.opened
                    placeholder: "履歴を検索 / search clipboard..."
                    inputLeftMargin: 44
                    inputVerticalPadding: 12
                    onTextEdited: (text) => {
                        return clipboardWindow.query = text;
                    }
                    onKeyPressed: (event) => {
                        return clipboardWindow.handleKey(event);
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: mutedFg
                    opacity: 0.35
                }

                Row {
                    width: parent.width
                    height: parent.height - 109
                    spacing: 0

                    Item {
                        id: listPane

                        width: parent.width
                        height: parent.height

                        Text {
                            visible: visibleItems.length === 0
                            anchors.centerIn: parent
                            text: "結果なし / NO CLIPBOARD MATCHES"
                            color: mutedFg
                            font.pixelSize: 10
                        }

                        ListView {
                            id: resultsList

                            anchors.fill: parent
                            model: clipboardWindow.opened ? visibleItems : []
                            spacing: 4
                            reuseItems: true
                            cacheBuffer: 96
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            visible: visibleItems.length > 0
                            interactive: contentHeight > height

                            delegate: ClipboardUi.ClipboardResultRow {
                                width: resultsList.width
                                entry: modelData
                                controller: clipboardController
                                resultIndex: index
                                selected: index === selectedIndex
                                panelBg: clipboardWindow.panelBg
                                panelFg: clipboardWindow.panelFg
                                panelAccent: clipboardWindow.panelAccent
                                mutedFg: clipboardWindow.mutedFg
                                inkBg: clipboardWindow.inkBg
                                onHovered: (rowIndex) => {
                                    if (!suppressHoverSelection)
                                        selectedIndex = rowIndex;

                                }
                                onActivated: (rowIndex) => {
                                    suppressHoverSelection = false;
                                    selectedIndex = rowIndex;
                                    activateSelected();
                                }
                            }

                        }

                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: clipboardWindow.opened ? 160 : 110
                easing.type: clipboardWindow.opened ? Easing.OutQuart : Easing.InQuad
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: clipboardWindow.opened ? 260 : 130
                easing.type: clipboardWindow.opened ? Easing.OutQuart : Easing.InQuad
            }

        }

    }

}

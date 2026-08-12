import QtQuick

Item {
    id: center

    property var theme: null
    property bool opened: false
    property bool dnd: false
    property var history: []
    readonly property bool transitionActive: opened || menuContent.opacity > 0
    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#1b1613"
    readonly property int visibleNotificationCount: 6
    readonly property int notificationRowHeight: 62
    readonly property int notificationGap: 6
    readonly property int notificationViewportHeight: visibleNotificationCount * notificationRowHeight
        + (visibleNotificationCount - 1) * notificationGap

    signal closeRequested()
    signal dndToggleRequested()
    signal clearRequested()
    signal itemDeleteRequested(int entryId)
    signal itemActivated(int entryId)
    signal itemActionRequested(int entryId, var action)

    visible: transitionActive

    MouseArea {
        anchors.fill: parent
        enabled: center.opened
        onClicked: center.closeRequested()
    }

    Item {
        id: menuContent

        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 32
        width: Math.min(380, parent.width - 20)
        height: center.opened ? Math.min(parent.height - 46, menuPanelColumn.implicitHeight + 32) : 0
        opacity: center.opened ? 1 : 0
        enabled: center.opened
        clip: true

        Rectangle {
            anchors.fill: parent
            color: center.panelBg
            border.color: center.panelAccent
            border.width: 1
            clip: true

            MouseArea {
                anchors.fill: parent
                enabled: center.opened
                onClicked: (mouse) => {
                    return mouse.accepted = true;
                }
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentWidth: width
                contentHeight: menuPanelColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: false

                Column {
                    id: menuPanelColumn

                    width: parent.width
                    spacing: 10

                    Row {
                        width: parent.width
                        height: 36
                        spacing: 10

                        Rectangle {
                            width: 36
                            height: 36
                            color: center.panelAccent

                            Text {
                                anchors.centerIn: parent
                                text: "知"
                                color: center.panelBg
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                            }

                        }

                        Column {
                            width: parent.width - 136
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: "NOTIFICATIONS"
                                color: center.panelFg
                                font.pixelSize: 12
                                font.letterSpacing: 3
                                font.bold: true
                            }

                            Text {
                                text: "通知センター  /  komorebi notices"
                                color: center.mutedFg
                                font.pixelSize: 9
                            }

                        }

                        Rectangle {
                            width: 80
                            height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            color: center.dnd ? center.panelAccent : center.inkBg
                            border.color: center.panelAccent
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: center.dnd ? "DND ON" : "DND"
                                color: center.dnd ? center.panelBg : center.panelAccent
                                font.family: "monospace"
                                font.pixelSize: 8
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: center.dndToggleRequested()
                            }

                        }

                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: center.mutedFg
                        opacity: 0.35
                    }

                    Row {
                        width: parent.width
                        height: 18
                        spacing: 8

                        Text {
                            width: parent.width - 64
                            text: "RECENT  /  " + center.history.length
                            color: center.panelAccent
                            font.family: "monospace"
                            font.pixelSize: 8
                            font.letterSpacing: 2
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            width: 56
                            height: parent.height
                            text: center.history.length > 0 ? "CLEAR" : ""
                            color: center.mutedFg
                            font.family: "monospace"
                            font.pixelSize: 9
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter

                            MouseArea {
                                anchors.fill: parent
                                enabled: center.history.length > 0
                                cursorShape: Qt.PointingHandCursor
                                onClicked: center.clearRequested()
                            }

                        }

                    }

                    Rectangle {
                        width: parent.width
                        height: center.history.length === 0 ? 52 : 0
                        visible: center.history.length === 0
                        color: "transparent"
                        border.color: "transparent"
                        border.width: 0

                        Row {
                            anchors.centerIn: parent
                            spacing: 9

                            Text {
                                text: "静"
                                color: center.panelAccent
                                opacity: 0.55
                                font.pixelSize: 17
                            }

                            Text {
                                text: "All quiet"
                                color: center.mutedFg
                                font.pixelSize: 11
                            }

                        }

                    }

                    Item {
                        width: parent.width
                        height: Math.min(historyList.contentHeight, center.notificationViewportHeight)
                        visible: center.history.length > 0

                        ListView {
                            id: historyList

                            anchors.fill: parent
                            anchors.rightMargin: interactive ? 6 : 0
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentHeight > height
                            model: center.opened ? center.history : []
                            spacing: center.notificationGap
                            reuseItems: true
                            cacheBuffer: center.notificationRowHeight

                            delegate: Rectangle {
                                id: historyEntry

                                required property var modelData
                                property var entry: modelData
                                width: ListView.view.width
                                height: center.notificationRowHeight + (actionFlow.visible ? actionFlow.implicitHeight + 8 : 0)
                                color: itemMouse.containsMouse ? center.inkBg : "transparent"
                                border.color: modelData.critical ? center.panelAccent : "transparent"
                                border.width: 1

                                Rectangle {
                                    width: 3
                                    height: parent.height
                                    color: center.panelAccent
                                    opacity: modelData.critical || itemMouse.containsMouse ? 1 : 0
                                }

                                MouseArea {
                                    id: itemMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: modelData.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: center.itemActivated(modelData.id)
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 9
                                    anchors.leftMargin: 11
                                    anchors.bottomMargin: actionFlow.visible ? actionFlow.implicitHeight + 9 : 9
                                    spacing: 9

                                    Rectangle {
                                        width: 36
                                        height: 36
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: center.inkBg
                                        border.color: center.mutedFg
                                        border.width: 1
                                        clip: true

                                        Image {
                                            id: historyImage

                                            anchors.fill: parent
                                            anchors.margins: 6
                                            source: modelData.icon
                                            sourceSize: Qt.size(72, 72)
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            cache: false
                                            smooth: true
                                            visible: source !== ""
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.critical ? "󰀦" : "󰂚"
                                            color: center.panelAccent
                                            font.pixelSize: 13
                                            visible: historyImage.source === ""
                                        }

                                    }

                                    Column {
                                        width: parent.width - 82
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Row {
                                            width: parent.width

                                            Text {
                                                width: parent.width - 42
                                                text: modelData.appName.toUpperCase()
                                                color: center.panelAccent
                                                font.pixelSize: 7
                                                font.bold: true
                                                font.letterSpacing: 2
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: 42
                                                text: modelData.time
                                                color: center.mutedFg
                                                font.pixelSize: 8
                                                horizontalAlignment: Text.AlignRight
                                            }

                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.summary || "Notification"
                                            color: center.panelFg
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.body
                                            color: center.mutedFg
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                            visible: text !== ""
                                        }

                                    }

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: deleteMouse.containsMouse ? center.panelAccent : "transparent"
                                        border.color: deleteMouse.containsMouse ? center.panelAccent : center.mutedFg
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            color: deleteMouse.containsMouse ? center.panelBg : center.mutedFg
                                            font.pixelSize: 12
                                        }

                                        MouseArea {
                                            id: deleteMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: center.itemDeleteRequested(modelData.id)
                                        }

                                    }

                                }

                                Flow {
                                    id: actionFlow

                                    anchors.left: parent.left
                                    anchors.leftMargin: 56
                                    anchors.right: parent.right
                                    anchors.rightMargin: 9
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 7
                                    spacing: 5
                                    visible: historyEntry.entry.actions && historyEntry.entry.actions.length > 0

                                    Repeater {
                                        model: historyEntry.entry.actions || []

                                        Rectangle {
                                            property var action: modelData

                                            width: Math.min(130, Math.max(54, historyActionText.implicitWidth + 16))
                                            height: 21
                                            color: historyActionMouse.containsMouse ? center.panelAccent : center.inkBg
                                            border.color: center.panelAccent
                                            border.width: 1

                                            Text {
                                                id: historyActionText

                                                anchors.centerIn: parent
                                                width: parent.width - 10
                                                text: parent.action && parent.action.text !== "" ? parent.action.text.toUpperCase() : (parent.action && parent.action.identifier === "default" ? "OPEN" : "ACTION")
                                                color: historyActionMouse.containsMouse ? center.panelBg : center.panelAccent
                                                font.pixelSize: 8
                                                font.bold: true
                                                elide: Text.ElideRight
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                id: historyActionMouse

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: mouse => {
                                                    mouse.accepted = true
                                                    center.itemActionRequested(historyEntry.entry.id, parent.action)
                                                }
                                            }
                                        }
                                    }
                                }

                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        width: 2
                        color: center.mutedFg
                        opacity: historyList.interactive ? 0.18 : 0
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 2
                        height: historyList.contentHeight > 0
                            ? Math.max(24, parent.height * historyList.visibleArea.heightRatio)
                            : 0
                        y: historyList.visibleArea.yPosition * parent.height
                        color: center.panelAccent
                        opacity: historyList.interactive ? 0.9 : 0
                    }

                }

                }

            }

        }

        }

        Behavior on height {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }

        }

    }

}

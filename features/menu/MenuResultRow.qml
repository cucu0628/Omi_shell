import QtQuick

Rectangle {
    id: row

    property var itemData: null
    property bool selected: false
    property string displayPath: ""
    property color foreground: "#f1e7d0"
    property color accent: "#d7472f"
    property color muted: "#9f8f7c"
    property color surface: "#1b1613"
    signal hovered()
    signal activated()

    height: 58
    radius: 0
    color: resultMouse.containsMouse || selected ? surface : "transparent"
    border.color: selected ? accent : "transparent"
    border.width: selected ? 1 : 0
    scale: 1

    Behavior on color { ColorAnimation { duration: 110 } }
    Behavior on border.width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

    Rectangle {
        width: 3
        height: parent.height
        anchors.left: parent.left
        color: row.accent
        opacity: resultMouse.containsMouse || row.selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        spacing: 13

        Text {
            text: row.itemData ? row.itemData.icon || "•" : "•"
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 19
            color: row.selected ? row.accent : row.foreground
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            width: parent.width - 75
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: row.itemData ? row.itemData.name : ""
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: row.selected ? row.accent : row.foreground
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: row.displayPath
                font.pixelSize: 11
                color: row.muted
                opacity: row.selected ? 0.9 : 1
                elide: Text.ElideRight
                width: parent.width
            }
        }

        Text {
            text: row.itemData && row.itemData.sub ? "›" : ""
            font.pixelSize: 22
            color: row.accent
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: resultMouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.hovered()
        onClicked: row.activated()
    }
}

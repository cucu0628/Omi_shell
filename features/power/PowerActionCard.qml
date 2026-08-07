import QtQuick

Rectangle {
    id: row

    property var theme: null
    property var actionData: null
    property int actionIndex: -1
    property bool selected: false
    property bool confirming: false
    readonly property string foreground: theme ? theme.foreground : "#f1e7d0"
    readonly property string accent: theme ? theme.accent : "#d7472f"
    readonly property string muted: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string surface: theme && theme.surface ? theme.surface : "#1b1613"

    signal hovered()
    signal activated()

    color: selected || actionMouse.containsMouse ? surface : "transparent"
    border.color: confirming ? accent : (selected ? muted : "transparent")
    border.width: selected || confirming ? 1 : 0

    Rectangle {
        anchors.left: parent.left
        width: 3
        height: parent.height
        color: row.accent
        opacity: row.selected ? 1 : 0
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 13
        anchors.rightMargin: 12
        spacing: 11

        Text {
            width: 20
            anchors.verticalCenter: parent.verticalCenter
            text: "0" + (row.actionIndex + 1)
            color: row.selected ? row.accent : row.muted
            font.family: "monospace"
            font.pixelSize: 8
        }

        Text {
            width: 24
            anchors.verticalCenter: parent.verticalCenter
            text: row.actionData ? row.actionData.icon : ""
            color: row.selected ? row.accent : row.muted
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 15
        }

        Column {
            width: parent.width - 120
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: row.actionData ? row.actionData.name : ""
                color: row.foreground
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: row.actionData ? row.actionData.label : ""
                color: row.muted
                font.family: "monospace"
                font.pixelSize: 8
                elide: Text.ElideRight
            }

        }

        Text {
            width: 43
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: row.confirming ? "CONFIRM" : (row.selected ? "ENTER ↵" : "→")
            color: row.confirming || row.selected ? row.accent : row.muted
            font.family: "monospace"
            font.pixelSize: 8
        }

    }

    MouseArea {
        id: actionMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.hovered()
        onClicked: row.activated()
    }

}

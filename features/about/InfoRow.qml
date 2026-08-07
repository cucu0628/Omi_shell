import QtQuick

Rectangle {
    id: row

    property var theme: null
    property var entry: null

    readonly property string background: theme ? theme.background : "#11130f"
    readonly property string foreground: theme ? theme.foreground : "#e8ddc7"
    readonly property string accent: theme ? theme.accent : "#b7372f"
    readonly property string muted: theme && theme.muted ? theme.muted : "#958b7a"

    height: 32
    radius: 0
    color: background
    border.color: Qt.rgba(1, 1, 1, 0.06)
    border.width: 1

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: row.accent
        opacity: 0.5
    }

    Text {
        id: rowIcon
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        text: row.entry ? row.entry.icon : ""
        color: row.accent
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
    }

    Column {
        anchors.left: rowIcon.right
        anchors.leftMargin: 9
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: row.entry ? row.entry.label.toUpperCase() : ""
            color: row.muted
            font.pixelSize: 8
            font.letterSpacing: 1.4
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: row.entry ? row.entry.value : ""
            color: row.foreground
            font.pixelSize: 11
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }
}

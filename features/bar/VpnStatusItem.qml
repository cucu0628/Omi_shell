import QtQuick

Item {
    id: root
    required property var theme
    required property int barHeight
    property bool active: false
    property string vpnName: ""
    signal clicked()

    width: mouse.containsMouse && active ? Math.min(115, 26 + label.implicitWidth) : 22
    height: parent.height
    anchors.verticalCenter: parent.verticalCenter
    clip: true
    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: root.theme.accent
        opacity: mouse.containsMouse || root.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        Item {
            width: 22
            height: root.barHeight
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                text: root.active ? "󰦝" : "󰦜"
                color: mouse.containsMouse || root.active ? root.theme.accent : root.theme.foreground
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 24
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
        Text {
            id: label
            text: root.vpnName
            color: root.theme.accent
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
            opacity: mouse.containsMouse && root.active ? 1 : 0
            elide: Text.ElideRight
            width: Math.min(86, implicitWidth)
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

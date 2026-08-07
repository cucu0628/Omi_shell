import QtQuick

Item {
    id: root
    required property var theme
    property string connectionType: "offline"
    property bool popupOpen: false
    signal clicked()

    width: 22
    height: parent.height

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -2
        text: root.connectionType === "ethernet" ? "󰈀" : (root.connectionType === "wifi" ? "󰤨" : "󰤭")
        color: mouse.containsMouse || root.popupOpen ? root.theme.accent : root.theme.foreground
        font.family: "Symbols Nerd Font Mono"
        font.pixelSize: 24
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: root.theme.accent
        opacity: mouse.containsMouse || root.popupOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

import QtQuick

Rectangle {
    property var controller: null
    property string message: ""

    color: controller ? controller.inkBg : "#1b1613"
    border.color: controller ? controller.lineBg : Qt.rgba(1, 1, 1, 0.055)
    border.width: 1
    radius: 0

    Text {
        anchors.centerIn: parent
        text: parent.message
        color: controller ? controller.mutedFg : "#9f8f7c"
        font.pixelSize: 12
    }
}

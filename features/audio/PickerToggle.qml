import QtQuick

Rectangle {
    property var controller: null
    property string title: ""
    property int count: 0
    property bool expanded: false

    signal clicked()

    color: pickerMouse.containsMouse || expanded ? (controller ? controller.hoverBg : Qt.rgba(1, 1, 1, 0.075)) : "transparent"
    border.color: controller ? controller.mutedFg : "#9f8f7c"
    border.width: 1
    radius: 0

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            width: 18
            height: parent.height
            text: expanded ? "▴" : "▾"
            color: controller ? controller.panelAccent : "#d7472f"
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width - 80
            height: parent.height
            text: title
            color: controller ? controller.panelFg : "#f1e7d0"
            opacity: 0.8
            font.pixelSize: 11
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Text {
            width: 42
            height: parent.height
            text: count.toString()
            color: controller ? controller.mutedFg : "#9f8f7c"
            font.family: "monospace"
            font.pixelSize: 10
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
        }

    }

    MouseArea {
        id: pickerMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: parent.clicked()
    }

}

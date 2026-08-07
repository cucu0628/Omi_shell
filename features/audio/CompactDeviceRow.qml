import QtQuick

Rectangle {
    property var controller: null
    property var node: null
    property bool input: false

    height: 36
    color: compactMouse.containsMouse ? (controller ? controller.inkBg : "#1b1613") : "transparent"
    border.color: "transparent"
    border.width: 0
    radius: 0

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 10

        Text {
            width: 22
            height: parent.height
            text: input ? "󰍬" : ""
            font.family: "Symbols Nerd Font Mono"
            color: controller ? controller.panelAccent : "#d7472f"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width - 94
            height: parent.height
            text: controller ? controller.nodeTitle(node) : ""
            color: controller ? controller.panelFg : "#f1e7d0"
            font.pixelSize: 11
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Rectangle {
            width: 50
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            border.color: controller ? controller.panelAccent : "#d7472f"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "USE"
                color: controller ? controller.panelAccent : "#d7472f"
                font.family: "monospace"
                font.pixelSize: 10
                font.bold: true
            }

        }

    }

    MouseArea {
        id: compactMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!controller)
                return ;

            if (input)
                controller.setDefaultInput(node);
            else
                controller.setDefaultOutput(node);
        }
    }

}

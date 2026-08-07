import "." as AudioUi
import QtQuick

Rectangle {
    id: streamRow

    property var controller: null
    property var node: null
    property bool input: false
    readonly property real nameWidth: input ? Math.max(90, width - 114) : Math.min(190, Math.max(130, width * 0.36))
    readonly property real barWidth: input ? 0 : Math.max(80, width - nameWidth - 114)

    height: 48
    color: streamHover.containsMouse ? (controller ? controller.inkBg : "#1b1613") : "transparent"
    border.color: "transparent"
    border.width: 0
    radius: 0

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: controller ? controller.panelAccent : "#d7472f"
        opacity: streamHover.containsMouse ? 1 : 0
    }

    Row {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 10

        Text {
            width: 24
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: input ? (node && node.audio && node.audio.muted ? "󰍭" : "󰍬") : (node && node.audio && node.audio.muted ? "" : "")
            font.family: "Symbols Nerd Font Mono"
            color: node && node.audio && node.audio.muted ? (controller ? controller.mutedFg : "#9f8f7c") : (controller ? controller.panelAccent : "#d7472f")
            font.pixelSize: 14

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (controller) {
                        controller.toggleMute(node);
                    }
                }
            }

        }

        Column {
            width: streamRow.nameWidth
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: controller ? controller.nodeTitle(node) : ""
                color: controller ? controller.panelFg : "#f1e7d0"
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: controller ? controller.nodeSubtitle(node) : ""
                color: controller ? controller.mutedFg : "#9f8f7c"
                font.pixelSize: 10
                elide: Text.ElideRight
                visible: !input
            }

        }

        AudioUi.VolumeBar {
            width: streamRow.barWidth
            visible: !input
            controller: streamRow.controller
            node: streamRow.node
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            width: 42
            anchors.verticalCenter: parent.verticalCenter
            text: (controller ? controller.percent(node) : 0) + "%"
            color: controller ? controller.panelFg : "#f1e7d0"
            font.family: "monospace"
            font.pixelSize: 11
            horizontalAlignment: Text.AlignRight
        }

    }

    MouseArea {
        id: streamHover

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onWheel: (wheel) => {
            if (controller)
                controller.wheelVolume(node, wheel);

        }
    }

}

import "." as AudioUi
import QtQuick

Rectangle {
    id: deviceCard

    property var controller: null
    property var node: null
    property bool input: false
    property bool active: false
    readonly property real nameWidth: Math.min(170, Math.max(118, width * 0.31))
    readonly property real barWidth: Math.max(64, width - nameWidth - 182)

    height: 64
    color: hover.containsMouse || active ? (controller ? controller.inkBg : "#1b1613") : "transparent"
    border.color: active ? (controller ? controller.panelAccent : "#d7472f") : "transparent"
    border.width: 1
    radius: 0

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: controller ? controller.panelAccent : "#d7472f"
        opacity: active ? 1 : 0
    }

    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Text {
            width: 24
            height: parent.height
            text: input ? (node && node.audio && node.audio.muted ? "󰍭" : "󰍬") : (node && node.audio && node.audio.muted ? "" : "")
            color: node && node.audio && node.audio.muted ? (controller ? controller.mutedFg : "#9f8f7c") : (controller ? controller.panelAccent : "#d7472f")
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 15
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

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
            width: deviceCard.nameWidth
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

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
                text: active ? (input ? "default input" : "default output") : (controller ? controller.nodeSubtitle(node) : "")
                color: controller ? controller.mutedFg : "#9f8f7c"
                font.pixelSize: 10
                elide: Text.ElideRight
            }

        }

        AudioUi.VolumeBar {
            width: deviceCard.barWidth
            controller: deviceCard.controller
            node: deviceCard.node
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            width: 42
            text: (controller ? controller.percent(node) : 0) + "%"
            color: controller ? controller.panelFg : "#f1e7d0"
            font.family: "monospace"
            font.pixelSize: 11
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 56
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            color: active ? (controller ? controller.panelAccent : "#d7472f") : "transparent"
            border.color: controller ? controller.panelAccent : "#d7472f"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: active ? "ON" : "USE"
                color: active ? (controller ? controller.panelBg : "#15110f") : (controller ? controller.panelAccent : "#d7472f")
                font.pixelSize: 10
                font.family: "monospace"
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
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

    }

    MouseArea {
        id: hover

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onWheel: (wheel) => {
            if (controller)
                controller.wheelVolume(node, wheel);

        }
    }

}

import QtQuick

Item {
    property var controller: null
    property var node: null

    height: 24

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 5
        color: Qt.rgba(1, 1, 1, 0.12)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * (controller ? controller.volumeRatio(parent.node) : 0)
        height: 5
        color: parent.node && parent.node.audio && parent.node.audio.muted
            ? (controller ? controller.mutedFg : "#9f8f7c")
            : (controller ? controller.panelAccent : "#d7472f")
        opacity: parent.node && parent.node.audio && parent.node.audio.muted ? 0.45 : 1
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => {
            if (parent.controller) parent.controller.setVolumeFromX(parent.node, mouse.x, width)
        }
        onPositionChanged: (mouse) => {
            if (pressed && parent.controller) parent.controller.setVolumeFromX(parent.node, mouse.x, width)
        }
    }
}

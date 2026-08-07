import QtQuick

Rectangle {
    id: resultRow

    property var entry: null
    property var controller: null
    property int resultIndex: 0
    property bool selected: false
    property color panelBg: "#15110f"
    property color panelFg: "#f1e7d0"
    property color panelAccent: "#d7472f"
    property color mutedFg: "#9f8f7c"
    property color inkBg: "#1b1613"

    signal hovered(int index)
    signal activated(int index)

    height: 58
    radius: 0
    color: selected || resultMouse.containsMouse ? inkBg : "transparent"
    border.color: "transparent"
    border.width: 0

    Rectangle {
        width: 3
        height: parent.height
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        radius: 0
        color: resultRow.panelAccent
        opacity: resultRow.selected ? 1 : 0
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 13
        anchors.rightMargin: 12
        spacing: 12

        Text {
            width: 24
            anchors.verticalCenter: parent.verticalCenter
            text: (resultRow.resultIndex + 1).toString().padStart(2, "0")
            color: resultRow.selected ? resultRow.panelAccent : resultRow.mutedFg
            font.family: "monospace"
            font.pixelSize: 8
        }

        Rectangle {
            width: resultRow.entry && resultRow.entry.isImage ? 52 : 28
            height: resultRow.entry && resultRow.entry.isImage ? 44 : 28
            radius: 0
            color: resultRow.panelBg
            border.color: "transparent"
            border.width: 0
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            Image {
                id: entryThumbImage

                anchors.fill: parent
                anchors.margins: 2
                source: resultRow.entry && resultRow.entry.isImage && resultRow.entry.preview !== "" && resultRow.controller ? resultRow.controller.previewSource(resultRow.entry.preview) : ""
                sourceSize: Qt.size(136, 112)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                cache: false
                visible: source !== "" && status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: resultRow.entry && resultRow.entry.isImage ? "" : ""
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 17
                color: resultRow.panelAccent
                visible: !resultRow.entry || !resultRow.entry.isImage || entryThumbImage.status !== Image.Ready
            }

        }

        Column {
            width: parent.width - 120 - (resultRow.entry && resultRow.entry.isImage ? 52 : 28)
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: resultRow.entry && resultRow.controller ? resultRow.controller.entryTypeLabel(resultRow.entry) + "  /  " + (resultRow.entry.isImage ? resultRow.entry.title : resultRow.entry.subtitle) : ""
                color: resultRow.mutedFg
                font.family: "monospace"
                font.pixelSize: 8
                font.letterSpacing: 1
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
                width: parent.width
            }

            Text {
                text: resultRow.entry ? (resultRow.entry.isImage ? resultRow.entry.subtitle : resultRow.entry.title) : ""
                color: resultRow.panelFg
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: resultRow.entry && resultRow.entry.isImage ? 1 : 2
                width: parent.width
                wrapMode: Text.WordWrap
            }

        }

        Text {
            width: 60
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: resultRow.selected ? "ENTER  ↵" : "PASTE  ↗"
            color: resultRow.selected ? resultRow.panelAccent : resultRow.mutedFg
            font.family: "monospace"
            font.pixelSize: 8
        }

    }

    MouseArea {
        id: resultMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: resultRow.hovered(resultRow.resultIndex)
        onClicked: resultRow.activated(resultRow.resultIndex)
    }

    Behavior on color {
        ColorAnimation {
            duration: 110
        }

    }

}

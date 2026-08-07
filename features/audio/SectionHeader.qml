import QtQuick

Row {
    property var controller: null
    property string title: ""
    property int count: 0

    height: 18
    spacing: 8

    Text {
        width: parent.width - 52
        text: parent.title
        color: controller ? controller.panelAccent : "#d7472f"
        font.pixelSize: 9
        font.letterSpacing: 3
        font.bold: true
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        width: 44
        text: parent.count.toString()
        color: controller ? controller.mutedFg : "#9f8f7c"
        font.pixelSize: 10
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }
}

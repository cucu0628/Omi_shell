import QtQuick
import "." as AboutUi
import "../../ui" as SharedUi

SharedUi.DashPanel {
    id: sectionCard

    property var entries: []
    property real rowHeight: 32
    property real rowGap: 6

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: sectionCard.rowGap

        Repeater {
            model: sectionCard.entries

            AboutUi.InfoRow {
                width: parent.width
                height: sectionCard.rowHeight
                theme: sectionCard.theme
                entry: modelData
            }
        }
    }

    Text {
        anchors.fill: parent
        visible: sectionCard.entries.length === 0
        text: "No data"
        color: sectionCard.muted
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}

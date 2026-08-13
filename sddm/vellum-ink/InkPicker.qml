import QtQuick

// Valaszto gomb (felhasznalo / munkamenet). A legordulo listat az InkCard
// rajzolja fololtetkent, hogy az egerkattintas ne akadjon el a szuloi hataron.
Item {
    id: picker

    required property var greeter
    property string pickerId: ""
    property string kanji: ""
    property string label: ""
    property var entries: []
    property int currentIndex: 0

    readonly property bool open: greeter.openPicker === pickerId
    readonly property bool selectable: entries.length > 1
    readonly property string currentLabel: (currentIndex >= 0 && currentIndex < entries.length)
        ? entries[currentIndex].label
        : "—"

    implicitWidth: row.implicitWidth
    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -10
        anchors.rightMargin: -10
        color: picker.greeter.accent
        opacity: picker.open ? 0.12 : (mouse.containsMouse && picker.selectable ? 0.07 : 0)

        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: -10
        anchors.bottom: parent.bottom
        width: picker.open ? parent.width + 20 : 0
        height: 1
        color: picker.greeter.accent

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
            text: picker.kanji
            visible: picker.kanji !== ""
            color: picker.greeter.accent
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: picker.label
            color: picker.greeter.muted
            font.pixelSize: 9
            font.letterSpacing: 2.4
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: picker.currentLabel
            color: picker.greeter.foreground
            font.pixelSize: 12
            font.letterSpacing: 0.6
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 220)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "▾"
            visible: picker.selectable
            color: picker.open ? picker.greeter.accent : picker.greeter.muted
            font.pixelSize: 9
            rotation: picker.open ? 180 : 0
            anchors.verticalCenter: parent.verticalCenter

            Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        anchors.leftMargin: -10
        anchors.rightMargin: -10
        hoverEnabled: true
        enabled: picker.selectable
        onClicked: picker.greeter.openPicker = picker.open ? "" : picker.pickerId
    }
}

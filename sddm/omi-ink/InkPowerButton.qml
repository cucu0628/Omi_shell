import QtQuick

// Egyszeru szoveges gomb: kanji jel + latin felirat, ikonfont nelkul.
Item {
    id: button

    required property var greeter
    property string kanji: ""
    property string label: ""
    property bool danger: false

    signal activated()

    readonly property color markColor: danger ? greeter.alertColor : greeter.accent

    implicitWidth: Math.max(kanjiText.implicitWidth, labelText.implicitWidth) + 22
    implicitHeight: 34
    opacity: enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        color: button.markColor
        opacity: mouse.containsMouse ? 0.12 : 0

        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: mouse.containsMouse ? parent.width : 0
        height: 1
        color: button.markColor

        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Column {
        anchors.centerIn: parent
        spacing: 1

        Text {
            id: kanjiText

            anchors.horizontalCenter: parent.horizontalCenter
            text: button.kanji
            color: mouse.containsMouse ? button.markColor : button.greeter.foreground
            font.pixelSize: 12

            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Text {
            id: labelText

            anchors.horizontalCenter: parent.horizontalCenter
            text: button.label
            color: button.greeter.muted
            font.pixelSize: 8
            font.letterSpacing: 1.6
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        enabled: button.enabled
        onClicked: button.activated()
    }
}

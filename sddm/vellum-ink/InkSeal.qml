import QtQuick

// Csendes pecset: allo negyzetkeret, tuskor es lakatjel.
Item {
    id: seal

    required property var greeter
    property real diameter: 96
    property bool busy: false
    property bool alert: false
    property string glyph: "LOCK"

    readonly property color markColor: alert ? greeter.alertColor : greeter.accent

    width: diameter
    height: diameter

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.74
        height: width
        color: "transparent"
        border.color: seal.markColor
        border.width: 1
        opacity: 0.32
        rotation: 45

        RotationAnimation on rotation {
            from: 45
            to: 405
            duration: 150000
            loops: Animation.Infinite
            running: true
        }

        Behavior on border.color { ColorAnimation { duration: 160 } }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.52
        height: width
        radius: width / 2
        color: Qt.rgba(0, 0, 0, 0.2)
        border.color: seal.markColor
        border.width: 1
        opacity: 0.85

        Behavior on border.color { ColorAnimation { duration: 160 } }
    }

    Text {
        anchors.centerIn: parent
        text: seal.glyph
        color: seal.markColor
        font.pixelSize: Math.round(seal.diameter * 0.13)
        font.letterSpacing: 2
        font.weight: Font.DemiBold

        Behavior on color { ColorAnimation { duration: 160 } }

        SequentialAnimation on opacity {
            running: seal.busy
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.35; duration: 620; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 620; easing.type: Easing.InOutSine }
        }
    }
}

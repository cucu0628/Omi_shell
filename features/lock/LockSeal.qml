import QtQuick

// Forgó pecsét: külső osztásgyűrű, ellenirányú rombusz és a 守 jel.
Item {
    id: seal

    required property var lockRoot
    property real diameter: 96
    property bool busy: false
    property bool alert: false
    property string glyph: "守"

    readonly property color markColor: alert ? lockRoot.alertColor : lockRoot.accent

    width: diameter
    height: diameter

    Item {
        anchors.fill: parent

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: seal.busy ? 3400 : 48000
            loops: Animation.Infinite
            running: true
        }

        Repeater {
            model: 36

            Item {
                required property int index

                anchors.fill: parent
                rotation: index * 10

                Rectangle {
                    width: 1
                    height: index % 3 === 0 ? seal.diameter * 0.08 : seal.diameter * 0.035
                    color: seal.markColor
                    opacity: index % 3 === 0 ? 0.7 : 0.3
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                }
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.66
        height: width
        color: "transparent"
        border.color: seal.markColor
        border.width: 1
        opacity: 0.4

        RotationAnimation on rotation {
            from: 45
            to: -315
            duration: 66000
            loops: Animation.Infinite
            running: true
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.58
        height: width
        radius: width / 2
        color: Qt.rgba(0, 0, 0, 0.24)
        border.color: seal.markColor
        border.width: 1
        opacity: 0.92
    }

    Text {
        anchors.centerIn: parent
        text: seal.glyph
        color: seal.markColor
        font.pixelSize: Math.round(seal.diameter * 0.28)
        font.weight: Font.DemiBold

        Behavior on color { ColorAnimation { duration: 140 } }
    }

    SequentialAnimation on scale {
        running: seal.busy
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation { to: 1.06; duration: 440; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 440; easing.type: Easing.InOutSine }
    }
}

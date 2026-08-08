import QtQuick
import "." as Ink

Item {
    id: backgroundView

    required property var greeter

    readonly property bool alive: greeter.ready && !greeter.closing
    readonly property real ensoSize: Math.min(width, height) * 0.62

    Rectangle {
        id: paper

        anchors.fill: parent
        color: backgroundView.greeter.background

        Behavior on color { ColorAnimation { duration: 180 } }
    }

    // Enso: nyitott tuskor, alig lathatoan, lassan lelegezve.
    Item {
        width: backgroundView.ensoSize
        height: backgroundView.ensoSize
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -backgroundView.height * 0.04
        opacity: backgroundView.alive ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }

        Item {
            anchors.fill: parent
            rotation: -14

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: backgroundView.greeter.foreground
                border.width: 2
                opacity: 0.07

                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.045; duration: 7000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.07; duration: 7000; easing.type: Easing.InOutSine }
                }
            }

            // Az ecsetvonas nyitott vege.
            Rectangle {
                width: parent.width * 0.3
                height: parent.height * 0.17
                radius: height / 2
                color: paper.color
                anchors.right: parent.right
                anchors.rightMargin: parent.width * -0.04
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.1
            }
        }
    }

    Ink.InkGlow {
        width: Math.min(backgroundView.width * 0.9, 1100)
        height: width * 0.7
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: backgroundView.width * 0.08
        y: -height * 0.42
        glowColor: backgroundView.greeter.foreground
        intensity: backgroundView.alive ? 0.05 : 0

        Behavior on intensity { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.16) }
            GradientStop { position: 0.45; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.42) }
        }
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.24) }
            GradientStop { position: 0.36; color: "transparent" }
            GradientStop { position: 0.64; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.24) }
        }
    }
}

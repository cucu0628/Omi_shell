import QtQuick
import "." as LockUi

Item {
    id: backgroundView

    required property var lockRoot

    readonly property bool alive: lockRoot.ready && !lockRoot.closing

    Rectangle {
        anchors.fill: parent
        color: backgroundView.lockRoot.background

        Behavior on color { ColorAnimation { duration: 180 } }
    }

    QtObject {
        id: drift
        property real x: 0
        property real y: 0
        property real shaft: 0
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        ParallelAnimation {
            NumberAnimation { target: drift; property: "x"; to: 26; duration: 6200; easing.type: Easing.InOutSine }
            NumberAnimation { target: drift; property: "y"; to: 14; duration: 6200; easing.type: Easing.InOutSine }
        }

        ParallelAnimation {
            NumberAnimation { target: drift; property: "x"; to: -14; duration: 6800; easing.type: Easing.InOutSine }
            NumberAnimation { target: drift; property: "y"; to: -10; duration: 6800; easing.type: Easing.InOutSine }
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        NumberAnimation { target: drift; property: "shaft"; to: 46; duration: 9400; easing.type: Easing.InOutSine }
        NumberAnimation { target: drift; property: "shaft"; to: -46; duration: 9400; easing.type: Easing.InOutSine }
    }

    // Hajszálvékony rács – a shell panelek rajzos, mérnöki karakteréhez.
    Item {
        anchors.fill: parent
        opacity: backgroundView.alive ? 0.05 : 0

        Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }

        Repeater {
            model: Math.max(1, Math.ceil(backgroundView.width / 128))

            Rectangle {
                required property int index

                x: index * 128
                width: 1
                height: backgroundView.height
                color: backgroundView.lockRoot.foreground
            }
        }

        Repeater {
            model: Math.max(1, Math.ceil(backgroundView.height / 128))

            Rectangle {
                required property int index

                y: index * 128
                width: backgroundView.width
                height: 1
                color: backgroundView.lockRoot.foreground
            }
        }
    }

    // Komorebi: ferde fénysávok, amelyek lassan sodródnak.
    Item {
        anchors.fill: parent
        opacity: backgroundView.alive ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } }

        Repeater {
            model: 3

            Item {
                required property int index

                width: 1
                height: 1
                x: backgroundView.width * (0.17 + index * 0.29) + drift.shaft * (1 + index * 0.5)
                y: backgroundView.height / 2
                rotation: -21

                Rectangle {
                    width: 96 + index * 58
                    height: backgroundView.height * 2.6
                    anchors.centerIn: parent
                    opacity: 0.06 - index * 0.013

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: index === 1 ? backgroundView.lockRoot.foreground : backgroundView.lockRoot.accent }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }
        }
    }

    LockUi.LockGlow {
        width: 560
        height: 560
        x: backgroundView.width - 320 + drift.x
        y: -210 + drift.y
        glowColor: backgroundView.lockRoot.accent
        intensity: backgroundView.alive ? 0.17 : 0

        Behavior on intensity { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
    }

    LockUi.LockGlow {
        width: 480
        height: 480
        x: -200 - drift.x * 0.7
        y: backgroundView.height - 260 - drift.y * 0.7
        glowColor: backgroundView.lockRoot.foreground
        intensity: backgroundView.alive ? 0.07 : 0

        Behavior on intensity { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }
    }

    // Vignetta: függőleges mélység és oldalsó elsötétítés.
    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.30) }
            GradientStop { position: 0.42; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.46) }
        }
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.26) }
            GradientStop { position: 0.34; color: "transparent" }
            GradientStop { position: 0.66; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.26) }
        }
    }
}

import QtQuick

// Shoji-redony: papirtablak csusznak szet inditaskor, es ossze sikeres
// bejelentkezeskor. A talalkozo elt lagy arnyek kiseri.
Item {
    id: shutter

    required property var greeter

    property real shutterFactor: 0
    property real dimOpacity: 0
    property real alertOpacity: 0

    readonly property color panelColor: greeter.background
    readonly property real edgeShadow: 1 - Math.min(1, shutterFactor * 3)

    Rectangle {
        width: parent.width
        height: Math.ceil(parent.height / 2) + 1
        y: -shutter.shutterFactor * height
        color: shutter.panelColor

        Rectangle {
            width: parent.width
            height: 26
            anchors.bottom: parent.bottom
            opacity: 0.5 * shutter.edgeShadow

            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: Math.ceil(parent.height / 2) + 1
        y: parent.height / 2 + shutter.shutterFactor * height
        color: shutter.panelColor

        Rectangle {
            width: parent.width
            height: 26
            anchors.top: parent.top
            opacity: 0.5 * shutter.edgeShadow

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.55) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: shutter.dimOpacity
    }

    Rectangle {
        anchors.fill: parent
        color: shutter.greeter.alertColor
        opacity: shutter.alertOpacity
    }

    SequentialAnimation {
        running: shutter.greeter.ready && !shutter.greeter.closing

        ParallelAnimation {
            NumberAnimation { target: shutter; property: "shutterFactor"; to: 1; duration: 680; easing.type: Easing.OutCubic }
            NumberAnimation { target: shutter; property: "dimOpacity"; to: 0; duration: 420; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        running: shutter.greeter.closing

        PauseAnimation { duration: 110 }

        NumberAnimation { target: shutter; property: "shutterFactor"; to: 0; duration: 300; easing.type: Easing.InOutCubic }

        NumberAnimation { target: shutter; property: "dimOpacity"; to: 0.55; duration: 230; easing.type: Easing.InCubic }
    }

    Connections {
        target: shutter.greeter

        function onFailedChanged() {
            if (shutter.greeter.failed) alertAnimation.restart()
        }
    }

    SequentialAnimation {
        id: alertAnimation
        NumberAnimation { target: shutter; property: "alertOpacity"; to: 0.05; duration: 90 }
        NumberAnimation { target: shutter; property: "alertOpacity"; to: 0; duration: 420; easing.type: Easing.OutCubic }
    }
}

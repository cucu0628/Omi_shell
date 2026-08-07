import QtQuick

// Shoji-redőny: záráskor becsukódik és egy fénypászmává húzódik össze,
// belépéskor ugyanez visszafelé játszódik le minden monitoron egyszerre.
Item {
    id: shutter

    required property var lockRoot

    property real shutterFactor: 0
    property real seamFactor: 1
    property real flashOpacity: 0
    property real alertOpacity: 0

    readonly property color panelColor: lockRoot.background
    readonly property color beamColor: lockRoot.accent

    Rectangle {
        id: topPanel

        width: parent.width
        height: Math.ceil(parent.height / 2) + 1
        y: -shutter.shutterFactor * height
        color: shutter.panelColor

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: shutter.beamColor
            opacity: 0.45
        }
    }

    Rectangle {
        id: bottomPanel

        width: parent.width
        height: Math.ceil(parent.height / 2) + 1
        y: parent.height / 2 + shutter.shutterFactor * height
        color: shutter.panelColor

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: shutter.beamColor
            opacity: 0.45
        }
    }

    Rectangle {
        width: parent.width * shutter.seamFactor
        height: 30
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 15
        opacity: 0.34 * shutter.seamFactor

        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: shutter.beamColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        width: parent.width * shutter.seamFactor
        height: 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 1
        color: shutter.beamColor
        opacity: shutter.seamFactor > 0.001 ? 1 : 0
    }

    // A záró villanás a résből árad ki, nem lapos teljes képernyős lap.
    Rectangle {
        width: parent.width
        height: parent.height * 0.6
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - height / 2
        opacity: shutter.flashOpacity

        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: shutter.beamColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: shutter.lockRoot.alertColor
        opacity: shutter.alertOpacity
    }

    SequentialAnimation {
        running: shutter.lockRoot.ready && !shutter.lockRoot.closing

        ParallelAnimation {
            NumberAnimation { target: shutter; property: "shutterFactor"; to: 1; duration: 640; easing.type: Easing.OutCubic }

            SequentialAnimation {
                PauseAnimation { duration: 240 }
                NumberAnimation { target: shutter; property: "seamFactor"; to: 0; duration: 500; easing.type: Easing.InOutCubic }
            }
        }
    }

    SequentialAnimation {
        running: shutter.lockRoot.closing

        PauseAnimation { duration: 90 }

        NumberAnimation { target: shutter; property: "shutterFactor"; to: 0; duration: 220; easing.type: Easing.InCubic }

        ParallelAnimation {
            NumberAnimation { target: shutter; property: "seamFactor"; to: 1; duration: 110; easing.type: Easing.OutQuart }
            NumberAnimation { target: shutter; property: "flashOpacity"; to: 0.62; duration: 110 }
        }

        ParallelAnimation {
            NumberAnimation { target: shutter; property: "seamFactor"; to: 0; duration: 210; easing.type: Easing.InQuart }
            NumberAnimation { target: shutter; property: "flashOpacity"; to: 0; duration: 240 }
        }
    }

    Connections {
        target: shutter.lockRoot

        function onFailedChanged() {
            if (shutter.lockRoot.failed) alertAnimation.restart()
        }
    }

    SequentialAnimation {
        id: alertAnimation
        NumberAnimation { target: shutter; property: "alertOpacity"; to: 0.14; duration: 70 }
        NumberAnimation { target: shutter; property: "alertOpacity"; to: 0; duration: 340; easing.type: Easing.OutCubic }
    }
}

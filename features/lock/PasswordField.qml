import QtQuick

Rectangle {
    id: passwordBox

    required property var lockRoot

    readonly property int charCount: lockRoot.password.length
    readonly property int dotCount: Math.min(charCount, 22)
    readonly property color edgeColor: lockRoot.failed ? lockRoot.alertColor : lockRoot.accent

    function forceInputFocus() {
        passwordInput.forceActiveFocus()
    }

    height: 50
    color: lockRoot.surface
    border.color: edgeColor
    border.width: lockRoot.failed ? 2 : 1
    radius: 0
    transform: Translate { id: failedShake; x: 0 }

    onCharCountChanged: keyPulse.restart()

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on border.width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    Connections {
        target: passwordBox.lockRoot

        function onFailedChanged() {
            if (passwordBox.lockRoot.failed) shakeAnimation.restart()
        }
    }

    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: failedShake; property: "x"; to: -10; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: failedShake; property: "x"; to: 10; duration: 70; easing.type: Easing.InOutQuad }
        NumberAnimation { target: failedShake; property: "x"; to: -7; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: failedShake; property: "x"; to: 5; duration: 55; easing.type: Easing.InOutQuad }
        NumberAnimation { target: failedShake; property: "x"; to: 0; duration: 80; easing.type: Easing.OutCubic }
    }

    // Leütésre felvillanó belső fény.
    Rectangle {
        id: pulseOverlay
        anchors.fill: parent
        anchors.margins: 1
        color: passwordBox.lockRoot.accent
        opacity: 0
    }

    NumberAnimation {
        id: keyPulse
        target: pulseOverlay
        property: "opacity"
        from: 0.16
        to: 0
        duration: 280
        easing.type: Easing.OutCubic
    }

    Rectangle {
        width: 3
        height: parent.height
        anchors.left: parent.left
        color: passwordBox.edgeColor

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
        text: ""
        font.family: "omarchy"
        font.pixelSize: 15
        color: passwordBox.edgeColor
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Row {
        id: dots

        anchors.left: parent.left
        anchors.leftMargin: 52
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Repeater {
            model: passwordBox.dotCount

            Rectangle {
                width: 7
                height: 7
                color: passwordBox.edgeColor
                anchors.verticalCenter: parent.verticalCenter

                NumberAnimation on scale {
                    from: 0.2
                    to: 1
                    duration: 180
                    easing.type: Easing.OutBack
                }
            }
        }
    }

    Rectangle {
        id: caret

        width: 2
        height: 20
        x: 52 + (passwordBox.dotCount > 0 ? dots.width + 6 : 0)
        anchors.verticalCenter: parent.verticalCenter
        color: passwordBox.edgeColor
        visible: !passwordBox.lockRoot.unlockInProgress

        Behavior on x { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

        SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: 0.1; duration: 540; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 540; easing.type: Easing.InOutSine }
        }
    }

    Text {
        text: "PASSWORD"
        visible: passwordBox.charCount === 0 && !passwordBox.lockRoot.unlockInProgress
        color: passwordBox.lockRoot.muted
        opacity: 0.55
        font.pixelSize: 10
        font.letterSpacing: 4
        x: 66
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: passwordBox.lockRoot.unlockInProgress
            ? "認証"
            : (passwordBox.charCount > 0 ? passwordBox.lockRoot.two(Math.min(passwordBox.charCount, 99)) : "--")
        color: passwordBox.lockRoot.unlockInProgress ? passwordBox.lockRoot.accent : passwordBox.lockRoot.muted
        font.family: passwordBox.lockRoot.unlockInProgress ? "" : "monospace"
        font.pixelSize: 10
        opacity: 0.8
    }

    // Hitelesítés alatt futó jelzőcsík az alsó élen.
    Rectangle {
        property real slideMargin: 18

        width: passwordBox.lockRoot.unlockInProgress ? 32 : 0
        height: 1
        anchors.right: parent.right
        anchors.rightMargin: slideMargin
        anchors.bottom: parent.bottom
        color: passwordBox.lockRoot.accent
        opacity: passwordBox.lockRoot.unlockInProgress ? 0.9 : 0

        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        SequentialAnimation on slideMargin {
            running: passwordBox.lockRoot.unlockInProgress
            loops: Animation.Infinite
            NumberAnimation { to: 64; duration: 640; easing.type: Easing.InOutSine }
            NumberAnimation { to: 18; duration: 640; easing.type: Easing.InOutSine }
        }
    }

    TextInput {
        id: passwordInput

        anchors.fill: parent
        opacity: 0
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
        enabled: !passwordBox.lockRoot.unlockInProgress
        focus: true
        text: passwordBox.lockRoot.password
        onTextChanged: passwordBox.lockRoot.password = text
        onAccepted: passwordBox.lockRoot.tryUnlock()
    }
}

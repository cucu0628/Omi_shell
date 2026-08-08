import QtQuick

Rectangle {
    id: passwordBox

    required property var greeter

    readonly property int charCount: greeter.password.length
    readonly property int dotCount: Math.min(charCount, 22)
    readonly property color edgeColor: greeter.failed ? greeter.alertColor : greeter.accent
    readonly property bool capsOn: (typeof keyboard !== "undefined") && keyboard.capsLock
    readonly property bool inputActive: passwordInput.activeFocus

    function forceInputFocus() {
        passwordInput.forceActiveFocus()
    }

    height: 50
    color: greeter.surface
    border.color: edgeColor
    border.width: greeter.failed ? 2 : 1
    radius: 0
    transform: Translate { id: failedShake; x: 0 }

    onCharCountChanged: keyPulse.restart()

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }
    Behavior on border.width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Connections {
        target: passwordBox.greeter

        function onFailedChanged() {
            if (passwordBox.greeter.failed) shakeAnimation.restart()
        }
    }

    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: failedShake; property: "x"; to: -9; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: failedShake; property: "x"; to: 9; duration: 75; easing.type: Easing.InOutQuad }
        NumberAnimation { target: failedShake; property: "x"; to: -6; duration: 65; easing.type: Easing.InOutQuad }
        NumberAnimation { target: failedShake; property: "x"; to: 4; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: failedShake; property: "x"; to: 0; duration: 90; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: pulseOverlay
        anchors.fill: parent
        anchors.margins: 1
        color: passwordBox.greeter.accent
        opacity: 0
    }

    NumberAnimation {
        id: keyPulse
        target: pulseOverlay
        property: "opacity"
        from: 0.1
        to: 0
        duration: 300
        easing.type: Easing.OutCubic
    }

    Rectangle {
        width: 3
        height: parent.height
        anchors.left: parent.left
        color: passwordBox.edgeColor

        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Text {
        text: "鍵"
        font.pixelSize: 15
        color: passwordBox.edgeColor
        anchors.left: parent.left
        anchors.leftMargin: 19
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 140 } }
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
                    from: 0.3
                    to: 1
                    duration: 200
                    easing.type: Easing.OutCubic
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
        visible: !passwordBox.greeter.busy

        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: 0.1; duration: 620; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 620; easing.type: Easing.InOutSine }
        }
    }

    Text {
        text: passwordBox.greeter.userNeedsPassword ? "PASSWORD" : "PRESS ENTER"
        visible: passwordBox.charCount === 0 && !passwordBox.greeter.busy
        color: passwordBox.greeter.muted
        opacity: 0.5
        font.pixelSize: 10
        font.letterSpacing: 4
        x: 66
        anchors.verticalCenter: parent.verticalCenter
    }

    // Caps Lock jelzes – SDDM-nel konnyu belefutni.
    Text {
        text: "CAPS"
        visible: passwordBox.capsOn
        color: passwordBox.greeter.alertColor
        font.pixelSize: 9
        font.letterSpacing: 2
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 8
    }

    // Hitelesites alatt lassan sodrodo jelzocsik az also elen.
    Rectangle {
        property real slideMargin: 18

        width: passwordBox.greeter.busy ? 30 : 0
        height: 1
        anchors.right: parent.right
        anchors.rightMargin: slideMargin
        anchors.bottom: parent.bottom
        color: passwordBox.greeter.accent
        opacity: passwordBox.greeter.busy ? 0.7 : 0

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        SequentialAnimation on slideMargin {
            running: passwordBox.greeter.busy
            loops: Animation.Infinite
            NumberAnimation { to: 62; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 18; duration: 900; easing.type: Easing.InOutSine }
        }
    }

    TextInput {
        id: passwordInput

        anchors.fill: parent
        opacity: 0
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
        enabled: !passwordBox.greeter.busy
        focus: true
        text: passwordBox.greeter.password
        onTextChanged: passwordBox.greeter.password = text
        onAccepted: passwordBox.greeter.tryLogin()

        Keys.onEscapePressed: passwordBox.greeter.clearPassword()
    }
}

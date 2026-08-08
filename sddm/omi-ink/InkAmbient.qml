import QtQuick
import "." as Ink

// Masodlagos kijelzok: csak ora, pecset es allapot – bevitel nelkul.
Item {
    id: ambient

    required property var greeter

    readonly property bool opened: greeter.revealStep >= 2 && !greeter.closing
    readonly property string stateText: greeter.failed
        ? "ACCESS DENIED"
        : (greeter.busy ? "AUTHENTICATING" : "AWAITING SIGN IN")
    readonly property string stateKanji: greeter.failed
        ? "拒否"
        : (greeter.busy ? "認証中" : "待機中")

    focus: true

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -8
        width: Math.min(parent.width * 0.72, 660)
        spacing: 30
        opacity: ambient.opened ? 1 : 0
        scale: ambient.opened ? 1 : 0.99

        transform: Translate {
            y: ambient.opened ? 0 : 14
            Behavior on y {
                NumberAnimation { duration: ambient.greeter.closing ? 200 : 560; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: ambient.greeter.closing ? 170 : 500; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: ambient.greeter.closing ? 200 : 560; easing.type: Easing.OutCubic }
        }

        Ink.InkClock {
            anchors.horizontalCenter: parent.horizontalCenter
            greeter: ambient.greeter
            centered: true
            timeSize: Math.round(Math.min(146, ambient.width * 0.1))
            barWidth: 240
        }

        Ink.InkSeal {
            anchors.horizontalCenter: parent.horizontalCenter
            diameter: 122
            greeter: ambient.greeter
            busy: ambient.greeter.busy
            alert: ambient.greeter.failed
        }

        Column {
            width: parent.width
            spacing: 11

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ambient.stateText
                color: ambient.greeter.failed ? ambient.greeter.alertColor : ambient.greeter.foreground
                font.pixelSize: 17
                font.letterSpacing: 4
                font.weight: Font.DemiBold

                Behavior on color { ColorAnimation { duration: 160 } }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ambient.stateKanji
                color: ambient.greeter.accent
                font.pixelSize: 11
                font.letterSpacing: 3
            }

            // A begepelt karakterek a tobbi kijelzon is latszanak.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 8
                spacing: 7
                visible: ambient.greeter.password.length > 0

                Repeater {
                    model: Math.min(ambient.greeter.password.length, 22)

                    Rectangle {
                        width: 6
                        height: 6
                        color: ambient.greeter.failed ? ambient.greeter.alertColor : ambient.greeter.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ambient.greeter.userLabel
                color: ambient.greeter.muted
                font.pixelSize: 10
                font.letterSpacing: 1.4
                opacity: 0.75
            }
        }
    }

    // A greeter minden kepernyore kulon ablakot nyit, es a billentyuzet fokusz
    // nem feltetlenul a kartyat mutato ablake. Ezert itt is fogadjuk a gepelest:
    // igy a jelszo barmelyik kijelzon beirhato.
    TextInput {
        id: ambientPasswordInput

        width: 1
        height: 1
        opacity: 0
        focus: true
        enabled: !ambient.greeter.busy
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
        text: ambient.greeter.password
        onTextChanged: ambient.greeter.password = text
        onAccepted: ambient.greeter.tryLogin()

        Keys.onEscapePressed: ambient.greeter.clearPassword()
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            if (!ambientPasswordInput.activeFocus) ambientPasswordInput.forceActiveFocus()
        }
    }
}

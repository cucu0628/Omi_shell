import QtQuick
import "." as LockUi

Item {
    id: ambientView

    required property var lockRoot
    property string screenName: ""

    readonly property bool opened: lockRoot.revealStep >= 2 && !lockRoot.closing
    readonly property string stateText: lockRoot.failed
        ? "ACCESS DENIED"
        : (lockRoot.unlockInProgress ? "AUTHENTICATING" : "SESSION SECURED")
    readonly property string stateKanji: lockRoot.failed
        ? "拒否"
        : (lockRoot.unlockInProgress ? "認証中" : "施錠中")

    focus: true

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -8
        width: Math.min(parent.width * 0.72, 660)
        spacing: 30
        opacity: ambientView.opened ? 1 : 0
        scale: ambientView.opened ? 1 : 0.99

        transform: Translate {
            y: ambientView.opened ? 0 : 14
            Behavior on y {
                NumberAnimation { duration: ambientView.lockRoot.closing ? 200 : 560; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: ambientView.lockRoot.closing ? 170 : 500; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: ambientView.lockRoot.closing ? 200 : 560; easing.type: Easing.OutCubic }
        }

        LockUi.LockClock {
            anchors.horizontalCenter: parent.horizontalCenter
            lockRoot: ambientView.lockRoot
            centered: true
            timeSize: Math.round(Math.min(146, ambientView.width * 0.1))
            barWidth: 240
        }

        LockUi.LockSeal {
            anchors.horizontalCenter: parent.horizontalCenter
            diameter: 122
            lockRoot: ambientView.lockRoot
            busy: ambientView.lockRoot.unlockInProgress
            alert: ambientView.lockRoot.failed
        }

        Column {
            width: parent.width
            spacing: 11

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ambientView.stateText
                color: ambientView.lockRoot.failed ? ambientView.lockRoot.alertColor : ambientView.lockRoot.foreground
                font.pixelSize: 17
                font.letterSpacing: 4
                font.weight: Font.DemiBold

                Behavior on color { ColorAnimation { duration: 160 } }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ambientView.stateKanji
                color: ambientView.lockRoot.accent
                font.pixelSize: 11
                font.letterSpacing: 3
            }

            // A begépelt karakterek a többi kijelzőn is látszanak.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 8
                spacing: 7
                visible: ambientView.lockRoot.password.length > 0

                Repeater {
                    model: Math.min(ambientView.lockRoot.password.length, 22)

                    Rectangle {
                        width: 6
                        height: 6
                        color: ambientView.lockRoot.failed ? ambientView.lockRoot.alertColor : ambientView.lockRoot.accent
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

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "unlock on " + ambientView.lockRoot.effectiveInputMonitorName
                color: ambientView.lockRoot.muted
                font.pixelSize: 10
                font.letterSpacing: 1.4
                opacity: 0.75
            }
        }
    }

    TextInput {
        id: ambientPasswordInput

        width: 1
        height: 1
        opacity: 0
        focus: true
        enabled: !ambientView.lockRoot.unlockInProgress
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
        text: ambientView.lockRoot.password
        onTextChanged: ambientView.lockRoot.password = text
        onAccepted: ambientView.lockRoot.tryUnlock()

        Keys.onEscapePressed: ambientView.lockRoot.clearPassword()
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: ambientPasswordInput.forceActiveFocus()
    }
}

import QtQuick
import "." as LockUi

FocusScope {
    id: focusScope

    required property var lockRoot
    property string screenName: ""

    readonly property bool opened: lockRoot.revealStep >= 2 && !lockRoot.closing
    readonly property int panelHeight: 244
    readonly property int panelWidth: Math.max(460, Math.min(focusScope.width - 160, 720))
    readonly property color baseColor: lockRoot.background

    focus: true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            focusScope.lockRoot.clearPassword()
            event.accepted = true
        }
    }

    Item {
        id: panelClip

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -4
        width: focusScope.panelWidth
        height: focusScope.opened ? focusScope.panelHeight : 0
        clip: true

        Behavior on height {
            NumberAnimation { duration: focusScope.lockRoot.closing ? 200 : 480; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: panel

            width: parent.width
            height: focusScope.panelHeight
            y: (parent.height - height) / 2
            radius: 0
            color: Qt.rgba(focusScope.baseColor.r, focusScope.baseColor.g, focusScope.baseColor.b, 0.88)
            border.color: focusScope.lockRoot.failed ? focusScope.lockRoot.alertColor : focusScope.lockRoot.accent
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 160 } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.color: focusScope.lockRoot.accent
                border.width: 1
                opacity: 0.2
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                height: 2
                color: focusScope.lockRoot.accent
                opacity: 0.75
            }

            Item {
                id: body

                anchors.fill: parent
                anchors.leftMargin: 30
                anchors.rightMargin: 30
                anchors.topMargin: 26
                anchors.bottomMargin: 26

                readonly property int leftWidth: Math.round(width * 0.42)

                LockUi.LockClock {
                    id: clockView

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: body.leftWidth - 26
                    lockRoot: focusScope.lockRoot
                    timeSize: 68
                    barWidth: width * 0.84
                    opacity: focusScope.lockRoot.revealStep >= 3 ? 1 : 0

                    transform: Translate {
                        x: focusScope.lockRoot.revealStep >= 3 ? 0 : -12
                        Behavior on x { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
                    }

                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    id: divider

                    x: body.leftWidth
                    width: 1
                    height: parent.height
                    color: focusScope.lockRoot.accent
                    opacity: 0.16
                }

                Item {
                    anchors.left: divider.right
                    anchors.leftMargin: 28
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: authColumn.height
                    opacity: focusScope.lockRoot.revealStep >= 4 ? 1 : 0

                    transform: Translate {
                        y: focusScope.lockRoot.revealStep >= 4 ? 0 : 10
                        Behavior on y { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
                    }

                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

                    Column {
                        id: authColumn

                        width: parent.width
                        spacing: 15

                        Row {
                            spacing: 15

                            LockUi.LockSeal {
                                diameter: 56
                                lockRoot: focusScope.lockRoot
                                busy: focusScope.lockRoot.unlockInProgress
                                alert: focusScope.lockRoot.failed
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    text: focusScope.lockRoot.userName
                                    color: focusScope.lockRoot.foreground
                                    font.pixelSize: 20
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: focusScope.lockRoot.powerText
                                    color: focusScope.lockRoot.muted
                                    font.pixelSize: 10
                                    font.letterSpacing: 1
                                }
                            }
                        }

                        LockUi.PasswordField {
                            id: passwordField

                            width: parent.width
                            lockRoot: focusScope.lockRoot
                        }

                        Text {
                            width: parent.width
                            text: focusScope.lockRoot.statusText
                            color: focusScope.lockRoot.failed ? focusScope.lockRoot.alertColor : focusScope.lockRoot.muted
                            font.pixelSize: 11
                            font.letterSpacing: 0.6
                            elide: Text.ElideRight
                            opacity: focusScope.lockRoot.revealStep >= 5 ? 1 : 0

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: passwordField.forceInputFocus()
    }
}

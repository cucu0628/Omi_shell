import QtQuick
import "." as LockUi

FocusScope {
    id: focusScope

    required property var lockRoot
    property string screenName: ""

    readonly property bool opened: lockRoot.revealStep >= 2 && !lockRoot.closing
    readonly property int panelHeight: 296
    readonly property int panelWidth: Math.max(460, Math.min(focusScope.width - 120, 780))
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
        anchors.verticalCenterOffset: -6
        width: focusScope.panelWidth
        height: focusScope.opened ? focusScope.panelHeight : 0
        clip: true

        Behavior on height {
            NumberAnimation { duration: focusScope.lockRoot.closing ? 190 : 460; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: panel

            width: parent.width
            height: focusScope.panelHeight
            y: (parent.height - height) / 2
            radius: 0
            color: Qt.rgba(focusScope.baseColor.r, focusScope.baseColor.g, focusScope.baseColor.b, 0.9)
            border.color: focusScope.lockRoot.failed ? focusScope.lockRoot.alertColor : focusScope.lockRoot.accent
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 140 } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.color: focusScope.lockRoot.accent
                border.width: 1
                opacity: 0.24
            }

            Item {
                id: header

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 18
                height: 34

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 32
                        height: 32
                        color: focusScope.lockRoot.accent
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "錠"
                            color: focusScope.lockRoot.background
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "SESSION LOCKED"
                            color: focusScope.lockRoot.foreground
                            font.pixelSize: 12
                            font.letterSpacing: 3
                            font.bold: true
                        }

                        Text {
                            text: "施錠  /  komorebi lock"
                            color: focusScope.lockRoot.muted
                            font.pixelSize: 9
                            font.letterSpacing: 0.5
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: focusScope.lockRoot.accent
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.22; duration: 950; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 950; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: "INPUT // " + focusScope.screenName
                        color: focusScope.lockRoot.muted
                        font.family: "monospace"
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                id: headerRule

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 14
                height: 1
                color: focusScope.lockRoot.accent
                opacity: 0.22
            }

            Item {
                id: body

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: headerRule.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 20
                anchors.bottomMargin: 20

                readonly property int leftWidth: Math.round(width * 0.42)

                LockUi.LockClock {
                    id: clockView

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: body.leftWidth - 22
                    lockRoot: focusScope.lockRoot
                    timeSize: 72
                    barWidth: width * 0.86
                    opacity: focusScope.lockRoot.revealStep >= 3 ? 1 : 0

                    transform: Translate {
                        x: focusScope.lockRoot.revealStep >= 3 ? 0 : -14
                        Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                    }

                    Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    id: divider

                    x: body.leftWidth
                    width: 1
                    height: parent.height
                    color: focusScope.lockRoot.accent
                    opacity: 0.18
                }

                Item {
                    anchors.left: divider.right
                    anchors.leftMargin: 24
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: authColumn.height
                    opacity: focusScope.lockRoot.revealStep >= 4 ? 1 : 0

                    transform: Translate {
                        y: focusScope.lockRoot.revealStep >= 4 ? 0 : 12
                        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                    }

                    Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

                    Column {
                        id: authColumn

                        width: parent.width
                        spacing: 14

                        Row {
                            spacing: 14

                            LockUi.LockSeal {
                                diameter: 52
                                lockRoot: focusScope.lockRoot
                                busy: focusScope.lockRoot.unlockInProgress
                                alert: focusScope.lockRoot.failed
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    text: focusScope.lockRoot.userName
                                    color: focusScope.lockRoot.foreground
                                    font.pixelSize: 20
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "local session  //  " + focusScope.lockRoot.powerText
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

                        Column {
                            width: parent.width
                            spacing: 6
                            opacity: focusScope.lockRoot.revealStep >= 5 ? 1 : 0

                            Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

                            Text {
                                width: parent.width
                                text: "// " + focusScope.lockRoot.statusText
                                color: focusScope.lockRoot.failed ? focusScope.lockRoot.alertColor : focusScope.lockRoot.muted
                                font.pixelSize: 11
                                elide: Text.ElideRight

                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                text: "ENTER  UNLOCK      ESC  CLEAR"
                                color: focusScope.lockRoot.muted
                                opacity: 0.5
                                font.family: "monospace"
                                font.pixelSize: 9
                                font.letterSpacing: 1
                            }
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

import QtQuick

// Képernyőnkénti keret: felső/alsó sáv a topbar arányaival, sarokjelekkel.
Item {
    id: chrome

    required property var lockRoot
    property string screenName: ""
    property bool primary: false

    readonly property int inset: 16

    opacity: lockRoot.revealStep >= 1 && !lockRoot.closing ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: chrome.lockRoot.closing ? 140 : 620; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: chrome.inset
        color: "transparent"
        border.color: chrome.lockRoot.accent
        border.width: 1
        opacity: 0.14
    }

    Repeater {
        model: 4

        Item {
            required property int index

            readonly property bool alignRight: index % 2 === 1
            readonly property bool alignBottom: index > 1

            width: 26
            height: 26
            x: alignRight ? chrome.width - chrome.inset - width : chrome.inset
            y: alignBottom ? chrome.height - chrome.inset - height : chrome.inset

            Rectangle {
                width: parent.width
                height: 1
                y: alignBottom ? parent.height - 1 : 0
                color: chrome.lockRoot.accent
                opacity: 0.7
            }

            Rectangle {
                width: 1
                height: parent.height
                x: alignRight ? parent.width - 1 : 0
                color: chrome.lockRoot.accent
                opacity: 0.7
            }
        }
    }

    Item {
        id: topRail

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: chrome.inset
        anchors.rightMargin: chrome.inset
        anchors.topMargin: chrome.inset
        height: 26

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: chrome.lockRoot.accent
            opacity: 0.16
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9

            Rectangle {
                width: 17
                height: 17
                color: chrome.lockRoot.accent
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "守"
                    color: chrome.lockRoot.background
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Text {
                text: "OMI SHELL"
                color: chrome.lockRoot.foreground
                font.pixelSize: 9
                font.letterSpacing: 3
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "// LOCKED"
                color: chrome.lockRoot.accent
                font.family: "monospace"
                font.pixelSize: 9
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: chrome.lockRoot.railDateText
            color: chrome.lockRoot.muted
            font.family: "monospace"
            font.pixelSize: 9
            font.letterSpacing: 1
        }
    }

    Item {
        id: bottomRail

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: chrome.inset
        anchors.rightMargin: chrome.inset
        anchors.bottomMargin: chrome.inset
        height: 24

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: chrome.lockRoot.accent
            opacity: 0.16
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "// " + chrome.lockRoot.powerText
            color: chrome.lockRoot.muted
            font.family: "monospace"
            font.pixelSize: 9
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 5
                height: 5
                color: chrome.lockRoot.failed ? chrome.lockRoot.alertColor : chrome.lockRoot.accent
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: chrome.lockRoot.unlockInProgress ? 240 : 1100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: chrome.lockRoot.unlockInProgress ? 240 : 1100; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: chrome.primary ? "INPUT DISPLAY" : "MIRROR DISPLAY"
                color: chrome.lockRoot.muted
                font.family: "monospace"
                font.pixelSize: 9
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: chrome.screenName + "  ·  " + chrome.lockRoot.timeText + ":" + chrome.lockRoot.secondsText
            color: chrome.lockRoot.muted
            font.family: "monospace"
            font.pixelSize: 9
            font.letterSpacing: 1
        }
    }
}

import QtQuick

Column {
    id: clock

    required property var lockRoot
    property int timeSize: 78
    property bool centered: false
    property real barWidth: 200

    spacing: 8

    Row {
        spacing: 10
        anchors.horizontalCenter: clock.centered ? parent.horizontalCenter : undefined

        Text {
            id: bigTime

            text: clock.lockRoot.timeText
            color: clock.lockRoot.foreground
            font.pixelSize: clock.timeSize
            font.weight: Font.Light
            font.letterSpacing: clock.timeSize * 0.02
        }

        Text {
            text: clock.lockRoot.secondsText
            color: clock.lockRoot.accent
            font.pixelSize: Math.round(clock.timeSize * 0.22)
            font.weight: Font.DemiBold
            font.letterSpacing: 2
            anchors.baseline: bigTime.baseline
        }
    }

    Row {
        spacing: 10
        anchors.horizontalCenter: clock.centered ? parent.horizontalCenter : undefined

        Text {
            text: clock.lockRoot.weekdayText
            color: clock.lockRoot.foreground
            font.pixelSize: 12
            font.letterSpacing: 5
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: clock.lockRoot.weekdayKanji
            color: clock.lockRoot.accent
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Text {
        text: clock.lockRoot.dateText
        color: clock.lockRoot.muted
        font.pixelSize: 11
        font.letterSpacing: 1.6
        anchors.horizontalCenter: clock.centered ? parent.horizontalCenter : undefined
    }

    Item {
        width: clock.barWidth
        height: 3
        anchors.horizontalCenter: clock.centered ? parent.horizontalCenter : undefined

        Rectangle {
            anchors.fill: parent
            color: clock.lockRoot.foreground
            opacity: 0.12
        }

        Rectangle {
            width: parent.width * clock.lockRoot.dayProgress
            height: parent.height
            color: clock.lockRoot.accent

            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        }
    }
}

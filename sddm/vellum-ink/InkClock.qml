import QtQuick

Column {
    id: clock

    required property var greeter
    property int timeSize: 78
    property bool centered: false
    property real barWidth: 200

    spacing: 8

    Row {
        spacing: 10
        anchors.horizontalCenter: clock.centered ? parent.horizontalCenter : undefined

        Text {
            id: bigTime

            text: clock.greeter.timeText
            color: clock.greeter.foreground
            font.pixelSize: clock.timeSize
            font.weight: Font.Light
            font.letterSpacing: clock.timeSize * 0.02
        }

        Text {
            text: clock.greeter.secondsText
            color: clock.greeter.accent
            font.pixelSize: Math.round(clock.timeSize * 0.22)
            font.weight: Font.DemiBold
            font.letterSpacing: 2
            anchors.baseline: bigTime.baseline
        }
    }

    Text {
        text: clock.greeter.weekdayText
        color: clock.greeter.foreground
        font.pixelSize: 12
        font.letterSpacing: 5
        font.bold: true
        anchors.horizontalCenter: clock.centered ? parent.horizontalCenter : undefined
    }

    Text {
        text: clock.greeter.dateText
        color: clock.greeter.muted
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
            color: clock.greeter.foreground
            opacity: 0.12
        }

        Rectangle {
            width: parent.width * clock.greeter.dayProgress
            height: parent.height
            color: clock.greeter.accent

            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        }
    }
}

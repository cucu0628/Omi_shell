import QtQuick
import "../../ui" as SharedUi

SharedUi.DashPanel {
    id: card

    property int cpuUsage: 0
    property int ramUsage: 0
    property int diskUsage: 0

    readonly property color lineBg: Qt.rgba(1, 1, 1, 0.055)

    title: "SYSTEM"
    kanji: "状態"
    trailing: "LIVE"

    Row {
        anchors.fill: parent
        spacing: 10

        Repeater {
            model: [
                { label: "CPU", value: card.cpuUsage },
                { label: "RAM", value: card.ramUsage },
                { label: "DISK", value: card.diskUsage }
            ]

            Item {
                width: (parent.width - 20) / 3
                height: parent.height

                Text {
                    id: valueText
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.value + "%"
                    color: card.foreground
                    font.pixelSize: 18
                    font.weight: Font.Light
                }

                Text {
                    id: labelText
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.label
                    color: card.muted
                    font.pixelSize: 9
                    font.letterSpacing: 2
                }

                Rectangle {
                    id: meterTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: valueText.bottom
                    anchors.bottom: labelText.top
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    color: card.background
                    border.color: card.lineBg
                    border.width: 1
                    clip: true

                    Repeater {
                        model: 3

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            y: meterTrack.height * (index + 1) / 4
                            height: 1
                            color: card.lineBg
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 1
                        height: Math.max(0, (meterTrack.height - 2) * Math.max(0, Math.min(100, modelData.value)) / 100)
                        color: card.accent
                        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}

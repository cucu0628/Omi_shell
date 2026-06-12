import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: calendarWindow

    property var theme: null
    property bool opened: false
    property var now: new Date()

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"
    readonly property string inkBg: "#1b1613"
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    onOpenedChanged: if (opened) now = new Date()

    function firstDayOffset() {
        var first = new Date(now.getFullYear(), now.getMonth(), 1).getDay()
        return first === 0 ? 6 : first - 1
    }

    function daysInMonth() {
        return new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    }

    function dayForCell(index) {
        return index - firstDayOffset() + 1
    }

    function isToday(day) {
        var today = new Date()
        return day === today.getDate() && now.getMonth() === today.getMonth() && now.getFullYear() === today.getFullYear()
    }

    visible: opened || content.opacity > 0
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.calendar"
    WlrLayershell.exclusiveZone: -1

    MouseArea { anchors.fill: parent; onClicked: opened = false }

    Item {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        y: 32
        width: 340
        height: opened ? 312 : 0
        clip: true
        opacity: opened ? 1 : 0
        Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 2
            radius: 0
            clip: true

            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Row {
                    width: parent.width
                    height: 42
                    spacing: 12

                    Rectangle { width: 3; height: parent.height; color: panelAccent }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text { text: "KOYOMI"; color: panelAccent; font.pixelSize: 9; font.letterSpacing: 4; font.bold: true }
                        Text { text: monthNames[now.getMonth()] + " " + now.getFullYear(); color: panelFg; font.pixelSize: 21; font.weight: Font.DemiBold }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: panelAccent; opacity: 0.45 }

                Grid {
                    width: parent.width
                    columns: 7
                    rowSpacing: 8
                    columnSpacing: 6

                    Repeater {
                        model: dayNames
                        Text {
                            width: (parent.width - 36) / 7
                            height: 18
                            text: modelData
                            color: mutedFg
                            font.pixelSize: 10
                            font.letterSpacing: 1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 7
                    rowSpacing: 6
                    columnSpacing: 6

                    Repeater {
                        model: 42
                        Rectangle {
                            property int day: dayForCell(index)
                            property bool activeDay: day > 0 && day <= daysInMonth()
                            property bool today: activeDay && isToday(day)

                            width: (parent.width - 36) / 7
                            height: 28
                            color: today ? panelAccent : (activeDay ? inkBg : "transparent")
                            border.color: activeDay && !today ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                            border.width: activeDay && !today ? 1 : 0
                            radius: 0

                            Text {
                                anchors.centerIn: parent
                                text: parent.activeDay ? parent.day.toString() : ""
                                color: parent.today ? panelBg : panelFg
                                opacity: parent.activeDay ? 1 : 0
                                font.pixelSize: 12
                                font.weight: parent.today ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../ui" as SharedUi

PanelWindow {
    id: calendarWindow

    property var theme: null
    property bool opened: false
    property var now: new Date()

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#1b1613"
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    onOpenedChanged: if (opened) now = new Date()

    visible: opened || content.opacity > 0
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.calendar"
    WlrLayershell.exclusiveZone: -1

    MouseArea { anchors.fill: parent; enabled: opened; onClicked: opened = false }

    Item {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: opened
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

                SharedUi.CalendarGrid {
                    width: parent.width
                    displayedDate: calendarWindow.now
                    dayNames: calendarWindow.dayNames
                    foreground: panelFg
                    muted: mutedFg
                    accent: panelAccent
                    todayForeground: panelBg
                    activeBackground: inkBg
                    activeBorder: Qt.rgba(1, 1, 1, 0.06)
                    sectionSpacing: 14
                }
            }
        }
    }
}

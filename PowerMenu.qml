import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: powerWindow

    property var theme: null
    property bool opened: false
    property int selectedIndex: 0
    property int confirmIndex: -1

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"
    readonly property string inkBg: "#1b1613"
    readonly property var actions: [
        { name: "Lock", label: "MAMORU", sub: "守る / quiet screen", icon: "", command: "uwsm-app -- quickshell --path ~/.config/quickshell/LockShell.qml", confirm: false },
        { name: "Suspend", label: "NEMURU", sub: "眠る / sleep now", icon: "󰒲", command: "systemctl suspend", confirm: true },
        { name: "Logout", label: "HANARERU", sub: "離れる / leave session", icon: "󰍃", command: "omarchy-system-logout", confirm: true },
        { name: "Reboot", label: "MEZAMERU", sub: "目覚める / restart", icon: "󰜉", command: "omarchy-system-reboot", confirm: true },
        { name: "Shutdown", label: "SHIMAI", sub: "仕舞い / power off", icon: "󰐥", command: "omarchy-system-shutdown", confirm: true }
    ]

    onOpenedChanged: {
        if (opened) {
            selectedIndex = 0
            confirmIndex = -1
            focusTimer.start()
        }
    }

    function shellCommand(command) {
        return ["sh", "-c", command]
    }

    function activate(index) {
        if (index < 0 || index >= actions.length) return
        if (actions[index].confirm && confirmIndex !== index) {
            confirmIndex = index
            confirmTimer.restart()
            return
        }
        actionRunner.command = shellCommand(actions[index].command)
        actionRunner.running = true
        confirmIndex = -1
        opened = false
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            opened = false
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers === Qt.ControlModifier)) {
            selectedIndex = Math.min(selectedIndex + 1, actions.length - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers === Qt.ControlModifier)) {
            selectedIndex = Math.max(selectedIndex - 1, 0)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activate(selectedIndex)
            event.accepted = true
        }
    }

    visible: opened || content.opacity > 0
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.power-menu"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? 1 : 0

    Process { id: actionRunner }
    Timer { id: focusTimer; interval: 60; onTriggered: content.forceActiveFocus() }
    Timer { id: confirmTimer; interval: 2200; onTriggered: confirmIndex = -1 }

    MouseArea { anchors.fill: parent; onClicked: opened = false }

    Item {
        id: content
        anchors.centerIn: parent
        width: Math.min(920, powerWindow.width - 56)
        height: Math.min(360, powerWindow.height - 60)
        opacity: opened ? 1 : 0
        scale: opened ? 1 : 0.98
        focus: opened
        Keys.onPressed: (event) => handleKey(event)
        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 2
            radius: 0
            clip: true

            Rectangle { width: 260; height: 260; radius: 130; x: parent.width - 120; y: -130; color: panelAccent; opacity: 0.10 }
            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 18

                Row {
                    width: parent.width
                    height: 54
                    spacing: 14

                    Rectangle { width: 4; height: parent.height; color: panelAccent }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text { text: "DENRYOKU"; color: panelAccent; font.pixelSize: 10; font.letterSpacing: 5; font.bold: true }
                        Text { text: "Power Ritual"; color: panelFg; font.pixelSize: 26; font.weight: Font.DemiBold }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: confirmIndex >= 0 ? "Press Enter again to confirm" : "Enter selects / Esc cancels"
                        color: mutedFg
                        font.pixelSize: 12
                    }
                }

                Rectangle { width: parent.width; height: 1; color: panelAccent; opacity: 0.45 }

                Row {
                    width: parent.width
                    height: parent.height - 82
                    spacing: 12

                    Repeater {
                        model: actions
                        Rectangle {
                            width: (parent.width - 48) / 5
                            height: parent.height
                            color: confirmIndex === index ? panelAccent : (actionMouse.containsMouse || index === selectedIndex ? inkBg : "transparent")
                            border.color: index === selectedIndex || confirmIndex === index ? panelAccent : mutedFg
                            border.width: index === selectedIndex || confirmIndex === index ? 2 : 1
                            radius: 0

                            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 4; color: panelAccent; opacity: actionMouse.containsMouse || index === selectedIndex ? 1 : 0.25 }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Text {
                                    text: modelData.icon
                                    color: confirmIndex === index ? panelBg : (actionMouse.containsMouse || index === selectedIndex ? panelAccent : panelFg)
                                    font.pixelSize: 28
                                }

                                Text {
                                    text: modelData.label
                                    color: confirmIndex === index ? panelBg : panelFg
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: modelData.name
                                    color: confirmIndex === index ? panelBg : panelAccent
                                    font.pixelSize: 11
                                    font.letterSpacing: 2
                                    font.bold: true
                                }

                                Text {
                                    text: confirmIndex === index ? "Press again within 2.2s" : modelData.sub
                                    color: confirmIndex === index ? panelBg : mutedFg
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: selectedIndex = index
                                onClicked: activate(index)
                            }
                        }
                    }
                }
            }
        }
    }
}

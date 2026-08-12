import "." as PowerUi
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: powerWindow

    property var theme: null
    property bool opened: false
    property int selectedIndex: 0
    property int confirmIndex: -1
    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#1b1613"
    readonly property var actions: [{
        "name": "Lock",
        "label": "MAMORU",
        "sub": "守る / quiet screen",
        "icon": "",
        "command": "quickshell ipc --path ~/.config/quickshell/omi_shell/shell.qml call lock lock",
        "confirm": false
    }, {
        "name": "Suspend",
        "label": "NEMURU",
        "sub": "眠る / sleep now",
        "icon": "󰒲",
        "command": "systemctl suspend",
        "confirm": true
    }, {
        "name": "Logout",
        "label": "HANARERU",
        "sub": "離れる / leave session",
        "icon": "󰍃",
        "command": "hyprctl dispatch 'hl.dsp.exit()'",
        "confirm": true
    }, {
        "name": "Reboot",
        "label": "MEZAMERU",
        "sub": "目覚める / restart",
        "icon": "󰜉",
        "command": "systemctl reboot",
        "confirm": true
    }, {
        "name": "Shutdown",
        "label": "SHIMAI",
        "sub": "仕舞い / power off",
        "icon": "󰐥",
        "command": "systemctl poweroff",
        "confirm": true
    }]

    function shellCommand(command) {
        return ["sh", "-c", command];
    }

    function activate(index) {
        if (index < 0 || index >= actions.length)
            return ;

        if (actions[index].confirm && confirmIndex !== index) {
            confirmIndex = index;
            confirmTimer.restart();
            return ;
        }
        actionRunner.command = shellCommand(actions[index].command);
        actionRunner.running = true;
        confirmIndex = -1;
        opened = false;
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            opened = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers === Qt.ControlModifier)) {
            selectedIndex = Math.min(selectedIndex + 1, actions.length - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers === Qt.ControlModifier)) {
            selectedIndex = Math.max(selectedIndex - 1, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activate(selectedIndex);
            event.accepted = true;
        }
    }

    onOpenedChanged: {
        if (opened) {
            selectedIndex = 0;
            confirmIndex = -1;
            focusTimer.start();
        }
    }
    onSelectedIndexChanged: {
        if (confirmIndex !== selectedIndex)
            confirmIndex = -1;

    }
    visible: opened || content.opacity > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.power-menu"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? 1 : 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Process {
        id: actionRunner
    }

    Timer {
        id: focusTimer

        interval: 60
        onTriggered: content.forceActiveFocus()
    }

    Timer {
        id: confirmTimer

        interval: 2200
        onTriggered: confirmIndex = -1
    }

    MouseArea {
        anchors.fill: parent
        enabled: opened
        onClicked: opened = false
    }

    Item {
        id: content

        anchors.centerIn: parent
        enabled: opened
        width: Math.min(620, powerWindow.width - 32)
        height: Math.min(340, powerWindow.height - 40)
        opacity: opened ? 1 : 0
        scale: opened ? 1 : 0.96
        transform: Translate {
            y: powerWindow.opened ? 0 : 12

            Behavior on y {
                NumberAnimation {
                    duration: powerWindow.opened ? 240 : 120
                    easing.type: powerWindow.opened ? Easing.OutQuart : Easing.InQuad
                }
            }
        }
        focus: opened
        Keys.onPressed: (event) => {
            return handleKey(event);
        }

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 1
            radius: 0
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => {
                    return mouse.accepted = true;
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Row {
                    width: parent.width
                    height: 36
                    spacing: 10

                    Rectangle {
                        width: 36
                        height: 36
                        color: panelAccent

                        Text {
                            anchors.centerIn: parent
                            text: "電"
                            color: panelBg
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                    }

                    Column {
                        width: parent.width - 286
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "SESSION CONTROL"
                            color: panelFg
                            font.pixelSize: 12
                            font.letterSpacing: 3
                            font.bold: true
                        }

                        Text {
                            text: "電源メニュー  /  komorebi power"
                            color: mutedFg
                            font.pixelSize: 9
                        }

                    }

                    Text {
                        width: 240
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: confirmIndex >= 0 ? "ENTER AGAIN TO CONFIRM" : "↑↓  MOVE    ENTER  SELECT    ESC  CLOSE"
                        color: confirmIndex >= 0 ? panelAccent : mutedFg
                        font.family: "monospace"
                        font.pixelSize: 8
                    }

                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: mutedFg
                    opacity: 0.35
                }

                Column {
                    width: parent.width
                    height: parent.height - 67
                    spacing: 5

                    Repeater {
                        model: actions

                        PowerUi.PowerActionCard {
                            width: parent.width
                            height: (parent.height - 20) / 5
                            theme: powerWindow.theme
                            actionData: modelData
                            actionIndex: index
                            selected: index === selectedIndex
                            confirming: confirmIndex === index
                            onHovered: selectedIndex = index
                            onActivated: activate(index)
                        }

                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: powerWindow.opened ? 160 : 110
                easing.type: powerWindow.opened ? Easing.OutQuart : Easing.InQuad
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: powerWindow.opened ? 260 : 130
                easing.type: powerWindow.opened ? Easing.OutQuart : Easing.InQuad
            }

        }

    }

}

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: trayMenu

    property var theme: null
    property int barHeight: 26
    property var menuModel: null
    property int menuX: 0

    visible: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.menu"
    WlrLayershell.exclusiveZone: -1

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"

    MouseArea { anchors.fill: parent; onClicked: trayMenu.visible = false }

    Item {
        x: Math.max(10, Math.min(trayMenu.width - width - 10, trayMenu.menuX - width / 2 + 8))
        y: trayMenu.barHeight
        width: 260
        height: menuColumn.implicitHeight + 18
        clip: true

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: -2
            color: panelBg
            border.color: panelAccent
            border.width: 1
            radius: 0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 2
                color: panelAccent
                opacity: 0.9
            }

            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Column {
                id: menuColumn
                anchors { fill: parent; margins: 9; topMargin: 12 }
                spacing: 3

                Repeater {
                    model: trayMenu.menuModel

                    Rectangle {
                        width: parent.width
                        height: modelData.isSeparator ? 9 : 31
                        color: !modelData.isSeparator && itemMouse.containsMouse ? panelAccent : "transparent"
                        radius: 0
                        opacity: modelData.enabled === false ? 0.45 : 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            visible: !modelData.isSeparator
                            width: 3
                            height: parent.height
                            anchors.left: parent.left
                            color: itemMouse.containsMouse ? panelBg : panelAccent
                            opacity: itemMouse.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        Rectangle {
                            visible: modelData.isSeparator
                            width: parent.width - 10
                            height: 1
                            color: panelAccent
                            opacity: 0.35
                            anchors.centerIn: parent
                        }

                        Text {
                            visible: !modelData.isSeparator
                            text: modelData.text ? modelData.text.replace(/&/g, "") : ""
                            color: itemMouse.containsMouse ? panelBg : panelFg
                            font.pixelSize: 12
                            font.weight: itemMouse.containsMouse ? Font.DemiBold : Font.Normal
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            elide: Text.ElideRight
                            width: parent.width - 24
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: modelData.isSeparator || modelData.enabled === false ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (!modelData.isSeparator && modelData.enabled !== false) {
                                    modelData.triggered()
                                    trayMenu.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland

// Names whoever is holding the microphone or the camera. It sits on the left
// edge because the indicator that opens it lives next to the workspaces, and it
// closes itself once the last capture ends, so it never outlives its own icon.
PanelWindow {
    id: privacyWindow

    property var theme: null
    property var statusController: null
    property bool opened: false

    readonly property var micUsers: statusController ? statusController.micUsers : []
    readonly property var cameraUsers: statusController ? statusController.cameraUsers : []
    readonly property bool anyActive: micUsers.length > 0 || cameraUsers.length > 0
    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#1b1613"

    onAnyActiveChanged: if (!anyActive) opened = false

    visible: opened || content.opacity > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.privacy"
    WlrLayershell.exclusiveZone: -1

    anchors { top: true; bottom: true; left: true; right: true }

    MouseArea {
        anchors.fill: parent
        enabled: privacyWindow.opened
        onClicked: privacyWindow.opened = false
    }

    Item {
        id: content
        anchors.left: parent.left
        anchors.leftMargin: 10
        enabled: privacyWindow.opened
        y: 32
        width: Math.min(340, parent.width - 20)
        height: privacyWindow.opened ? Math.min(panel.implicitHeight + 32, parent.height - 46) : 0
        clip: true
        opacity: privacyWindow.opened ? 1 : 0

        Rectangle {
            anchors.fill: parent
            color: privacyWindow.panelBg
            border.color: privacyWindow.panelAccent
            border.width: 1
            clip: true

            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }

            Column {
                id: panel
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    width: parent.width
                    height: 36
                    spacing: 10

                    Rectangle {
                        width: 36
                        height: 36
                        color: privacyWindow.panelAccent
                        Text {
                            anchors.centerIn: parent
                            text: "󰈈"
                            color: privacyWindow.panelBg
                            font.family: "Symbols Nerd Font Mono"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        width: parent.width - 46
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            width: parent.width
                            text: "PRIVACY"
                            color: privacyWindow.panelFg
                            font.pixelSize: 12
                            font.letterSpacing: 3
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: "Live microphone and camera access"
                            color: privacyWindow.mutedFg
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }
                }

                Repeater {
                    model: [
                        { "title": "MICROPHONE", "icon": "󰍬", "users": privacyWindow.micUsers },
                        { "title": "CAMERA", "icon": "󰄀", "users": privacyWindow.cameraUsers }
                    ]

                    delegate: Rectangle {
                        id: sectionCard

                        required property var modelData
                        readonly property var users: modelData.users || []

                        width: parent.width
                        height: sectionColumn.implicitHeight + 24
                        color: privacyWindow.inkBg
                        border.color: Qt.rgba(1, 1, 1, 0.07)

                        Rectangle {
                            anchors.left: parent.left
                            width: 3
                            height: parent.height
                            color: sectionCard.users.length > 0 ? privacyWindow.panelAccent : privacyWindow.mutedFg
                        }

                        Column {
                            id: sectionColumn
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 14
                            anchors.topMargin: 12
                            anchors.bottomMargin: 12
                            spacing: 9

                            Row {
                                width: parent.width
                                height: 18
                                spacing: 8

                                Text {
                                    text: sectionCard.modelData.icon
                                    color: sectionCard.users.length > 0 ? privacyWindow.panelAccent : privacyWindow.mutedFg
                                    font.family: "Symbols Nerd Font Mono"
                                    font.pixelSize: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    width: parent.width - 90
                                    height: parent.height
                                    text: sectionCard.modelData.title
                                    color: privacyWindow.panelFg
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 2
                                }
                                Text {
                                    width: 58
                                    height: parent.height
                                    text: sectionCard.users.length > 0 ? "IN USE" : "IDLE"
                                    color: sectionCard.users.length > 0 ? privacyWindow.panelAccent : privacyWindow.mutedFg
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: "monospace"
                                    font.pixelSize: 9
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: privacyWindow.panelAccent
                                opacity: 0.18
                            }

                            Repeater {
                                model: sectionCard.users

                                delegate: Column {
                                    required property var modelData

                                    width: parent.width
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: modelData.app
                                        color: privacyWindow.panelFg
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        visible: (modelData.device || "") !== ""
                                        text: modelData.device
                                        color: privacyWindow.mutedFg
                                        font.family: "monospace"
                                        font.pixelSize: 8
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                visible: sectionCard.users.length === 0
                                text: "Nothing is using it right now"
                                color: privacyWindow.mutedFg
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }

        Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
}

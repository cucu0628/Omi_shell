import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland

PanelWindow {
    id: window

    property var theme: null
    property var screenProvider: null
    property string response: ""

    readonly property var flow: agent.flow
    readonly property bool opened: agent.isActive && flow !== null
    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#1b1613"
    readonly property string errorColor: "#d7472f"

    function focusInput() {
        if (opened && flow && flow.isResponseRequired) responseInput.forceActiveFocus()
    }

    function submit() {
        if (!flow || !flow.isResponseRequired || response === "") return
        var value = response
        response = ""
        flow.submit(value)
    }

    function cancel() {
        if (flow) flow.cancelAuthenticationRequest()
        response = ""
    }

    visible: opened
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.polkit-agent"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? 1 : 0

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            window.response = ""
            if (window.screenProvider) window.screen = window.screenProvider()
            focusTimer.restart()
        }
    }

    Connections {
        target: window.flow
        enabled: window.flow !== null
        ignoreUnknownSignals: true

        function onAuthenticationFailed() {
            window.response = ""
            focusTimer.restart()
        }

        function onIsResponseRequiredChanged() {
            if (window.flow && window.flow.isResponseRequired) focusTimer.restart()
        }
    }

    onOpenedChanged: {
        if (opened) focusTimer.restart()
        else response = ""
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: window.focusInput()
    }

    MouseArea {
        anchors.fill: parent
        enabled: window.opened
        onClicked: window.cancel()
    }

    Item {
        id: content
        anchors.centerIn: parent
        width: Math.min(560, window.width - 36)
        height: Math.min(card.implicitHeight, window.height - 36)
        focus: window.opened

        Keys.onEscapePressed: window.cancel()

        Rectangle {
            id: card
            width: parent.width
            implicitHeight: body.implicitHeight + 48
            color: window.panelBg
            border.color: window.flow && window.flow.failed ? window.errorColor : window.panelAccent
            border.width: 2
            clip: true

            Rectangle {
                width: 220
                height: 220
                radius: 110
                x: parent.width - 105
                y: -125
                color: window.panelAccent
                opacity: 0.09
            }

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => mouse.accepted = true
            }

            Column {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 16

                Row {
                    width: parent.width
                    spacing: 14

                    Rectangle {
                        width: 48
                        height: 48
                        color: window.inkBg
                        border.color: window.panelAccent
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰌾"
                            color: window.panelAccent
                            font.family: "Symbols Nerd Font Mono"
                            font.pixelSize: 23
                        }
                    }

                    Column {
                        width: parent.width - 62
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: "KENGEN"
                            color: window.panelAccent
                            font.pixelSize: 10
                            font.letterSpacing: 5
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: "Authentication required"
                            color: window.panelFg
                            font.pixelSize: 23
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: window.panelAccent
                    opacity: 0.42
                }

                Text {
                    width: parent.width
                    text: window.flow ? window.flow.message : ""
                    color: window.panelFg
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                }

                Text {
                    width: parent.width
                    visible: window.flow && window.flow.actionId !== ""
                    text: window.flow ? "// " + window.flow.actionId : ""
                    color: window.mutedFg
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                }

                Column {
                    width: parent.width
                    visible: window.flow && window.flow.identities.length > 1
                    spacing: 7

                    Text {
                        text: "AUTHENTICATE AS"
                        color: window.mutedFg
                        font.pixelSize: 10
                        font.letterSpacing: 2
                        font.bold: true
                    }

                    Repeater {
                        model: window.flow ? window.flow.identities : []

                        Rectangle {
                            required property var modelData

                            width: body.width
                            height: 38
                            color: window.flow && window.flow.selectedIdentity === modelData ? Qt.rgba(window.panelAccent.r, window.panelAccent.g, window.panelAccent.b, 0.16) : window.inkBg
                            border.color: window.flow && window.flow.selectedIdentity === modelData ? window.panelAccent : Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.displayName + "  //  " + modelData.string
                                color: window.panelFg
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    window.response = ""
                                    window.flow.selectedIdentity = modelData
                                    focusTimer.restart()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 52
                    visible: window.flow && window.flow.isResponseRequired
                    color: window.inkBg
                    border.color: window.flow && window.flow.failed ? window.errorColor : window.panelAccent
                    border.width: window.flow && window.flow.failed ? 2 : 1

                    Rectangle {
                        width: 3
                        height: parent.height
                        color: window.flow && window.flow.failed ? window.errorColor : window.panelAccent
                    }

                    TextInput {
                        id: responseInput
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height - 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: window.panelFg
                        font.pixelSize: 15
                        echoMode: window.flow && window.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        inputMethodHints: window.flow && window.flow.responseVisible ? Qt.ImhNone : Qt.ImhSensitiveData
                        text: window.response
                        onTextChanged: window.response = text
                        onAccepted: window.submit()

                        Text {
                            anchors.fill: parent
                            visible: parent.text === ""
                            text: window.flow && window.flow.inputPrompt !== "" ? window.flow.inputPrompt : "Password"
                            color: window.mutedFg
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: window.flow && window.flow.supplementaryMessage !== ""
                    text: window.flow ? "// " + window.flow.supplementaryMessage : ""
                    color: window.flow && window.flow.supplementaryIsError ? window.errorColor : window.mutedFg
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }

                Row {
                    anchors.right: parent.right
                    spacing: 10

                    Rectangle {
                        width: 104
                        height: 38
                        color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        border.color: window.mutedFg
                        border.width: 1

                        Text { anchors.centerIn: parent; text: "Cancel"; color: window.panelFg; font.pixelSize: 12 }
                        MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: true; onClicked: window.cancel() }
                    }

                    Rectangle {
                        width: 126
                        height: 38
                        opacity: window.response !== "" ? 1 : 0.45
                        color: submitMouse.containsMouse && window.response !== "" ? Qt.lighter(window.panelAccent, 1.12) : window.panelAccent

                        Text { anchors.centerIn: parent; text: "Authenticate"; color: window.panelBg; font.pixelSize: 12; font.bold: true }
                        MouseArea { id: submitMouse; anchors.fill: parent; enabled: window.response !== ""; hoverEnabled: true; onClicked: window.submit() }
                    }
                }
            }
        }
    }
}

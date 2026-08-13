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
    readonly property bool failed: flow !== null && flow.failed
    readonly property string panelBg: theme ? theme.background : "#11130f"
    readonly property string panelFg: theme ? theme.foreground : "#e8ddc7"
    readonly property string panelAccent: theme ? theme.accent : "#b7372f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#958b7a"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#191b16"
    readonly property string errorColor: "#d7472f"
    readonly property color hoverBg: Qt.rgba(1, 1, 1, 0.075)
    readonly property color lineBg: Qt.rgba(1, 1, 1, 0.055)
    readonly property color frameColor: failed ? errorColor : panelAccent

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

    Rectangle {
        anchors.fill: parent
        color: window.panelBg
        opacity: 0.72
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
            implicitHeight: header.height + 12 + 1 + 12 + body.implicitHeight + 32
            color: window.panelBg
            border.color: window.frameColor
            border.width: 1
            radius: 0
            clip: true
            Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => mouse.accepted = true
            }

            Item {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 16
                height: 44

                Rectangle {
                    id: headerSeal
                    width: 44
                    height: 44
                    color: window.frameColor
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰌾"
                        color: window.panelBg
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }
                }

                Column {
                    anchors.left: headerSeal.right
                    anchors.leftMargin: 12
                    anchors.right: headerState.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "AUTHENTICATION"
                        color: window.panelFg
                        font.pixelSize: 12
                        font.letterSpacing: 3
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: "Polkit authorization agent"
                        color: window.mutedFg
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: headerState
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: window.failed ? "DENIED" : "REQUIRED"
                    color: window.frameColor
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    font.bold: true
                }
            }

            Rectangle {
                id: headerRule
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 12
                height: 1
                color: window.mutedFg
                opacity: 0.35
            }

            Column {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: headerRule.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 12
                spacing: 14

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
                    text: window.flow ? window.flow.actionId : ""
                    color: window.mutedFg
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    elide: Text.ElideMiddle
                }

                Column {
                    width: parent.width
                    visible: window.flow && window.flow.identities.length > 1
                    spacing: 6

                    Text {
                        text: "AUTHENTICATE AS"
                        color: window.panelAccent
                        font.pixelSize: 9
                        font.letterSpacing: 2
                        font.bold: true
                    }

                    Repeater {
                        model: window.flow ? window.flow.identities : []

                        Rectangle {
                            id: identityRow
                            required property var modelData
                            readonly property bool current: window.flow && window.flow.selectedIdentity === modelData

                            width: body.width
                            height: 36
                            radius: 0
                            color: identityRow.current
                                ? window.inkBg
                                : (identityMouse.containsMouse ? window.hoverBg : window.panelBg)
                            border.color: identityRow.current ? window.panelAccent : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 110; easing.type: Easing.OutCubic } }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 2
                                color: window.panelAccent
                                opacity: identityRow.current ? 1 : 0.35
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 13
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: identityRow.modelData.displayName + "  ·  " + identityRow.modelData.string
                                color: identityRow.current ? window.panelAccent : window.panelFg
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: identityMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.response = ""
                                    window.flow.selectedIdentity = identityRow.modelData
                                    focusTimer.restart()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 46
                    visible: window.flow && window.flow.isResponseRequired
                    radius: 0
                    color: window.inkBg
                    border.color: window.failed
                        ? window.errorColor
                        : (responseInput.activeFocus ? window.panelAccent : window.lineBg)
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: window.frameColor
                    }

                    TextInput {
                        id: responseInput
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height - 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: window.panelFg
                        font.pixelSize: 14
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
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: window.flow && window.flow.supplementaryMessage !== ""
                    text: window.flow ? window.flow.supplementaryMessage : ""
                    color: window.flow && window.flow.supplementaryIsError ? window.errorColor : window.mutedFg
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }

                Item {
                    width: parent.width
                    height: 40

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ESC  cancel      ↵  submit"
                        color: window.mutedFg
                        opacity: 0.72
                        font.pixelSize: 9
                        font.letterSpacing: 1
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            width: 104
                            height: 40
                            radius: 0
                            color: cancelMouse.containsMouse ? window.hoverBg : "transparent"
                            border.color: window.lineBg
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "CANCEL"
                                color: window.panelFg
                                font.pixelSize: 9
                                font.letterSpacing: 2
                                font.bold: true
                            }

                            MouseArea {
                                id: cancelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.cancel()
                            }
                        }

                        Rectangle {
                            width: 134
                            height: 40
                            radius: 0
                            opacity: window.response !== "" ? 1 : 0.45
                            color: submitMouse.containsMouse && window.response !== ""
                                ? Qt.lighter(window.panelAccent, 1.15)
                                : window.panelAccent
                            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                text: "AUTHENTICATE"
                                color: window.panelBg
                                font.pixelSize: 9
                                font.letterSpacing: 2
                                font.bold: true
                            }

                            MouseArea {
                                id: submitMouse
                                anchors.fill: parent
                                enabled: window.response !== ""
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.submit()
                            }
                        }
                    }
                }
            }
        }
    }
}

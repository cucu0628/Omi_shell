import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: aiWindow

    property var theme: null
    property bool opened: false
    property bool refreshing: false
    property var claude: emptyProvider("claude", "Claude Code")
    property var codex: emptyProvider("codex", "Codex")
    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#1b1613"

    function emptyProvider(id, name) {
        return { "id": id, "name": name, "plan": "", "ready": false, "status": "Not loaded", "limits": [] }
    }

    function refresh(force) {
        if (claudeProcess.running || codexProcess.running)
            return
        refreshing = true
        claudeProcess.command = [Quickshell.env("HOME") + "/.config/quickshell/vellum_shell/scripts/ai-usage-claude"]
        codexProcess.command = [Quickshell.env("HOME") + "/.config/quickshell/vellum_shell/scripts/ai-usage-codex"]
        if (force) {
            claudeProcess.command.push("--force")
            codexProcess.command.push("--force")
        }
        claudeProcess.running = true
        codexProcess.running = true
    }

    function parseProvider(text, fallback) {
        try {
            return JSON.parse((text || "").trim())
        } catch (error) {
            return { "id": fallback.id, "name": fallback.name, "plan": "", "ready": false, "status": "Invalid usage response", "limits": [] }
        }
    }

    function processFinished() {
        refreshing = claudeProcess.running || codexProcess.running
    }

    function percent(value) {
        return Math.round(Math.max(0, Math.min(1, Number(value) || 0)) * 100)
    }

    function resetText(value) {
        if (!value)
            return "Reset time unavailable"
        var date = new Date(value)
        if (isNaN(date.getTime()))
            return "Reset " + value
        return "Resets " + Qt.formatDateTime(date, "MMM d, HH:mm")
    }

    function providerHeight(provider) {
        var count = Math.min(2, (provider.limits || []).length)
        return count > 0 ? 58 + count * 63 : 104
    }

    readonly property real panelContentHeight: 110 + providerHeight(claude) + providerHeight(codex)

    onOpenedChanged: if (opened) refresh(false)
    visible: opened || content.opacity > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.ai-usage"
    WlrLayershell.exclusiveZone: -1

    anchors { top: true; bottom: true; left: true; right: true }

    MouseArea {
        anchors.fill: parent
        enabled: opened
        onClicked: opened = false
    }

    Item {
        id: content
        anchors.right: parent.right
        anchors.rightMargin: 10
        enabled: opened
        y: 32
        width: Math.min(430, parent.width - 20)
        height: opened ? Math.min(panelContentHeight, parent.height - 46) : 0
        clip: true
        opacity: opened ? 1 : 0

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 1
            clip: true

            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }

            Column {
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
                        color: panelAccent
                        Text {
                            anchors.centerIn: parent
                            text: "󰚩"
                            color: panelBg
                            font.family: "Symbols Nerd Font Mono"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        width: parent.width - 116
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            width: parent.width
                            text: "AI ALLOWANCES"
                            color: panelFg
                            font.pixelSize: 12
                            font.letterSpacing: 3
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: refreshing ? "Updating provider limits..." : "Subscription windows and reset times"
                            color: mutedFg
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        width: 70
                        height: parent.height
                        text: refreshing ? "WAIT" : "Refresh"
                        color: refreshMouse.containsMouse && !refreshing ? panelAccent : mutedFg
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        font.family: "monospace"
                        font.pixelSize: 10
                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            enabled: !refreshing
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: refresh(true)
                        }
                    }
                }

                Repeater {
                    model: 2
                    delegate: Rectangle {
                        id: providerCard

                        required property int index
                        readonly property var provider: index === 0 ? aiWindow.claude : aiWindow.codex
                        width: parent.width
                        height: aiWindow.providerHeight(provider)
                        color: inkBg
                        border.color: Qt.rgba(1, 1, 1, 0.07)

                        Rectangle {
                            anchors.left: parent.left
                            width: 3
                            height: parent.height
                            color: providerCard.provider.ready ? panelAccent : mutedFg
                        }

                        Column {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 14
                            anchors.topMargin: 12
                            anchors.bottomMargin: 12
                            spacing: 9

                            Row {
                                width: parent.width
                                height: 25
                                Text {
                                    width: parent.width - 130
                                    height: parent.height
                                    text: providerCard.provider.name.toUpperCase()
                                    color: panelFg
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 2
                                }
                                Text {
                                    width: 130
                                    height: parent.height
                                    text: providerCard.provider.plan ? String(providerCard.provider.plan).toUpperCase() : ""
                                    color: panelAccent
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: "monospace"
                                    font.pixelSize: 9
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: panelAccent
                                opacity: 0.18
                            }

                            Repeater {
                                model: (providerCard.provider.limits || []).slice(0, 2)
                                delegate: Column {
                                    id: usageRow

                                    required property var modelData
                                    property real displayedRemaining: 0
                                    property bool initialized: false
                                    readonly property real targetRemaining: Math.max(0, Math.min(1, Number(modelData.remaining) || 0))
                                    width: parent.width
                                    height: 53
                                    spacing: 4

                                    Component.onCompleted: {
                                        initialized = true
                                        fillAnimation.restart()
                                    }
                                    onTargetRemainingChanged: {
                                        if (initialized)
                                            fillAnimation.restart()
                                    }

                                    SequentialAnimation {
                                        id: fillAnimation

                                        PauseAnimation { duration: 100 }
                                        NumberAnimation {
                                            target: usageRow
                                            property: "displayedRemaining"
                                            from: 0
                                            to: usageRow.targetRemaining
                                            duration: 720
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        height: 16
                                        Text {
                                            width: parent.width - 80
                                            text: modelData.label || "Limit"
                                            color: mutedFg
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: 80
                                            text: percent(modelData.remaining) + "% left"
                                            color: panelFg
                                            horizontalAlignment: Text.AlignRight
                                            font.family: "monospace"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: 5
                                        color: panelBg
                                        border.color: Qt.rgba(1, 1, 1, 0.12)
                                        border.width: 1
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.margins: 1
                                            width: Math.max(0, (parent.width - 2) * usageRow.displayedRemaining)
                                            color: panelAccent
                                        }
                                    }
                                    Text {
                                        width: parent.width
                                        text: percent(modelData.used) + "% used  ·  " + resetText(modelData.resetsAt)
                                        color: mutedFg
                                        font.family: "monospace"
                                        font.pixelSize: 8
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                height: 26
                                visible: !providerCard.provider.limits || providerCard.provider.limits.length === 0
                                text: providerCard.provider.status || "No limit data returned"
                                color: mutedFg
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 12
                    text: "Values are reported by Anthropic and the Codex app server."
                    color: mutedFg
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "monospace"
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }
        }

        Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    Process {
        id: claudeProcess
        stdout: StdioCollector { onStreamFinished: aiWindow.claude = aiWindow.parseProvider(text, aiWindow.emptyProvider("claude", "Claude Code")) }
        onExited: aiWindow.processFinished()
    }

    Process {
        id: codexProcess
        stdout: StdioCollector { onStreamFinished: aiWindow.codex = aiWindow.parseProvider(text, aiWindow.emptyProvider("codex", "Codex")) }
        onExited: aiWindow.processFinished()
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire

PanelWindow {
    id: audioWindow

    property var theme: null
    property bool opened: false
    property bool outputPickerOpen: false
    property bool inputPickerOpen: false

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"
    readonly property string inkBg: "#1b1613"
    readonly property string hoverBg: Qt.rgba(1, 1, 1, 0.075)

    readonly property var audioNodes: Pipewire.ready ? Pipewire.nodes.values.filter(node => node && node.audio) : []
    readonly property var outputDevices: audioNodes.filter(node => !node.isStream && node.isSink)
    readonly property var inputDevices: audioNodes.filter(node => !node.isStream && !node.isSink)
    readonly property var playbackStreams: audioNodes.filter(node => node.isStream && !node.isSink)
    readonly property var recordingStreams: audioNodes.filter(node => node.isStream && node.isSink)
    readonly property var currentOutputDevices: currentDevices(outputDevices, true)
    readonly property var currentInputDevices: currentDevices(inputDevices, false)
    readonly property var otherOutputDevices: otherDevices(outputDevices, currentOutputDevices.length > 0 ? currentOutputDevices[0] : null)
    readonly property var otherInputDevices: otherDevices(inputDevices, currentInputDevices.length > 0 ? currentInputDevices[0] : null)

    PwObjectTracker { objects: audioWindow.audioNodes }

    Process { id: launcher }

    function nodeTitle(node) {
        if (!node) return "Unknown"
        return node.description || node.nickname || node.name || ("Node " + node.id)
    }

    function nodeSubtitle(node) {
        if (!node) return ""
        var props = node.properties || {}
        return props["application.name"] || props["media.name"] || node.name || ""
    }

    function currentDevices(devices, output) {
        for (var i = 0; i < devices.length; i++) {
            if (output ? isDefaultOutput(devices[i]) : isDefaultInput(devices[i])) return [devices[i]]
        }
        return devices.length > 0 ? [devices[0]] : []
    }

    function otherDevices(devices, current) {
        var result = []
        for (var i = 0; i < devices.length; i++) {
            if (!current || devices[i].id !== current.id) result.push(devices[i])
        }
        return result
    }

    function percent(node) {
        if (!node || !node.audio) return 0
        return Math.round(Math.max(0, Math.min(1.5, node.audio.volume || 0)) * 100)
    }

    function setVolume(node, ratio) {
        if (!node || !node.audio) return
        node.audio.volume = Math.max(0, Math.min(1.5, ratio))
    }

    function setVolumeFromX(node, x, width) {
        setVolume(node, x / Math.max(1, width))
    }

    function wheelVolume(node, wheel) {
        if (!node || !node.audio) return
        setVolume(node, (node.audio.volume || 0) + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
        wheel.accepted = true
    }

    function toggleMute(node) {
        if (!node || !node.audio) return
        node.audio.muted = !node.audio.muted
    }

    function isDefaultOutput(node) {
        return Pipewire.defaultAudioSink && node && Pipewire.defaultAudioSink.id === node.id
    }

    function isDefaultInput(node) {
        return Pipewire.defaultAudioSource && node && Pipewire.defaultAudioSource.id === node.id
    }

    function setDefaultOutput(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
        outputPickerOpen = false
    }

    function setDefaultInput(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node
        inputPickerOpen = false
    }

    visible: opened || content.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.audio"
    WlrLayershell.exclusiveZone: -1

    MouseArea { anchors.fill: parent; onClicked: opened = false }

    Item {
        id: content
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 32
        width: Math.min(560, parent.width - 20)
        height: opened ? Math.min(620, column.implicitHeight + 32) : 0
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

            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                clip: true
                contentWidth: width
                contentHeight: column.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: column
                    width: parent.width
                    spacing: 10

                Row {
                    width: parent.width
                    height: 50
                    spacing: 12

                    Rectangle { width: 3; height: parent.height; color: panelAccent }

                    Text {
                        width: 34
                        height: parent.height
                        text: "音"
                        color: panelAccent
                        font.pixelSize: 26
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Column {
                        id: titleColumn
                        width: parent.width - 3 - 12 - 34 - 12 - 12 - 86
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text { text: "ONGAKU"; color: panelAccent; font.pixelSize: 9; font.letterSpacing: 4; font.bold: true }
                        Text { width: parent.width; text: Pipewire.ready ? "Sound control" : "Waiting for PipeWire"; color: panelFg; font.pixelSize: 18; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    }

                    Rectangle {
                        width: 86
                        height: 28
                        anchors.verticalCenter: parent.verticalCenter
                        color: inkBg
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        Text { anchors.centerIn: parent; text: "ADV"; color: panelFg; font.pixelSize: 10; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                launcher.command = ["sh", "-c", "command -v pavucontrol >/dev/null 2>&1 && pavucontrol || omarchy-launch-audio"]
                                launcher.running = true
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: panelAccent; opacity: 0.45 }

                Text { text: "OUTPUT DEVICES"; color: panelAccent; font.pixelSize: 9; font.letterSpacing: 3; font.bold: true }
                Column {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: currentOutputDevices
                        delegate: Rectangle {
                            width: parent.width
                            height: 58
                            color: outputHover.containsMouse ? hoverBg : (isDefaultOutput(modelData) ? Qt.rgba(1, 1, 1, 0.08) : inkBg)
                            border.color: isDefaultOutput(modelData) ? panelAccent : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: panelAccent; opacity: isDefaultOutput(modelData) || outputHover.containsMouse ? 1 : 0.2 }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Text {
                                    width: 24
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.audio.muted ? "" : ""
                                    color: modelData.audio.muted ? mutedFg : panelAccent
                                    font.pixelSize: 15
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: toggleMute(modelData) }
                                }

                                Column {
                                    width: 150
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3
                                    Text { width: parent.width; text: nodeTitle(modelData); color: panelFg; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                                    Text { width: parent.width; text: isDefaultOutput(modelData) ? "default output" : nodeSubtitle(modelData); color: mutedFg; font.pixelSize: 10; elide: Text.ElideRight }
                                }

                                Item {
                                    width: 170
                                    height: parent.height
                                    anchors.verticalCenter: parent.verticalCenter
                                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; color: Qt.rgba(1, 1, 1, 0.12) }
                                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Math.min(parent.width, parent.width * (modelData.audio.volume || 0)); height: 6; color: panelAccent }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => setVolumeFromX(modelData, mouse.x, width)
                                        onPositionChanged: (mouse) => { if (pressed) setVolumeFromX(modelData, mouse.x, width) }
                                    }
                                }

                                Text { width: 42; anchors.verticalCenter: parent.verticalCenter; text: percent(modelData) + "%"; color: panelFg; font.pixelSize: 11; horizontalAlignment: Text.AlignRight }
                                Rectangle {
                                    width: 56
                                    height: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: isDefaultOutput(modelData) ? panelAccent : "transparent"
                                    border.color: panelAccent
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: isDefaultOutput(modelData) ? "ON" : "USE"; color: isDefaultOutput(modelData) ? panelBg : panelAccent; font.pixelSize: 10; font.bold: true }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: setDefaultOutput(modelData) }
                                }
                            }

                            MouseArea {
                                id: outputHover
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                hoverEnabled: true
                                onWheel: (wheel) => wheelVolume(modelData, wheel)
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: otherOutputDevices.length > 0 ? 30 : 0
                        visible: otherOutputDevices.length > 0
                        color: outputPickerMouse.containsMouse || outputPickerOpen ? hoverBg : "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text { width: 18; height: parent.height; text: outputPickerOpen ? "▴" : "▾"; color: panelAccent; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                            Text { width: parent.width - 80; height: parent.height; text: "Other outputs"; color: panelFg; opacity: 0.8; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                            Text { width: 42; height: parent.height; text: otherOutputDevices.length.toString(); color: mutedFg; font.pixelSize: 10; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignRight }
                        }

                        MouseArea { id: outputPickerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: outputPickerOpen = !outputPickerOpen }
                    }

                    Column {
                        width: parent.width
                        spacing: 4
                        visible: outputPickerOpen && otherOutputDevices.length > 0

                        Repeater {
                            model: otherOutputDevices
                            delegate: Rectangle {
                                width: parent.width
                                height: 36
                                color: otherOutputMouse.containsMouse ? hoverBg : inkBg
                                border.color: Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 10
                                    Text { width: 22; height: parent.height; text: ""; color: panelAccent; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                                    Text { width: parent.width - 94; height: parent.height; text: nodeTitle(modelData); color: panelFg; font.pixelSize: 11; font.bold: true; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                                    Rectangle { width: 50; height: 24; anchors.verticalCenter: parent.verticalCenter; color: "transparent"; border.color: panelAccent; border.width: 1; Text { anchors.centerIn: parent; text: "USE"; color: panelAccent; font.pixelSize: 10; font.bold: true } }
                                }

                                MouseArea { id: otherOutputMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: setDefaultOutput(modelData) }
                            }
                        }
                    }
                }

                Text { text: "INPUT DEVICES"; color: panelAccent; font.pixelSize: 9; font.letterSpacing: 3; font.bold: true }
                Column {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: currentInputDevices
                        delegate: Rectangle {
                            width: parent.width
                            height: 58
                            color: inputHover.containsMouse ? hoverBg : (isDefaultInput(modelData) ? Qt.rgba(1, 1, 1, 0.08) : inkBg)
                            border.color: isDefaultInput(modelData) ? panelAccent : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: panelAccent; opacity: isDefaultInput(modelData) || inputHover.containsMouse ? 1 : 0.2 }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Text {
                                    width: 24
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.audio.muted ? "󰍭" : "󰍬"
                                    color: modelData.audio.muted ? mutedFg : panelAccent
                                    font.pixelSize: 15
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: toggleMute(modelData) }
                                }

                                Column {
                                    width: 150
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3
                                    Text { width: parent.width; text: nodeTitle(modelData); color: panelFg; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                                    Text { width: parent.width; text: isDefaultInput(modelData) ? "default input" : nodeSubtitle(modelData); color: mutedFg; font.pixelSize: 10; elide: Text.ElideRight }
                                }

                                Item {
                                    width: 170
                                    height: parent.height
                                    anchors.verticalCenter: parent.verticalCenter
                                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; color: Qt.rgba(1, 1, 1, 0.12) }
                                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Math.min(parent.width, parent.width * (modelData.audio.volume || 0)); height: 6; color: panelAccent }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => setVolumeFromX(modelData, mouse.x, width)
                                        onPositionChanged: (mouse) => { if (pressed) setVolumeFromX(modelData, mouse.x, width) }
                                    }
                                }

                                Text { width: 42; anchors.verticalCenter: parent.verticalCenter; text: percent(modelData) + "%"; color: panelFg; font.pixelSize: 11; horizontalAlignment: Text.AlignRight }
                                Rectangle {
                                    width: 56
                                    height: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: isDefaultInput(modelData) ? panelAccent : "transparent"
                                    border.color: panelAccent
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: isDefaultInput(modelData) ? "ON" : "USE"; color: isDefaultInput(modelData) ? panelBg : panelAccent; font.pixelSize: 10; font.bold: true }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: setDefaultInput(modelData) }
                                }
                            }

                            MouseArea {
                                id: inputHover
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                hoverEnabled: true
                                onWheel: (wheel) => wheelVolume(modelData, wheel)
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: otherInputDevices.length > 0 ? 30 : 0
                        visible: otherInputDevices.length > 0
                        color: inputPickerMouse.containsMouse || inputPickerOpen ? hoverBg : "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text { width: 18; height: parent.height; text: inputPickerOpen ? "▴" : "▾"; color: panelAccent; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                            Text { width: parent.width - 80; height: parent.height; text: "Other inputs"; color: panelFg; opacity: 0.8; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                            Text { width: 42; height: parent.height; text: otherInputDevices.length.toString(); color: mutedFg; font.pixelSize: 10; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignRight }
                        }

                        MouseArea { id: inputPickerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: inputPickerOpen = !inputPickerOpen }
                    }

                    Column {
                        width: parent.width
                        spacing: 4
                        visible: inputPickerOpen && otherInputDevices.length > 0

                        Repeater {
                            model: otherInputDevices
                            delegate: Rectangle {
                                width: parent.width
                                height: 36
                                color: otherInputMouse.containsMouse ? hoverBg : inkBg
                                border.color: Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 10
                                    Text { width: 22; height: parent.height; text: "󰍬"; color: panelAccent; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                                    Text { width: parent.width - 94; height: parent.height; text: nodeTitle(modelData); color: panelFg; font.pixelSize: 11; font.bold: true; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                                    Rectangle { width: 50; height: 24; anchors.verticalCenter: parent.verticalCenter; color: "transparent"; border.color: panelAccent; border.width: 1; Text { anchors.centerIn: parent; text: "USE"; color: panelAccent; font.pixelSize: 10; font.bold: true } }
                                }

                                MouseArea { id: otherInputMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: setDefaultInput(modelData) }
                            }
                        }
                    }
                }

                Text { text: "APP PLAYBACK"; color: panelAccent; font.pixelSize: 9; font.letterSpacing: 3; font.bold: true; visible: playbackStreams.length > 0 }
                Column {
                    width: parent.width
                    spacing: 6
                    visible: playbackStreams.length > 0
                    Repeater {
                        model: playbackStreams
                        delegate: Rectangle {
                            width: parent.width
                            height: 48
                            color: playbackHover.containsMouse ? hoverBg : inkBg
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: panelAccent; opacity: playbackHover.containsMouse ? 1 : 0.2 }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 9
                                spacing: 10

                                Text { width: 24; height: parent.height; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; text: modelData.audio.muted ? "" : ""; color: modelData.audio.muted ? mutedFg : panelAccent; font.pixelSize: 14; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: toggleMute(modelData) } }
                                Column { width: 188; anchors.verticalCenter: parent.verticalCenter; spacing: 2; Text { width: parent.width; text: nodeTitle(modelData); color: panelFg; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight } Text { width: parent.width; text: nodeSubtitle(modelData); color: mutedFg; font.pixelSize: 10; elide: Text.ElideRight } }
                                Item { width: 210; height: parent.height; Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; color: Qt.rgba(1, 1, 1, 0.12) } Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Math.min(parent.width, parent.width * (modelData.audio.volume || 0)); height: 6; color: panelAccent } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onPressed: (mouse) => setVolumeFromX(modelData, mouse.x, width); onPositionChanged: (mouse) => { if (pressed) setVolumeFromX(modelData, mouse.x, width) } } }
                                Text { width: 42; anchors.verticalCenter: parent.verticalCenter; text: percent(modelData) + "%"; color: panelFg; font.pixelSize: 11; horizontalAlignment: Text.AlignRight }
                            }

                            MouseArea {
                                id: playbackHover
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                hoverEnabled: true
                                onWheel: (wheel) => wheelVolume(modelData, wheel)
                            }
                        }
                    }
                }

                Text { text: "RECORDING APPS"; color: panelAccent; font.pixelSize: 9; font.letterSpacing: 3; font.bold: true; visible: recordingStreams.length > 0 }
                Column {
                    width: parent.width
                    spacing: 6
                    visible: recordingStreams.length > 0
                    Repeater {
                        model: recordingStreams
                        delegate: Rectangle {
                            width: parent.width
                            height: 42
                            color: recordingHover.containsMouse ? hoverBg : inkBg
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: panelAccent; opacity: recordingHover.containsMouse ? 1 : 0.2 }
                            Row {
                                anchors.fill: parent
                                anchors.margins: 9
                                spacing: 10
                                Text { width: 24; height: parent.height; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; text: modelData.audio.muted ? "󰍭" : "󰍬"; color: modelData.audio.muted ? mutedFg : panelAccent; font.pixelSize: 14; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: toggleMute(modelData) } }
                                Text { width: parent.width - 88; anchors.verticalCenter: parent.verticalCenter; text: nodeTitle(modelData); color: panelFg; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                                Text { width: 42; anchors.verticalCenter: parent.verticalCenter; text: percent(modelData) + "%"; color: panelFg; font.pixelSize: 11; horizontalAlignment: Text.AlignRight }
                            }

                            MouseArea {
                                id: recordingHover
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                hoverEnabled: true
                                onWheel: (wheel) => wheelVolume(modelData, wheel)
                            }
                        }
                    }
                }
                }
            }
        }
    }
}

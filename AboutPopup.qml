import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: aboutWindow

    property var theme: null
    property bool opened: false
    property var hardwareItems: []
    property var softwareItems: []
    property var statusItems: []
    property string osName: "Omarchy"
    property string themeName: ""

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"
    readonly property string inkBg: "#1b1613"
    readonly property string hoverBg: Qt.rgba(1, 1, 1, 0.075)

    onOpenedChanged: if (opened) refreshInfo()

    function fmtBytes(bytes) {
        if (!bytes || bytes <= 0) return "0 B"
        var units = ["B", "KiB", "MiB", "GiB", "TiB"]
        var value = bytes
        var unit = 0
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024
            unit++
        }
        return value.toFixed(unit === 0 ? 0 : 1) + " " + units[unit]
    }

    function uptimeText(ms) {
        var minutes = Math.floor((ms || 0) / 60000)
        var days = Math.floor(minutes / 1440)
        var hours = Math.floor((minutes % 1440) / 60)
        var mins = minutes % 60
        if (days > 0) return days + "d " + hours + "h"
        if (hours > 0) return hours + "h " + mins + "m"
        return mins + "m"
    }

    function cleanAnsi(value) {
        return (value || "").toString().replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "").trim()
    }

    function first(type, data) {
        for (var i = 0; i < data.length; i++) if (data[i].type === type && data[i].result !== undefined) return data[i].result
        return null
    }

    function all(type, data) {
        var result = []
        for (var i = 0; i < data.length; i++) if (data[i].type === type && data[i].result !== undefined) result.push(data[i].result)
        return result
    }

    function commandResults(data) {
        var result = []
        for (var i = 0; i < data.length; i++) if (data[i].type === "Command" && data[i].result !== undefined) result.push(cleanAnsi(data[i].result))
        return result
    }

    function parseInfo(output) {
        try {
            var data = JSON.parse(output || "[]")
            var cpu = first("CPU", data)
            var gpus = first("GPU", data) || []
            var displays = first("Display", data) || []
            var disks = first("Disk", data) || []
            var memory = first("Memory", data)
            var kernel = first("Kernel", data)
            var wm = first("WM", data)
            var terminal = first("Terminal", data)
            var packages = first("Packages", data)
            var font = first("TerminalFont", data)
            var uptime = first("Uptime", data)
            var commands = commandResults(data)

            osName = commands.length > 0 ? commands[0] : "Omarchy"
            themeName = commands.length > 3 ? commands[3].replace(/[●\s]+$/g, "").trim() : ""

            var hw = []
            if (cpu) hw.push({ icon: "", label: "CPU", value: cpu.cpu + " (" + cpu.cores.logical + ")" })
            for (var g = 0; g < Math.min(gpus.length, 2); g++) hw.push({ icon: "", label: gpus[g].type || "GPU", value: gpus[g].name })
            for (var d = 0; d < Math.min(displays.length, 2); d++) hw.push({ icon: "󱄄", label: "Display", value: displays[d].output.width + "x" + displays[d].output.height + " @ " + Math.round(displays[d].output.refreshRate) + "Hz" })
            if (disks.length > 0) hw.push({ icon: "󰋊", label: "Disk", value: fmtBytes(disks[0].bytes.used) + " / " + fmtBytes(disks[0].bytes.total) })
            if (memory) hw.push({ icon: "", label: "Memory", value: fmtBytes(memory.used) + " / " + fmtBytes(memory.total) })
            hardwareItems = hw

            var sw = []
            sw.push({ icon: "", label: "OS", value: osName })
            if (kernel) sw.push({ icon: "", label: "Kernel", value: kernel.name + " " + kernel.release })
            if (wm) sw.push({ icon: "", label: "Session", value: wm.prettyName + " " + wm.version + " (" + wm.protocolName + ")" })
            if (terminal) sw.push({ icon: "", label: "Terminal", value: terminal.prettyName + " " + terminal.version })
            if (packages) sw.push({ icon: "󰏖", label: "Packages", value: packages.all + " total" })
            if (font && font.font) sw.push({ icon: "", label: "Font", value: font.font.pretty })
            softwareItems = sw

            var st = []
            if (commands.length > 1) st.push({ icon: "󰘬", label: "Branch", value: commands[1] })
            if (commands.length > 2) st.push({ icon: "󰔫", label: "Channel", value: commands[2] })
            if (themeName !== "") st.push({ icon: "󰸌", label: "Theme", value: themeName })
            if (commands.length > 4) st.push({ icon: "󱦟", label: "OS Age", value: commands[4] })
            if (uptime) st.push({ icon: "󱫐", label: "Uptime", value: uptimeText(uptime.uptime) })
            if (commands.length > 5) st.push({ icon: "", label: "Update", value: commands[5] })
            statusItems = st
        } catch (error) {
            hardwareItems = [{ icon: "󰅙", label: "Error", value: "Could not parse fastfetch" }]
            softwareItems = []
            statusItems = []
        }
    }

    function refreshInfo() {
        fetcher.command = ["fastfetch", "--format", "json", "--logo", "none"]
        fetcher.running = true
    }

    Process {
        id: fetcher
        stdout: StdioCollector { onStreamFinished: parseInfo(this.text || "") }
    }

    Component {
        id: infoRow
        Rectangle {
            width: parent.width
            height: 32
            color: Qt.rgba(1, 1, 1, 0.035)
            border.color: Qt.rgba(1, 1, 1, 0.055)
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text { width: 24; height: parent.height; text: modelData.icon; color: panelAccent; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                Column {
                    width: parent.width - 44
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text { width: parent.width; text: modelData.label; color: mutedFg; font.pixelSize: 8; font.letterSpacing: 1.3; font.bold: true; elide: Text.ElideRight }
                    Text { width: parent.width; text: modelData.value; color: panelFg; font.pixelSize: 11; font.weight: Font.DemiBold; elide: Text.ElideRight }
                }
            }
        }
    }

    Component {
        id: sectionCard
        Rectangle {
            property string title: ""
            property var entries: []

            width: parent.width
            height: parent.height
            color: inkBg
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7

                Row {
                    width: parent.width
                    height: 20
                    spacing: 8
                    Rectangle { width: 3; height: 16; color: panelAccent; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: parent.width - 11; text: title; color: panelAccent; font.pixelSize: 10; font.letterSpacing: 3; font.bold: true; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                }

                Repeater { model: entries; delegate: infoRow }

                Text {
                    visible: entries.length === 0
                    width: parent.width
                    height: 38
                    text: "No data available"
                    color: mutedFg
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    visible: opened || content.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.about"
    WlrLayershell.exclusiveZone: -1

    MouseArea { anchors.fill: parent; onClicked: opened = false }

    Item {
        id: content
        anchors.centerIn: parent
        width: Math.min(980, parent.width - 28)
        height: Math.min(500, parent.height - 48)
        opacity: opened ? 1 : 0
        scale: opened ? 1 : 0.98
        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 2
            radius: 0
            clip: true

            Rectangle { width: 260; height: 260; radius: 130; x: parent.width - 140; y: -130; color: panelAccent; opacity: 0.08 }
            Rectangle { width: 180; height: 180; radius: 90; x: -80; y: parent.height - 80; color: panelAccent; opacity: 0.045 }
            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 18

                Row {
                    width: parent.width
                    height: 62
                    spacing: 16

                    Rectangle {
                        width: 48
                        height: 48
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(1, 1, 1, 0.045)
                        border.color: panelAccent
                        border.width: 1
                        Text { anchors.centerIn: parent; text: ""; color: panelAccent; font.family: "omarchy"; font.pixelSize: 26 }
                    }

                    Column {
                        width: parent.width - 48 - 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text { text: "SHIRASE"; color: panelAccent; font.pixelSize: 10; font.letterSpacing: 4; font.bold: true }
                        Text { width: parent.width; text: osName; color: panelFg; font.pixelSize: 24; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { width: parent.width; text: themeName !== "" ? "知らせ / " + themeName + " theme" : "知らせ / system snapshot"; color: mutedFg; font.pixelSize: 12; elide: Text.ElideRight }
                    }
                }

                Row {
                    id: body
                    width: parent.width
                    height: parent.height - 78
                    clip: true
                    spacing: 14

                    Rectangle {
                        id: rail
                        width: Math.max(170, Math.floor(parent.width * 0.22))
                        height: parent.height
                        color: Qt.rgba(1, 1, 1, 0.035)
                        border.color: Qt.rgba(1, 1, 1, 0.07)
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 13

                            Rectangle { width: parent.width; height: 3; color: panelAccent }
                            Text { width: parent.width; text: "知らせ"; color: panelAccent; font.pixelSize: 36; horizontalAlignment: Text.AlignHCenter }
                            Text { width: parent.width; text: "SYSTEM SNAPSHOT"; color: panelFg; font.pixelSize: 13; font.letterSpacing: 2; font.bold: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
                            Rectangle { width: parent.width; height: 1; color: panelAccent; opacity: 0.35 }
                            Text { width: parent.width; text: "Hardware, software and session state from fastfetch."; color: mutedFg; font.pixelSize: 12; lineHeight: 1.12; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter }
                        }
                    }

                    Loader { width: Math.floor((parent.width - rail.width - 42) / 3); height: parent.height; sourceComponent: sectionCard; onLoaded: { item.title = "HARDWARE"; item.entries = Qt.binding(function() { return hardwareItems }) } }
                    Loader { width: Math.floor((parent.width - rail.width - 42) / 3); height: parent.height; sourceComponent: sectionCard; onLoaded: { item.title = "SOFTWARE"; item.entries = Qt.binding(function() { return softwareItems }) } }
                    Loader { width: Math.floor((parent.width - rail.width - 42) / 3); height: parent.height; sourceComponent: sectionCard; onLoaded: { item.title = "STATUS"; item.entries = Qt.binding(function() { return statusItems }) } }

                }
            }
        }
    }
}

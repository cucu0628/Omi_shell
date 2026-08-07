import QtQuick
import Quickshell.Io

Item {
    id: controller

    property bool active: false
    property string name: ""

    width: 0
    height: 0
    visible: false

    function refresh() {
        fetcher.command = ["nmcli", "-t", "-f", "TYPE,NAME", "connection", "show", "--active"]
        fetcher.running = true
    }

    function update(output) {
        var lines = (output || "").trim().split("\n")
        var activeName = ""
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split(":")
            if (parts.length >= 2 && (parts[0] === "vpn" || parts[0] === "wireguard")) {
                activeName = parts.slice(1).join(":")
                break
            }
        }
        active = activeName !== ""
        name = activeName
    }

    Process {
        id: fetcher
        stdout: StdioCollector { onStreamFinished: controller.update(this.text || "") }
    }

    Timer {
        interval: 12000
        running: true
        repeat: true
        onTriggered: controller.refresh()
    }
}

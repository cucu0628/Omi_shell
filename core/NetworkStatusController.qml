import QtQuick
import Quickshell.Io
import Quickshell.Networking

Item {
    id: controller

    property bool connected: false
    property string connectionType: "offline"
    property string connectionName: ""
    property string device: ""
    property string lanIp: ""
    property var addresses: ({})
    property bool vpnActive: false
    property string vpnName: ""

    width: 0
    height: 0
    visible: false

    function splitEscaped(line) {
        var fields = []
        var field = ""
        var escaped = false
        for (var i = 0; i < line.length; i++) {
            var character = line[i]
            if (escaped) {
                field += character
                escaped = false
            } else if (character === "\\") {
                escaped = true
            } else if (character === ":") {
                fields.push(field)
                field = ""
            } else {
                field += character
            }
        }
        fields.push(field)
        return fields
    }

    function refresh() {
        if (!connectionFetcher.running) {
            connectionFetcher.command = ["nmcli", "-t", "-e", "yes", "-f", "TYPE,DEVICE,NAME", "connection", "show", "--active"]
            connectionFetcher.running = true
        }
        if (!addressFetcher.running) {
            addressFetcher.command = ["ip", "-4", "-j", "address", "show", "up", "scope", "global"]
            addressFetcher.running = true
        }
    }

    function updateConnections(output) {
        var best = null
        var activeVpn = ""
        var lines = (output || "").trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            if (lines[i] === "") continue
            var fields = splitEscaped(lines[i])
            if (fields.length < 3) continue
            var type = fields[0]
            if ((type === "vpn" || type === "wireguard") && activeVpn === "") {
                activeVpn = fields.slice(2).join(":")
                continue
            }
            if (fields[1] === "") continue
            var normalized = ""
            if (type === "802-3-ethernet" || type === "ethernet") normalized = "ethernet"
            else if (type === "802-11-wireless" || type === "wifi") normalized = "wifi"
            if (normalized === "") continue

            var candidate = { type: normalized, device: fields[1], name: fields.slice(2).join(":") }
            if (!best || (candidate.type === "ethernet" && best.type !== "ethernet")) best = candidate
        }

        connected = best !== null
        connectionType = best ? best.type : "offline"
        connectionName = best ? best.name : ""
        device = best ? best.device : ""
        vpnActive = activeVpn !== ""
        vpnName = activeVpn
        updateLanIp()
    }

    function updateAddresses(output) {
        var nextAddresses = {}
        try {
            var interfaces = JSON.parse(output || "[]")
            for (var i = 0; i < interfaces.length; i++) {
                var info = interfaces[i]
                var entries = info.addr_info || []
                for (var j = 0; j < entries.length; j++) {
                    if (entries[j].family === "inet" && entries[j].scope === "global") {
                        nextAddresses[info.ifname] = entries[j].local || ""
                        break
                    }
                }
            }
        } catch (error) {
            nextAddresses = {}
        }
        addresses = nextAddresses
        updateLanIp()
    }

    function updateLanIp() {
        lanIp = device && addresses[device] ? addresses[device] : ""
    }

    Process {
        id: connectionFetcher
        stdout: StdioCollector { onStreamFinished: controller.updateConnections(this.text || "") }
    }

    Process {
        id: addressFetcher
        stdout: StdioCollector { onStreamFinished: controller.updateAddresses(this.text || "") }
    }

    Timer {
        id: monitorRefresh
        interval: 150
        onTriggered: controller.refresh()
    }

    Connections {
        target: Networking.devices

        function onValuesChanged() { monitorRefresh.restart() }
    }

    Instantiator {
        model: Networking.devices

        delegate: Item {
            required property var modelData

            width: 0
            height: 0
            visible: false

            Connections {
                target: modelData

                function onConnectedChanged() { monitorRefresh.restart() }
                function onStateChanged() { monitorRefresh.restart() }
                function onAddressChanged() { monitorRefresh.restart() }
                function onNameChanged() { monitorRefresh.restart() }
            }

            Connections {
                target: modelData.networks || null
                ignoreUnknownSignals: true

                function onValuesChanged() { monitorRefresh.restart() }
            }
        }
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: controller.refresh()
    }
}

import QtQuick
import Quickshell.Io

// Single source of truth for the VPN bar item and the Proton panel.
//
// Every `protonvpn` call costs ~2.5s of python startup, so it is only used for
// details and actions. Whether a tunnel is up is polled from nmcli instead,
// which answers in milliseconds and still sees Proton's WireGuard device, so
// the panel can open on the right state instead of flipping a second later.
// Details stay cached here rather than in the popup, which is unloaded when it
// closes.
Item {
    id: controller

    // Cheap state, shared with the bar.
    property bool active: false
    property string rawName: ""
    property string name: ""
    property bool cliConnected: false
    readonly property bool nmProton: rawName.indexOf("ProtonVPN") === 0
    // A tunnel nmcli can see counts as up even when the CLI disagrees, which it
    // does when the connection was made from the Proton app.
    readonly property bool protonActive: nmProton || cliConnected

    // Detail state, filled in by the CLI.
    property bool cliAvailable: true
    property bool checking: false
    property bool panelOpen: false
    property string detailKey: ""
    property string pendingKey: ""
    property double detailTime: 0
    property string server: ""
    property string location: ""
    property string load: ""
    property string protocol: ""
    property string publicIp: ""
    property string killSwitch: ""
    property bool locationSelection: false
    property bool planKnown: false
    property bool configLoaded: false
    property var countries: []
    property string action: ""
    property string errorMessage: ""
    readonly property bool busy: action !== ""

    width: 0
    height: 0
    visible: false

    function refresh() {
        if (poll.running) return
        poll.command = ["nmcli", "-t", "-f", "TYPE,NAME", "connection", "show", "--active"]
        poll.running = true
    }

    function updatePoll(output) {
        var lines = (output || "").trim().split("\n")
        var found = ""
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split(":")
            if (parts.length >= 2 && (parts[0] === "vpn" || parts[0] === "wireguard")) {
                found = parts.slice(1).join(":")
                break
            }
        }
        rawName = found
        active = found !== ""
        name = found.replace(/^ProtonVPN\s+/, "")

        if (!nmProton) {
            if (!cliConnected) clearDetails()
        } else if (detailKey !== name) {
            // A different server than the cached details: show what nmcli
            // already knows and only pay for the CLI while the panel is up.
            server = name
            location = ""
            load = ""
            protocol = ""
            publicIp = ""
            if (panelOpen) refreshDetails(false)
        }
    }

    function clearDetails() {
        server = ""
        location = ""
        load = ""
        protocol = ""
        publicIp = ""
        detailKey = ""
        pendingKey = ""
    }

    function refreshDetails(force) {
        if (!cliAvailable || statusQuery.running) return
        if (!force && detailKey === name && Date.now() - detailTime < 60000) return

        // The attempt is recorded before the call runs: a status answer that
        // disagrees with nmcli (the Proton app connects behind the CLI's back)
        // must not leave the poll asking for details over and over.
        pendingKey = name
        detailKey = name
        detailTime = Date.now()
        checking = true
        statusQuery.command = ["protonvpn", "status"]
        statusQuery.running = true
    }

    function refreshConfig(force) {
        if (!cliAvailable || configQuery.running) return
        if (!force && configLoaded) return
        configQuery.command = ["protonvpn", "config", "list"]
        configQuery.running = true
    }

    function refreshCountries() {
        if (!cliAvailable || countryQuery.running || !locationSelection || countries.length > 0) return
        countryQuery.command = ["protonvpn", "countries", "list"]
        countryQuery.running = true
    }

    function panelOpened() {
        errorMessage = ""
        refresh()
        // Nothing to describe while no tunnel is up, so no CLI call is made.
        if (nmProton || cliConnected) refreshDetails(false)
        refreshConfig(false)
    }

    function parseStatus(output) {
        var lines = (output || "").trim().split("\n")
        var connected = false
        var nextServer = ""
        var nextLocation = ""
        var nextLoad = ""
        var nextProtocol = ""
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            var separator = line.indexOf(":")
            if (separator === -1) continue

            var key = line.slice(0, separator).trim().toLowerCase()
            var value = line.slice(separator + 1).trim()
            if (key === "status") connected = value.toLowerCase() === "connected"
            else if (key === "server") {
                // "NL-FREE#113 in Amsterdam, Netherlands"
                var split = value.indexOf(" in ")
                nextServer = split === -1 ? value : value.slice(0, split)
                nextLocation = split === -1 ? "" : value.slice(split + 4)
            } else if (key === "load") nextLoad = value
            else if (key === "protocol") nextProtocol = value
        }

        // Never poke nmcli from here: the two feeding each other is what turned
        // a disagreement into an endless refresh loop.
        cliConnected = connected
        detailKey = pendingKey
        detailTime = Date.now()

        if (!connected) {
            location = ""
            load = ""
            protocol = ""
            publicIp = ""
            // nmcli may still see the tunnel, and then its name is all we have.
            if (!nmProton) server = ""
            return
        }

        server = nextServer
        location = nextLocation
        load = nextLoad
        protocol = nextProtocol
    }

    function parseConfig(output) {
        var text = output || ""
        var lines = text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].match(/^kill-switch\s+(\S.*)$/)
            if (match) killSwitch = match[1].trim()
        }
        // The free plan renders paid settings as "Upgrade to enable", which is
        // also exactly when the CLI refuses any location selection.
        locationSelection = text.trim() !== "" && text.indexOf("Upgrade to enable") === -1
        planKnown = text.trim() !== ""
        configLoaded = planKnown
        if (locationSelection) refreshCountries()
    }

    function parseCountries(output) {
        var result = []
        var lines = (output || "").trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line.indexOf("---") === 0 || line.trim() === "") continue

            var match = line.match(/^(.*\S)\s{2,}([A-Z]{2})\s*$/)
            if (!match || match[1].trim() === "Country") continue

            result.push({ "name": match[1].trim(), "code": match[2] })
        }
        countries = result
    }

    function cleanOutput(output) {
        var lines = (output || "").split("\n")
        var kept = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "" || line.toLowerCase().indexOf("eventlet") !== -1 || line.indexOf("warnings.warn") !== -1) continue

            kept.push(line)
        }
        return kept
    }

    function actionError(output) {
        var lines = cleanOutput(output)
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("Error:") === 0) return lines[i].replace(/^Error:\s*/, "")
        }
        for (var j = lines.length - 1; j >= 0; j--) {
            if (lines[j].indexOf("Try '") !== 0 && lines[j].indexOf("Usage:") !== 0) return lines[j]
        }
        return "The Proton VPN CLI reported an error"
    }

    // `connect` already reports the server it landed on, so the panel can settle
    // immediately instead of waiting for another status call.
    function parseActionOutput(output) {
        var lines = cleanOutput(output)
        for (var i = 0; i < lines.length; i++) {
            var connectedTo = lines[i].match(/Connected to\s+(\S+)\s+in\s+(.+?)\.?$/)
            if (connectedTo) {
                server = connectedTo[1]
                location = connectedTo[2]
                detailKey = connectedTo[1]
                pendingKey = connectedTo[1]
                detailTime = Date.now()
                rawName = "ProtonVPN " + connectedTo[1]
                name = connectedTo[1]
                active = true
                cliConnected = true
            }
            var address = lines[i].match(/IP address is\s+([0-9a-fA-F:.]+)/)
            if (address) publicIp = address[1].replace(/\.$/, "")
            if (lines[i].indexOf("Disconnected") === 0) {
                clearDetails()
                rawName = ""
                name = ""
                active = false
                cliConnected = false
            }
        }
    }

    function run(label, command) {
        if (busy) return
        action = label
        errorMessage = ""
        vpnAction.command = command
        vpnAction.running = true
    }

    // Launching lives here rather than in the panel: the panel is unloaded a
    // moment after it closes, which killed the still-starting app with it.
    // setsid also puts the app in its own session so nothing can reap it.
    function openApp() {
        appLauncher.command = ["sh", "-c", "setsid protonvpn-app >/dev/null 2>&1 </dev/null &"]
        appLauncher.running = true
    }

    function connectFastest() { run("connect", ["protonvpn", "connect"]) }
    function connectCountry(code) { run("connect", ["protonvpn", "connect", "--country", code]) }
    function disconnectVpn() { run("disconnect", ["protonvpn", "disconnect"]) }

    Component.onCompleted: cliProbe.running = true

    Process {
        id: cliProbe
        command: ["sh", "-c", "command -v protonvpn >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: controller.cliAvailable = (this.text || "").trim() === "yes" }
    }

    Process {
        id: poll
        stdout: StdioCollector { onStreamFinished: controller.updatePoll(this.text || "") }
    }

    Process {
        id: appLauncher
    }

    Process {
        id: statusQuery
        environment: ({ "PYTHONWARNINGS": "ignore" })
        onExited: controller.checking = false
        stdout: StdioCollector { onStreamFinished: controller.parseStatus(this.text || "") }
    }

    Process {
        id: configQuery
        environment: ({ "PYTHONWARNINGS": "ignore" })
        stdout: StdioCollector { onStreamFinished: controller.parseConfig(this.text || "") }
    }

    Process {
        id: countryQuery
        environment: ({ "PYTHONWARNINGS": "ignore" })
        stdout: StdioCollector { onStreamFinished: controller.parseCountries(this.text || "") }
    }

    Process {
        id: vpnAction

        property string failureText: ""
        property string successText: ""

        environment: ({ "PYTHONWARNINGS": "ignore" })
        onRunningChanged: {
            if (running) {
                failureText = ""
                successText = ""
            }
        }
        onExited: (exitCode) => {
            controller.action = ""
            if (exitCode === 0) controller.parseActionOutput(successText)
            else controller.errorMessage = controller.actionError(failureText !== "" ? failureText : successText)
            controller.refresh()
            controller.refreshDetails(true)
        }
        stdout: StdioCollector { onStreamFinished: vpnAction.successText = this.text || "" }
        stderr: StdioCollector { onStreamFinished: vpnAction.failureText = this.text || "" }
    }

    Timer {
        interval: controller.panelOpen ? 4000 : 12000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: controller.refresh()
    }
}

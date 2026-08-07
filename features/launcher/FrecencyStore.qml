import QtQuick
import Quickshell.Io

Item {
    id: store

    property var stats: ({})

    width: 0
    height: 0
    visible: false

    Component.onCompleted: load()

    function score(app) {
        var key = app.id || app.name
        var stat = stats[key]
        if (!stat) return 0
        return Math.min(60, (stat.count || 0) * 4) + Math.max(0, 30 - Math.floor((Date.now() / 1000 - (stat.last || 0)) / 86400))
    }

    function load() {
        statsLoader.command = ["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\"; awk -F '\\t' '{ c[$1]++; l[$1]=$2 } END { for (id in c) printf \"%s\\t%d\\t%s\\n\", id, c[id], l[id] }' \"$HOME/.cache/quickshell/launcher-frecent.tsv\" 2>/dev/null"]
        statsLoader.running = true
    }

    function parse(output) {
        var parsedStats = {}
        var lines = (output || "").trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("\t")
            if (parts.length >= 3 && parts[0] !== "") parsedStats[parts[0]] = { count: parseInt(parts[1]) || 0, last: parseInt(parts[2]) || 0 }
        }
        stats = parsedStats
    }

    function record(id) {
        if (!id || id === "") return
        var now = Math.floor(Date.now() / 1000)
        var currentStats = stats
        var current = currentStats[id] || { count: 0, last: 0 }
        current.count = current.count + 1
        current.last = now
        currentStats[id] = current
        stats = currentStats
        statsWriter.command = ["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\"; printf '%s\\t%s\\n' " + shellQuote(id) + " " + shellQuote(now.toString()) + " >> \"$HOME/.cache/quickshell/launcher-frecent.tsv\""]
        statsWriter.running = true
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    Process { id: statsWriter }
    Process {
        id: statsLoader
        stdout: StdioCollector { onStreamFinished: store.parse(this.text || "") }
    }
}

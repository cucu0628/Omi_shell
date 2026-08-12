import QtQuick
import Quickshell.Io

Item {
    id: stats

    property bool active: false
    property int cpuUsage: 0
    property int ramUsage: 0
    property int diskUsage: 0
    property double previousCpuIdle: -1
    property double previousCpuTotal: -1

    width: 0
    height: 0
    visible: false

    onActiveChanged: {
        if (active) {
            previousCpuIdle = -1
            previousCpuTotal = -1
            requestRefresh()
            initialCpuSample.start()
            refreshDisk()
        } else {
            initialCpuSample.stop()
        }
    }

    function requestRefresh() {
        cpuFile.reload()
        memoryFile.reload()
    }

    function updateCpu(text) {
        if (!active) return
        var firstLine = (text || "").split("\n")[0]
        var cpuFields = firstLine.trim().split(/\s+/)
        if (cpuFields.length >= 8 && cpuFields[0] === "cpu") {
            var idle = Number(cpuFields[4]) + Number(cpuFields[5])
            var total = 0
            for (var i = 1; i < cpuFields.length; i++) total += Number(cpuFields[i]) || 0
            if (previousCpuTotal >= 0 && total > previousCpuTotal) {
                cpuUsage = Math.max(0, Math.min(100, Math.round(100 * (1 - (idle - previousCpuIdle) / (total - previousCpuTotal)))))
            }
            previousCpuIdle = idle
            previousCpuTotal = total
        }
    }

    function updateMemory(text) {
        if (!active) return
        var memory = {}
        var memoryLines = (text || "").split("\n")
        for (var j = 0; j < memoryLines.length; j++) {
            var match = memoryLines[j].match(/^(MemTotal|MemAvailable):\s+(\d+)/)
            if (match) memory[match[1]] = Number(match[2])
        }
        if (memory.MemTotal > 0) {
            ramUsage = Math.max(0, Math.min(100, Math.round(100 * (memory.MemTotal - memory.MemAvailable) / memory.MemTotal)))
        }
    }

    function refreshDisk() {
        if (!diskLoader.running) diskLoader.running = true
    }

    function parseDisk(output) {
        var lines = (output || "").trim().split("\n")
        if (lines.length < 2) return
        var fields = lines[lines.length - 1].trim().split(/\s+/)
        if (fields.length < 5) return
        diskUsage = Math.max(0, Math.min(100, parseInt(fields[4]) || 0))
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        preload: true
        printErrors: false
        onLoaded: stats.updateCpu(cpuFile.text())
    }

    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        preload: true
        printErrors: false
        onLoaded: stats.updateMemory(memoryFile.text())
    }

    Process {
        id: diskLoader
        command: ["df", "-P", "/"]
        stdout: StdioCollector { onStreamFinished: stats.parseDisk(this.text || "") }
    }

    Timer {
        id: initialCpuSample
        interval: 300
        onTriggered: cpuFile.reload()
    }

    Timer {
        interval: 5000
        running: stats.active
        repeat: true
        onTriggered: stats.requestRefresh()
    }

    Timer {
        interval: 60000
        running: stats.active
        repeat: true
        onTriggered: stats.refreshDisk()
    }
}

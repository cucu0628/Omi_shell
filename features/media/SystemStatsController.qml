import QtQuick
import Quickshell.Io

Item {
    id: stats

    property bool active: false
    property int cpuUsage: 0
    property int ramUsage: 0
    property int diskUsage: 0

    width: 0
    height: 0
    visible: false

    onActiveChanged: if (active) refresh()

    function parse(output) {
        var lines = (output || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("=")
            if (parts.length !== 2) continue
            var value = Math.max(0, Math.min(100, parseInt(parts[1]) || 0))
            if (parts[0] === "cpu") cpuUsage = value
            else if (parts[0] === "ram") ramUsage = value
            else if (parts[0] === "disk") diskUsage = value
        }
    }

    function refresh() {
        loader.command = ["sh", "-c", "read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat; idle1=$((idle+iowait)); total1=$((user+nice+system+idle+iowait+irq+softirq+steal)); sleep 0.25; read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat; idle2=$((idle+iowait)); total2=$((user+nice+system+idle+iowait+irq+softirq+steal)); dt=$((total2-total1)); di=$((idle2-idle1)); if [ \"$dt\" -gt 0 ]; then cpu=$(( (100*(dt-di))/dt )); else cpu=0; fi; printf 'cpu=%s\n' \"$cpu\"; free | awk '/^Mem:/{print \"ram=\" int(($2-$7)*100/$2)}'; df -P / | awk 'NR==2{gsub(/%/,\"\",$5); print \"disk=\" $5}'"]
        loader.running = true
    }

    Process {
        id: loader
        stdout: StdioCollector { onStreamFinished: stats.parse(this.text || "") }
    }

    Timer {
        interval: 5000
        running: stats.active
        repeat: true
        onTriggered: stats.refresh()
    }
}

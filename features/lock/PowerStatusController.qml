import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string powerText: "Desktop power"

    function refreshPowerStatus() {
        powerFetcher.command = ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] || continue; cap=$(cat \"$b/capacity\"); status=$(cat \"$b/status\" 2>/dev/null); printf '%s%% · %s\\n' \"$cap\" \"$status\"; exit; done; for a in /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/Mains*; do [ -e \"$a\" ] && printf 'AC power\\n' && exit; done; printf 'Desktop power\\n'"]
        powerFetcher.running = true
    }

    property Process powerFetcher: Process {
        stdout: StdioCollector {
            onStreamFinished: root.powerText = (this.text || "Desktop power").trim()
        }
    }
}

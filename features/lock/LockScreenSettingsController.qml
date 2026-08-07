import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string inputMonitorName: ""
    property bool ready: false

    function load() {
        ready = false
        loader.command = ["sh", "-c", "sh \"$HOME/.config/quickshell/omi_shell/scripts/lockscreen-monitor\" current"]
        loader.running = true
    }

    property Process loader: Process {
        onExited: (exitCode) => root.ready = true

        stdout: StdioCollector {
            onStreamFinished: root.inputMonitorName = (this.text || "").trim()
        }
    }
}

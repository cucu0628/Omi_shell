import QtQuick
import Quickshell.Io

Item {
    id: controller

    property bool active: false
    property bool available: false
    property var values: [0, 0, 0, 0, 0, 0]
    readonly property string configPath: "/tmp/omi-shell-cava-" + Date.now() + "-" + Math.floor(Math.random() * 1000000) + ".conf"

    width: 0
    height: 0
    visible: false

    function syncProcess() {
        var shouldRun = available && active
        if (cavaProcess.running !== shouldRun) cavaProcess.running = shouldRun
    }

    onActiveChanged: syncProcess()
    onAvailableChanged: syncProcess()

    Process {
        id: availabilityCheck
        command: ["sh", "-c", "command -v cava >/dev/null 2>&1"]
        onExited: exitCode => controller.available = exitCode === 0
    }

    Process {
        id: cavaProcess
        command: ["sh", "-c", "cat > '" + controller.configPath + "' <<'EOF'\n"
            + "[general]\n"
            + "framerate=15\n"
            + "bars=6\n"
            + "autosens=0\n"
            + "sensitivity=30\n"
            + "lower_cutoff_freq=50\n"
            + "higher_cutoff_freq=12000\n\n"
            + "[output]\n"
            + "method=raw\n"
            + "raw_target=/dev/stdout\n"
            + "data_format=ascii\n"
            + "channels=mono\n"
            + "mono_option=average\n\n"
            + "[smoothing]\n"
            + "noise_reduction=35\n"
            + "integral=90\n"
            + "gravity=95\n"
            + "ignore=2\n"
            + "monstercat=1.5\n"
            + "EOF\n"
            + "trap \"rm -f '" + controller.configPath + "'\" EXIT\n"
            + "exec cava -p '" + controller.configPath + "' < /dev/null"]

        onRunningChanged: if (!running) controller.values = [0, 0, 0, 0, 0, 0]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var parts = data.split(";")
                if (parts.length < 6) return

                var nextValues = []
                for (var i = 0; i < 6; i++) nextValues.push(parseInt(parts[i], 10) || 0)
                for (var j = 0; j < 6; j++) {
                    if (nextValues[j] !== controller.values[j]) {
                        controller.values = nextValues
                        return
                    }
                }
            }
        }
    }

    Component.onCompleted: availabilityCheck.running = true
}

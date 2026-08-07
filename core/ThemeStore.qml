import QtQuick
import Quickshell.Io

Item {
    id: store

    property string background: "#1e1e2e"
    property string foreground: "#cdd6f4"
    property string accent: "#89b4fa"
    property string surface: "#181825"
    property string muted: "#9399b2"

    width: 0
    height: 0
    visible: false

    function updateColors(text) {
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "" || line.startsWith("#")) continue
            if (line.startsWith("env = BACKGROUND,")) background = line.split(",")[1].replace("##", "#")
            else if (line.startsWith("env = FOREGROUND,")) foreground = line.split(",")[1].replace("##", "#")
            else if (line.startsWith("env = BORDER_FOREGROUND,")) accent = line.split(",")[1].replace("##", "#")
            else if (line.startsWith("BACKGROUND=")) background = line.split("=")[1].replace("##", "#")
            else if (line.startsWith("FOREGROUND=")) foreground = line.split("=")[1].replace("##", "#")
            else if (line.startsWith("ACCENT=")) accent = line.split("=")[1].replace("##", "#")
            else if (line.startsWith("BORDER_FOREGROUND=")) accent = line.split("=")[1].replace("##", "#")
            else if (line.startsWith("SURFACE=")) surface = line.split("=")[1].replace("##", "#")
            else if (line.startsWith("MUTED=")) muted = line.split("=")[1].replace("##", "#")
        }
    }

    function load() {
        loader.command = ["sh", "-c", "sh \"$HOME/.config/quickshell/omi_shell/scripts/theme-read\""]
        loader.running = true
    }

    Process {
        id: loader
        stdout: StdioCollector { onStreamFinished: store.updateColors(this.text || "") }
    }

}

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string background: "#1e1e2e"
    property string foreground: "#cdd6f4"
    property string accent: "#89b4fa"
    property string surface: "#181825"
    property string muted: "#bac2de"
    property string outline: "#9399b2"

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
            else if (line.startsWith("MUTED=")) outline = line.split("=")[1].replace("##", "#")
            else if (line.startsWith("LIGHT_FOREGROUND=")) muted = line.split("=")[1].replace("##", "#")
        }
    }

    function loadThemeColors() {
        themeLoader.command = ["sh", "-c", "sh \"$HOME/.config/quickshell/vellum_shell/scripts/theme-read\""]
        themeLoader.running = true
    }

    property Process themeLoader: Process {
        stdout: StdioCollector {
            onStreamFinished: root.updateColors(this.text || "")
        }
    }
}

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string themeName: ""
    property string userHost: ""

    // Shell facts are exposed one by one rather than as a list so the popup can
    // interleave them with values it computes live (uptime, screens).
    property string shellVersion: ""
    property string quickshellVersion: ""
    property string moduleSummary: ""
    property string wallpaperName: ""
    property string configPath: "~/.config/quickshell/vellum_shell"

    function parseInfo(output) {
        var lines = (output || "").split("\n")

        themeName = ""
        userHost = ""
        shellVersion = ""
        quickshellVersion = ""
        moduleSummary = ""
        wallpaperName = ""

        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("\t")
            if (parts.length < 4) continue

            var section = parts[0]
            var item = { icon: parts[1], label: parts[2], value: parts.slice(3).join("\t") }
            if (item.value === "") continue

            if (section === "meta") {
                if (item.label === "Theme") themeName = item.value
                else if (item.label === "User") userHost = item.value
            } else if (section === "shell") {
                if (item.label === "Version") shellVersion = item.value
                else if (item.label === "Runtime") quickshellVersion = item.value
                else if (item.label === "Modules") moduleSummary = item.value
                else if (item.label === "Wallpaper") wallpaperName = item.value
            }
        }
    }

    function refreshInfo() {
        var cmd = [
            "dir=\"$HOME/.config/quickshell/vellum_shell\"",
            "theme=$(cat \"$dir/current-theme\" 2>/dev/null)",
            "[ -n \"$theme\" ] && printf 'meta\\t󰸌\\tTheme\\t%s\\n' \"$theme\"",
            "printf 'meta\\t󰀄\\tUser\\t%s@%s\\n' \"$USER\" \"$(hostname 2>/dev/null)\"",
            "gitsha=$(git -C \"$dir\" rev-parse --short HEAD 2>/dev/null)",
            "gitcount=$(git -C \"$dir\" rev-list --count HEAD 2>/dev/null)",
            "dirty=''",
            "[ -n \"$(git -C \"$dir\" status --porcelain 2>/dev/null)\" ] && dirty='+'",
            "if [ -n \"$gitsha\" ]; then printf 'shell\\t󰋼\\tVersion\\tr%s · %s%s\\n' \"$gitcount\" \"$gitsha\" \"$dirty\"; else printf 'shell\\t󰋼\\tVersion\\tunversioned\\n'; fi",
            "qsver=$(quickshell --version 2>/dev/null | head -1 | sed -E 's/ \\(revision.*//')",
            "[ -n \"$qsver\" ] && printf 'shell\\t󰒓\\tRuntime\\t%s\\n' \"$qsver\"",
            "qml=$(find \"$dir\" -name '*.qml' 2>/dev/null | wc -l)",
            "feat=$(find \"$dir/features\" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)",
            "[ \"$qml\" -gt 0 ] 2>/dev/null && printf 'shell\\t󰐱\\tModules\\t%s QML · %s features\\n' \"$qml\" \"$feat\"",
            "wp=$(cat \"$dir/current-wallpaper\" 2>/dev/null)",
            "[ -n \"$wp\" ] && printf 'shell\\t󰉉\\tWallpaper\\t%s\\n' \"$(basename \"$wp\")\""
        ].join("; ")
        fetcher.command = ["sh", "-c", cmd]
        fetcher.running = true
    }

    property Process fetcher: Process {
        stdout: StdioCollector { onStreamFinished: root.parseInfo(this.text || "") }
    }
}

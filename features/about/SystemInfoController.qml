import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var hardwareItems: []
    property var systemItems: []
    property string osName: "Linux"
    property string themeName: ""
    property string userHost: ""

    // Shell facts are exposed one by one rather than as a list so the popup can
    // interleave them with values it computes live (uptime, screens).
    property string shellVersion: ""
    property string quickshellVersion: ""
    property string moduleSummary: ""
    property string wallpaperName: ""
    property string configPath: "~/.config/quickshell/omi_shell"

    function parseInfo(output) {
        var hw = []
        var sys = []
        var lines = (output || "").split("\n")

        osName = "Linux"
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
                if (item.label === "OS") osName = item.value
                else if (item.label === "Theme") themeName = item.value
                else if (item.label === "User") userHost = item.value
            } else if (section === "shell") {
                if (item.label === "Version") shellVersion = item.value
                else if (item.label === "Runtime") quickshellVersion = item.value
                else if (item.label === "Modules") moduleSummary = item.value
                else if (item.label === "Wallpaper") wallpaperName = item.value
            } else if (section === "hardware") hw.push(item)
            else if (section === "system") sys.push(item)
        }

        hardwareItems = hw
        systemItems = sys
    }

    function refreshInfo() {
        var cmd = [
            "os=$(awk -F= '/^PRETTY_NAME=/{gsub(/\\\"/,\"\",$2); print $2}' /etc/os-release 2>/dev/null)",
            "[ -n \"$os\" ] || os=$(uname -s)",
            "printf 'meta\\t󰣇\\tOS\\t%s\\n' \"$os\"",
            "printf 'system\\t󰣇\\tOS\\t%s\\n' \"$os\"",
            "kernel=$(uname -sr 2>/dev/null)",
            "[ -n \"$kernel\" ] && printf 'system\\t󰌽\\tKernel\\t%s\\n' \"$kernel\"",
            "session=${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-Wayland}}",
            "[ -n \"$session\" ] && printf 'system\\t󰍹\\tSession\\t%s\\n' \"$session\"",
            "shell_name=$(basename \"$SHELL\" 2>/dev/null)",
            "[ -n \"$shell_name\" ] && printf 'system\\t󱆃\\tShell\\t%s\\n' \"$shell_name\"",
            "term=${TERMINAL:-kitty}",
            "[ -n \"$term\" ] && printf 'system\\t󰆍\\tTerminal\\t%s\\n' \"$term\"",
            "pkgs=$(pacman -Qq 2>/dev/null | wc -l)",
            "[ \"$pkgs\" -gt 0 ] 2>/dev/null && printf 'system\\t󰏖\\tPackages\\t%s total\\n' \"$pkgs\"",
            "up=$(uptime -p 2>/dev/null | sed 's/^up //')",
            "[ -n \"$up\" ] && printf 'system\\t󱫐\\tSystem Up\\t%s\\n' \"$up\"",
            "cpu=$(awk -F: '/model name/{gsub(/^ /,\"\",$2); print $2; exit}' /proc/cpuinfo 2>/dev/null)",
            "cpu=$(printf '%s' \"$cpu\" | sed -E 's/\\((R|TM|r|tm)\\)//g; s/ [0-9]+-Core Processor//; s/ Processor$//; s/ CPU$//; s/  +/ /g')",
            "cores=$(nproc 2>/dev/null)",
            "[ -n \"$cpu\" ] && printf 'hardware\\t󰻠\\tCPU\\t%s (%s)\\n' \"$cpu\" \"$cores\"",
            "lspci 2>/dev/null | awk -F': ' '/VGA|3D|Display/{gpu=$2; if (first == \"\") first=gpu; name=tolower(gpu); if (name ~ /radeon rx|radeon pro|geforce|quadro|tesla|arc a[0-9]/) {print gpu; found=1; exit}} END {if (!found && first != \"\") print first}' | sed -E 's/.*\\[Radeon (RX [^]]+)\\].*/\\1/; s/.*\\[(GeForce [^]]+)\\].*/\\1/; s/.*\\[(Arc [^]]+)\\].*/\\1/' | while IFS= read -r gpu; do [ -n \"$gpu\" ] && printf 'hardware\\t󰢮\\tGPU\\t%s\\n' \"$gpu\"; done",
            "mem=$(free -b 2>/dev/null | awk '/Mem:/{printf \"%.1f GiB / %.1f GiB\", $3/1024/1024/1024, $2/1024/1024/1024}')",
            "[ -n \"$mem\" ] && printf 'hardware\\t󰍛\\tMemory\\t%s\\n' \"$mem\"",
            "disk=$(df -h / 2>/dev/null | awk 'NR==2{print $3 \" / \" $2}')",
            "[ -n \"$disk\" ] && printf 'hardware\\t󰋊\\tDisk\\t%s\\n' \"$disk\"",
            "hyprctl monitors 2>/dev/null | awk '/^Monitor /{name=$2} /^[[:space:]]+[0-9]+x[0-9]+@/{split($1, mode, \"@\"); count++; printf \"hardware\\t󱄄\\tDisplay %d\\t%s · %s@%.0fHz\\n\", count, name, mode[1], mode[2]}'",
            "dir=\"$HOME/.config/quickshell/omi_shell\"",
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

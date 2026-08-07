import QtQuick
import Quickshell.Io

Item {
    id: controller

    property string activeCategory: ""
    property var activeSubmenu: []
    property bool isLoading: false
    property string currentDynamicIcon: ""
    property string currentDynamicCommandPrefix: ""
    property string currentDynamicPath: ""
    property string currentDynamicType: "default"

    width: 0
    height: 0
    visible: false

    Process {
        id: dynamicFetcher
        onExited: (exitCode) => {
            controller.isLoading = false
            dynamicTimeout.stop()
            if (exitCode !== 0) controller.activeSubmenu = []
        }

        stdout: StdioCollector {
            onStreamFinished: controller.loadDynamicOutput(this.text || "")
        }
    }

    Timer {
        id: dynamicTimeout
        interval: 3500
        onTriggered: {
            dynamicFetcher.running = false
            controller.isLoading = false
            if (controller.activeSubmenu.length === 0) controller.activeSubmenu = []
        }
    }

    function loadDynamicOutput(output) {
        if (currentDynamicType === "keybindings") {
            loadKeybindingsOutput(output)
            return
        }

        var out = (output || "").trim()
        if (out === "") {
            activeSubmenu = []
            return
        }

        var lines = out.split("\n")
        var newSub = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line !== "") {
                var displayName = line
                var value = line
                var separatorIndex = line.indexOf("|")
                if (separatorIndex >= 0) {
                    displayName = line.slice(0, separatorIndex).trim()
                    value = line.slice(separatorIndex + 1).trim()
                } else if (line.includes("/")) {
                    displayName = line.split("/").pop().replace(/\.[^/.]+$/, "").replace(/[-_]/g, " ")
                    displayName = displayName.replace(/\w\S*/g, (txt) => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase())
                }

                newSub.push({
                    name: displayName,
                    icon: currentDynamicIcon,
                    path: currentDynamicPath,
                    command: currentDynamicCommandPrefix + " \"" + value + "\""
                })
            }
        }
        activeSubmenu = newSub
    }

    function loadKeybindingsOutput(output) {
        var out = (output || "").trim()
        if (out === "") {
            activeSubmenu = []
            return
        }

        if (out.charAt(0) === "[") {
            loadKeybindingsJson(out)
            return
        }

        var lines = out.split("\n")
        var newSub = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "") continue

            var arrowIndex = line.indexOf("→")
            var shortcut = arrowIndex >= 0 ? line.slice(0, arrowIndex).trim() : line
            var action = arrowIndex >= 0 ? line.slice(arrowIndex + 1).trim() : ""

            newSub.push({
                name: shortcut,
                icon: "",
                path: action,
                readonly: true
            })
        }
        activeSubmenu = newSub
    }

    function modMaskLabel(mask) {
        var parts = []
        if (mask & 64) parts.push("SUPER")
        if (mask & 4) parts.push("CTRL")
        if (mask & 8) parts.push("ALT")
        if (mask & 1) parts.push("SHIFT")
        return parts.join(" + ")
    }

    function keyLabel(binding) {
        if (binding.key && binding.key !== "") return binding.key.replace("mouse:272", "LEFT MOUSE BUTTON").replace("mouse:273", "RIGHT MOUSE BUTTON")
        if (binding.keycode && binding.keycode !== 0) return "keycode " + binding.keycode
        return ""
    }

    function loadKeybindingsJson(output) {
        var parsed = []
        try {
            parsed = JSON.parse(output)
        } catch (error) {
            activeSubmenu = []
            return
        }

        var newSub = []
        for (var i = 0; i < parsed.length; i++) {
            var binding = parsed[i]
            var modifiers = modMaskLabel(binding.modmask || 0)
            var key = keyLabel(binding)
            var shortcut = modifiers !== "" && key !== "" ? modifiers + " + " + key : key
            var action = binding.description && binding.description !== "" ? binding.description : ((binding.dispatcher || "") + (binding.arg ? " " + binding.arg : ""))

            if (shortcut === "" && action === "") continue

            newSub.push({
                name: shortcut,
                icon: "",
                path: action,
                readonly: true
            })
        }
        activeSubmenu = newSub
    }

    function fetchDynamic(cmd, icon, prefix, path) {
        isLoading = true
        activeSubmenu = []
        currentDynamicIcon = icon
        currentDynamicCommandPrefix = prefix
        currentDynamicPath = path || activeCategory
        currentDynamicType = "default"
        dynamicTimeout.restart()
        dynamicFetcher.command = ["sh", "-c", cmd]
        dynamicFetcher.running = true
    }

    function fetchKeybindings(path) {
        isLoading = true
        activeSubmenu = []
        currentDynamicPath = path || activeCategory
        currentDynamicType = "keybindings"
        dynamicTimeout.restart()
        dynamicFetcher.command = ["hyprctl", "binds", "-j"]
        dynamicFetcher.running = true
    }
}

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property var entries: []
    property bool refreshPending: false

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/omi_shell"
    readonly property string imageDir: stateDir + "/cliphist-images"

    width: 0
    height: 0
    visible: false

    Component.onCompleted: refreshClipboard()

    function refreshClipboard() {
        if (fetcher.running) {
            refreshPending = true
            return
        }

        fetcher.command = ["sh", "-c", "mkdir -p " + shellQuote(imageDir) + "; cliphist list 2>/dev/null | head -n 100 | while IFS=\"$(printf '\\t')\" read -r id preview; do case \"$preview\" in '[[ binary data '*) format=$(printf '%s\\n' \"$preview\" | cut -d' ' -f6); case \"$format\" in png|jpg|jpeg|webp|gif|bmp|tiff) ;; *) format=bin ;; esac; path=" + shellQuote(imageDir) + "/cliphist-$id.$format; if [ ! -s \"$path\" ]; then tmp=\"$path.tmp\"; cliphist decode \"$id\" > \"$tmp\" && mv \"$tmp\" \"$path\" || rm -f \"$tmp\"; fi ;; esac; printf '%s\\t%s\\n' \"$id\" \"$preview\"; done"]
        fetcher.running = true
    }

    function normalize(value) {
        return (value || "").toString().toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
    }

    function filterEntries(value) {
        var words = normalize(value).split(/\s+/).filter((word) => word !== "")
        if (words.length === 0) return entries

        var result = []
        for (var i = 0; i < entries.length; i++) {
            var haystack = normalize(entries[i].title + " " + entries[i].subtitle)
            var matched = true
            for (var j = 0; j < words.length; j++) {
                if (haystack.indexOf(words[j]) < 0) {
                    matched = false
                    break
                }
            }
            if (matched) result.push(entries[i])
        }
        return result
    }

    function compactText(value) {
        return (value || "").replace(/\s+/g, " ").trim()
    }

    function imageExtension(preview) {
        var match = (preview || "").match(/^\[\[ binary data [^ ]+ [^ ]+ ([A-Za-z0-9]+)\b/)
        if (!match) return ""

        var extension = match[1].toLowerCase()
        return ["png", "jpg", "jpeg", "webp", "gif", "bmp", "tiff"].indexOf(extension) >= 0 ? extension : "bin"
    }

    function parseOutput(output) {
        var lines = (output || "").split("\n")
        var parsed = []

        for (var i = 0; i < lines.length; i++) {
            var separator = lines[i].indexOf("\t")
            if (separator < 1) continue

            var identifier = lines[i].slice(0, separator)
            var preview = lines[i].slice(separator + 1)
            var extension = imageExtension(preview)
            var isImage = extension !== ""

            parsed.push({
                identifier: identifier,
                title: isImage ? "Image clipboard" : compactText(preview),
                text: isImage ? "" : preview,
                subtitle: isImage ? "Clipboard image" : "Clipboard history",
                preview: isImage ? imageDir + "/cliphist-" + identifier + "." + extension : "",
                isImage: isImage,
                source: "cliphist"
            })
        }

        entries = parsed
    }

    function entryTypeLabel(item) {
        if (!item) return "EMPTY"
        if (item.isImage) return "IMAGE"
        return (item.text || "").length >= 100 ? "LONG TEXT" : "TEXT"
    }

    function previewSource(path) {
        if (!path) return ""
        if (path.startsWith("file:")) return path
        if (path.startsWith("/")) return "file://" + path
        return path
    }

    function activate(item) {
        if (!item) return
        activateProcess.command = ["sh", "-c", "cliphist decode " + shellQuote(item.identifier) + " | wl-copy"]
        activateProcess.running = true
    }

    function remove(item) {
        if (!item) return

        deleteProcess.command = ["sh", "-c", "printf '%s\\n' " + shellQuote(item.identifier) + " | cliphist delete; rm -f " + shellQuote(imageDir + "/cliphist-" + item.identifier) + ".*"]
        deleteProcess.running = true

        var nextEntries = []
        for (var i = 0; i < entries.length; i++) {
            if (entries[i].identifier !== item.identifier) nextEntries.push(entries[i])
        }
        entries = nextEntries
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    Timer {
        id: watchRefreshTimer
        interval: 120
        onTriggered: controller.refreshClipboard()
    }

    Process {
        id: fetcher
        onExited: {
            if (controller.refreshPending) {
                controller.refreshPending = false
                controller.refreshClipboard()
            }
        }
        stdout: StdioCollector {
            onStreamFinished: controller.parseOutput(this.text || "")
        }
    }

    Process {
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", "cliphist store && printf 'changed\\n'"]
        running: true
        stdout: SplitParser {
            onRead: watchRefreshTimer.restart()
        }
    }

    Process {
        command: ["wl-paste", "--type", "image", "--watch", "sh", "-c", "cliphist store && printf 'changed\\n'"]
        running: true
        stdout: SplitParser {
            onRead: watchRefreshTimer.restart()
        }
    }

    Process { id: activateProcess }
    Process { id: deleteProcess }
}

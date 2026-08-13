import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property var entries: []
    property bool refreshPending: false
    property var decodedPreviews: ({})
    property var decodeQueue: []

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/vellum-shell"
    readonly property string imageDir: stateDir + "/cliphist-images"
    readonly property string thumbnailDir: stateDir + "/cliphist-thumbnails"

    width: 0
    height: 0
    visible: false

    Component.onCompleted: refreshClipboard()

    function refreshClipboard() {
        if (fetcher.running) {
            refreshPending = true
            return
        }

        fetcher.command = ["sh", "-c", "mkdir -p " + shellQuote(imageDir) + "; cliphist list 2>/dev/null | head -n 100"]
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
                preview: isImage ? thumbnailDir + "/cliphist-" + identifier + ".png" : "",
                original: isImage ? imageDir + "/cliphist-" + identifier + "." + extension : "",
                isImage: isImage,
                source: "cliphist"
            })
        }

        entries = parsed
        prunePreviewCache(parsed)
    }

    function entryTypeLabel(item) {
        if (!item) return "EMPTY"
        if (item.isImage) return "IMAGE"
        return (item.text || "").length >= 100 ? "LONG TEXT" : "TEXT"
    }

    function previewSource(item) {
        if (!item || !item.isImage) return ""
        return decodedPreviews[item.identifier] || ""
    }

    function ensurePreview(item) {
        if (!item || !item.isImage || decodedPreviews[item.identifier]) return
        if (previewDecoder.running && previewDecoder.identifier === item.identifier) return
        for (var i = 0; i < decodeQueue.length; i++) {
            if (decodeQueue[i].identifier === item.identifier) return
        }
        decodeQueue = decodeQueue.concat([item])
        startNextDecode()
    }

    function startNextDecode() {
        if (previewDecoder.running || decodeQueue.length === 0) return
        var item = decodeQueue[0]
        decodeQueue = decodeQueue.slice(1)
        previewDecoder.identifier = item.identifier
        previewDecoder.outputPath = item.preview
        previewDecoder.command = ["sh", "-c", "mkdir -p " + shellQuote(imageDir) + " " + shellQuote(thumbnailDir) + "; original=" + shellQuote(item.original) + "; thumb=" + shellQuote(item.preview) + "; if [ ! -s \"$thumb\" ]; then raw=\"$original.tmp\"; out=\"$thumb.tmp.png\"; cliphist decode " + shellQuote(item.identifier) + " > \"$raw\" && magick \"$raw\" -auto-orient -thumbnail '136x112^' -gravity center -extent 136x112 -strip \"$out\" && mv \"$out\" \"$thumb\"; rm -f \"$raw\" \"$out\"; fi; [ -s \"$thumb\" ]"]
        previewDecoder.running = true
    }

    function prunePreviewCache(currentEntries) {
        var identifiers = " "
        for (var i = 0; i < currentEntries.length; i++) identifiers += currentEntries[i].identifier + " "
        cachePruner.command = ["sh", "-c", "keep=" + shellQuote(identifiers) + "; for dir in " + shellQuote(imageDir) + " " + shellQuote(thumbnailDir) + "; do [ -d \"$dir\" ] || continue; for path in \"$dir\"/cliphist-*; do [ -e \"$path\" ] || continue; name=${path##*/cliphist-}; id=${name%%.*}; case \"$keep\" in *\" $id \"*) ;; *) rm -f \"$path\" ;; esac; done; done"]
        if (!cachePruner.running) cachePruner.running = true
    }

    function activate(item) {
        if (!item) return
        activateProcess.command = ["sh", "-c", "cliphist decode " + shellQuote(item.identifier) + " | wl-copy"]
        activateProcess.running = true
    }

    function remove(item) {
        if (!item) return

        deleteProcess.command = ["sh", "-c", "printf '%s\\n' " + shellQuote(item.identifier) + " | cliphist delete; rm -f " + shellQuote(imageDir + "/cliphist-" + item.identifier) + ".* " + shellQuote(thumbnailDir + "/cliphist-" + item.identifier) + ".*"]
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

    Process {
        id: previewDecoder
        property string identifier: ""
        property string outputPath: ""
        onExited: exitCode => {
            if (exitCode === 0) {
                var next = Object.assign({}, controller.decodedPreviews)
                next[identifier] = "file://" + outputPath
                controller.decodedPreviews = next
            }
            controller.startNextDecode()
        }
    }

    Process { id: cachePruner }
}

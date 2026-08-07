import QtQuick
import Quickshell.Io

Item {
    id: controller

    property var theme: null
    property var wallpaperController: null
    property bool opened: false
    property string mode: "wallpaper"
    property string activeSection: "wallpaper"
    property var themeItems: []
    property var wallpaperItems: []
    property int selectedThemeIndex: 0
    property int selectedWallpaperIndex: 0
    property bool applying: false
    property bool sceneApplied: false
    property int loadGeneration: 0

    readonly property var selectedTheme: themeItems.length > 0 ? themeItems[Math.max(0, Math.min(selectedThemeIndex, themeItems.length - 1))] : null
    readonly property var selectedWallpaper: wallpaperItems.length > 0 ? wallpaperItems[Math.max(0, Math.min(selectedWallpaperIndex, wallpaperItems.length - 1))] : null

    signal focusRequested
    signal themeScrollRequested
    signal wallpaperScrollRequested

    width: 0
    height: 0
    visible: false

    onOpenedChanged: {
        if (opened) {
            closeTimer.stop()
            activeSection = mode === "theme" ? "theme" : "wallpaper"
            sceneApplied = false
            applying = false
            loadItems()
            focusRequested()
        }
    }

    function loadItems() {
        loadGeneration++
        themeItems = []
        wallpaperItems = []
        themeLoader.generation = loadGeneration
        wallpaperLoader.generation = loadGeneration
        themeLoader.command = ["sh", "-c", "sh \"$HOME/.config/quickshell/omi_shell/scripts/theme-list\""]
        wallpaperLoader.command = ["sh", "-c", "base=\"$HOME/.config/quickshell/omi_shell\"; bgdir=\"$HOME/Pictures/wallpapers\"; current_bg=\"\"; [ -r \"$base/current-wallpaper\" ] && current_bg=$(cat \"$base/current-wallpaper\"); [ -d \"$bgdir\" ] || exit 0; find \"$bgdir\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort | while IFS= read -r path; do name=$(basename \"$path\"); clean=${name%.*}; clean=${clean#omi-}; title=$(printf '%s\\n' \"$clean\" | tr '_-' ' ' | awk '{for (i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}'); marker=''; [ \"$path\" = \"$current_bg\" ] && marker='current'; printf '%s|%s|%s\\n' \"$title\" \"$path\" \"$marker\"; done"]
        themeLoader.running = true
        wallpaperLoader.running = true
    }

    function releaseResources() {
        loadGeneration++
        themeLoader.running = false
        wallpaperLoader.running = false
        themeItems = []
        wallpaperItems = []
    }

    function parseThemes(output) {
        var lines = (output || "").trim().split("\n")
        var parsed = []
        var currentIndex = 0
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim() === "") continue
            var parts = lines[i].split("|")
            parsed.push({
                name: parts[0] || "",
                slug: parts[1] || "",
                meta: parts[2] || "",
                background: parts[3] || "#1e1e2e",
                foreground: parts[4] || "#cdd6f4",
                accent: parts[5] || "#89b4fa",
                surface: parts[6] || "#181825",
                muted: parts[7] || "#9399b2",
                kind: parts[8] || "static"
            })
            if ((parts[2] || "") === "current") currentIndex = parsed.length - 1
        }
        selectedThemeIndex = currentIndex
        themeItems = parsed
        themeScrollRequested()
    }

    function parseWallpapers(output) {
        var lines = (output || "").trim().split("\n")
        var parsed = []
        var currentIndex = 0
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim() === "") continue
            var parts = lines[i].split("|")
            parsed.push({ name: parts[0] || "", path: parts[1] || "", meta: parts[2] || "" })
            if ((parts[2] || "") === "current") currentIndex = parsed.length - 1
        }
        selectedWallpaperIndex = currentIndex
        wallpaperItems = parsed
        wallpaperScrollRequested()
    }

    function imageSource(path) {
        if (!path) return ""
        if (path.startsWith("file:")) return path
        return path.startsWith("/") ? "file://" + path : ""
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function setSection(section) {
        activeSection = section
        if (section === "theme") themeScrollRequested()
        else wallpaperScrollRequested()
    }

    function moveSelection(delta) {
        if (activeSection === "theme") {
            selectedThemeIndex = Math.max(0, Math.min(selectedThemeIndex + delta, themeItems.length - 1))
            themeScrollRequested()
        } else {
            selectedWallpaperIndex = Math.max(0, Math.min(selectedWallpaperIndex + delta, wallpaperItems.length - 1))
            wallpaperScrollRequested()
        }
    }

    function selectDynamicTheme() {
        for (var i = 0; i < themeItems.length; i++) {
            if (themeItems[i].kind === "dynamic") {
                selectedThemeIndex = i
                setSection("theme")
                return
            }
        }
    }

    function applyScene() {
        if (!selectedTheme || !selectedWallpaper || applying) return
        applying = true
        sceneApplied = false

        if (theme) {
            theme.background = selectedTheme.background
            theme.foreground = selectedTheme.foreground
            theme.accent = selectedTheme.accent
            theme.surface = selectedTheme.surface
            theme.muted = selectedTheme.muted
        }
        if (wallpaperController) wallpaperController.setCurrentWallpaper(selectedWallpaper.path)

        var command = "base=\"$HOME/.config/quickshell/omi_shell\"; slug=" + shellQuote(selectedTheme.slug)
            + "; path=" + shellQuote(selectedWallpaper.path)
            + "; printf '%s\\n' \"$slug\" > \"$base/current-theme\""
            + "; printf '%s\\n' \"$path\" > \"$base/current-wallpaper\""
            + "; [ \"$slug\" = dynamic-matugen ] && sh \"$base/scripts/matugen-theme\" \"$path\" >/dev/null 2>&1 || true"
            + "; sh \"$base/scripts/kitty-theme\" >/dev/null 2>&1 || true"
            + "; sh \"$base/scripts/gtk-theme\" >/dev/null 2>&1 || true"
            + "; sh \"$base/scripts/hyprland-theme\" >/dev/null 2>&1 || true"
            + "; sh \"$base/scripts/zen-theme\" >/dev/null 2>&1 || true"
            + "; sh \"$base/scripts/btop-theme\" >/dev/null 2>&1 || true"
        applyProcess.command = ["sh", "-c", command]
        applyProcess.running = true
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            opened = false
            event.accepted = true
        } else if (event.key === Qt.Key_Tab) {
            setSection(activeSection === "wallpaper" ? "theme" : "wallpaper")
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers === Qt.ControlModifier)) {
            moveSelection(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers === Qt.ControlModifier)) {
            moveSelection(1)
            event.accepted = true
        } else if (event.key === Qt.Key_D) {
            selectDynamicTheme()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            applyScene()
            event.accepted = true
        }
    }

    Timer { id: closeTimer; interval: 520; onTriggered: controller.opened = false }

    Process {
        id: themeLoader
        property int generation: 0
        stdout: StdioCollector {
            onStreamFinished: {
                if (themeLoader.generation === controller.loadGeneration && controller.opened)
                    controller.parseThemes(this.text || "")
            }
        }
    }
    Process {
        id: wallpaperLoader
        property int generation: 0
        stdout: StdioCollector {
            onStreamFinished: {
                if (wallpaperLoader.generation === controller.loadGeneration && controller.opened)
                    controller.parseWallpapers(this.text || "")
            }
        }
    }
    Process {
        id: applyProcess
        onExited: {
            controller.applying = false
            controller.sceneApplied = true
            if (controller.wallpaperController) controller.wallpaperController.loadThemeColors()
            closeTimer.restart()
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: controller

    required property string shellDir
    property var screens: []
    property string currentWallpaper: shellDir + "/wallpapers/omi-mountain-tower.png"

    width: 0
    height: 0
    visible: false

    function load() {
        loader.command = ["sh", "-c", "base=\"$HOME/.config/quickshell/omi_shell\"; fallback=\"$base/wallpapers/omi-mountain-tower.png\"; path=\"\"; [ -r \"$base/current-wallpaper\" ] && path=$(cat \"$base/current-wallpaper\"); [ -r \"$path\" ] || path=\"$fallback\"; printf '%s' \"$path\""]
        loader.running = true
    }

    function setCurrentWallpaper(path) {
        if (path && path !== "") currentWallpaper = path
    }

    function source(path) {
        if (!path || path === "") return ""
        if (path.startsWith("file:")) return path
        return "file://" + path
    }

    Process {
        id: loader
        stdout: StdioCollector { onStreamFinished: controller.setCurrentWallpaper((this.text || "").trim()) }
    }


    Instantiator {
        model: controller.screens
        delegate: PanelWindow {
            id: wallpaperWindow
            required property var modelData

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "#000000"
            WlrLayershell.layer: WlrLayershell.Background
            WlrLayershell.namespace: "quickshell.wallpaper"
            WlrLayershell.exclusiveZone: -1

            Image {
                anchors.fill: parent
                source: controller.source(controller.currentWallpaper)
                sourceSize: Qt.size(width * wallpaperWindow.screen.devicePixelRatio, height * wallpaperWindow.screen.devicePixelRatio)
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                cache: false
            }

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.10
            }
        }
    }
}

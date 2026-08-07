import QtQuick
import Quickshell.Io

Item {
    id: controller

    required property string shellDir
    property string pendingMode: ""

    width: 0
    height: 0
    visible: false

    function capture(mode) {
        pendingMode = mode
        captureDelay.restart()
    }

    Timer {
        id: captureDelay
        interval: 40
        onTriggered: {
            captureProcess.command = [controller.shellDir + "/scripts/screenshot-capture", controller.pendingMode]
            captureProcess.running = true
        }
    }

    Process { id: captureProcess }
}

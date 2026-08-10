import QtQuick
import Quickshell.Io

// Quickshell only learns about a seek when the player emits the MPRIS "Seeked"
// signal, and several players emit it for DBus initiated seeks only. Reading
// the Position property straight off the bus keeps the timeline honest no
// matter where the seek came from; between reads the value is extrapolated so
// the display still ticks smoothly.
Item {
    id: controller

    property bool active: false
    property string dbusName: ""
    property string trackKey: ""
    property bool playing: false

    readonly property bool valid: baseStamp > 0
    property real position: 0

    property real baseSeconds: 0
    property real baseStamp: 0
    property int failures: 0
    property int generation: 0
    property int probeGeneration: -1

    readonly property bool probeAllowed: active && dbusName !== "" && failures < 3

    width: 0
    height: 0
    visible: false

    onDbusNameChanged: reset()
    onTrackKeyChanged: beginTrackChange()
    onActiveChanged: if (active) requestProbe()

    function reset() {
        baseSeconds = 0
        baseStamp = dbusName !== "" ? Date.now() : 0
        failures = 0
        position = 0
        generation++
        requestProbe()
    }

    function beginTrackChange() {
        failures = 0
        generation++
        adopt(0)
        requestProbe()
    }

    // Adopt a position we caused ourselves, so our own seeks show up instantly
    // instead of waiting for the next probe.
    function adopt(seconds) {
        baseSeconds = Math.max(0, seconds)
        baseStamp = Date.now()
        position = baseSeconds
        failures = 0
    }

    function requestProbe() {
        if (!probeAllowed || probe.running) return
        probeGeneration = generation
        probe.running = true
    }

    function applyProbe(text) {
        if (probeGeneration !== generation) {
            retryProbe.restart()
            return
        }
        var match = /int64\s+(-?\d+)/.exec(text || "")
        if (!match) {
            controller.failures += 1
            return
        }
        controller.failures = 0
        controller.adopt(parseInt(match[1], 10) / 1000000)
    }

    Timer {
        id: retryProbe
        interval: 0
        onTriggered: controller.requestProbe()
    }

    Process {
        id: probe
        command: ["gdbus", "call", "--session", "--dest", controller.dbusName,
            "--object-path", "/org/mpris/MediaPlayer2",
            "--method", "org.freedesktop.DBus.Properties.Get",
            "org.mpris.MediaPlayer2.Player", "Position"]
        onExited: {
            if (probeGeneration !== controller.generation)
                retryProbe.restart()
        }
        stdout: StdioCollector { onStreamFinished: controller.applyProbe(this.text || "") }
    }

    Timer {
        interval: 2000
        running: controller.probeAllowed
        repeat: true
        triggeredOnStart: true
        onTriggered: controller.requestProbe()
    }

    Timer {
        interval: 250
        running: controller.active && controller.valid && controller.playing
        repeat: true
        onTriggered: controller.position = controller.baseSeconds + (Date.now() - controller.baseStamp) / 1000
    }
}

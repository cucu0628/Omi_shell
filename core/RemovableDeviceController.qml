import QtQuick
import Quickshell.Io

Item {
    id: controller

    property var devices: []
    property string busyPath: ""
    property string errorMessage: ""
    property bool initialized: false
    readonly property int deviceCount: devices.length
    readonly property int mountedCount: devices.filter(device => device.mounted).length

    signal deviceAdded(string name)

    width: 0
    height: 0
    visible: false

    function displayName(entry, disk) {
        return entry.label || disk.label || disk.model || entry.name || "Removable device"
    }

    function firstMountpoint(entry) {
        var points = entry.mountpoints || []
        for (var i = 0; i < points.length; i++) {
            if (points[i]) return points[i]
        }
        return ""
    }

    function formatSize(bytes) {
        var value = Number(bytes || 0)
        if (value <= 0) return "Unknown size"
        var units = ["B", "KB", "MB", "GB", "TB"]
        var unit = 0
        while (value >= 1000 && unit < units.length - 1) {
            value /= 1000
            unit++
        }
        return (unit > 1 ? value.toFixed(value >= 10 ? 0 : 1) : Math.round(value)) + " " + units[unit]
    }

    function appendVolumes(result, disk, entries, removable) {
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i]
            var isRemovable = removable || entry.rm === true || entry.hotplug === true
                || entry.tran === "usb" || entry.tran === "mmc" || entry.tran === "firewire"
            var children = entry.children || []
            var filesystem = entry.fstype || ""

            if (isRemovable && filesystem !== "" && filesystem !== "swap") {
                var mountpoint = firstMountpoint(entry)
                result.push({
                    path: entry.path || "",
                    diskPath: disk.path || entry.path || "",
                    name: displayName(entry, disk),
                    model: disk.model || "Removable drive",
                    filesystem: filesystem,
                    size: formatSize(entry.size),
                    mountpoint: mountpoint,
                    mounted: mountpoint !== "",
                    transport: disk.tran || entry.tran || ""
                })
            }
            if (children.length > 0) appendVolumes(result, disk, children, isRemovable)
        }
    }

    function update(output) {
        var next = []
        try {
            var parsed = JSON.parse(output || "{}")
            var disks = parsed.blockdevices || []
            for (var i = 0; i < disks.length; i++) {
                var disk = disks[i]
                var removable = disk.rm === true || disk.hotplug === true
                    || disk.tran === "usb" || disk.tran === "mmc" || disk.tran === "firewire"
                appendVolumes(next, disk, [disk], removable)
            }
        } catch (error) {
            errorMessage = "Could not read removable devices"
            return
        }

        var previous = {}
        for (var j = 0; j < devices.length; j++) previous[devices[j].path] = true
        devices = next

        if (initialized) {
            for (var k = 0; k < next.length; k++) {
                if (!previous[next[k].path]) {
                    deviceAdded(next[k].name)
                    break
                }
            }
        }
        initialized = true
    }

    function refresh() {
        if (deviceFetcher.running) return
        deviceFetcher.command = ["lsblk", "--json", "--bytes", "--output", "PATH,NAME,LABEL,FSTYPE,SIZE,TYPE,RM,HOTPLUG,MOUNTPOINTS,MODEL,TRAN"]
        deviceFetcher.running = true
    }

    function runAction(command, path) {
        if (deviceAction.running) return
        errorMessage = ""
        busyPath = path
        deviceAction.command = command
        deviceAction.running = true
    }

    function mount(path) {
        runAction(["udisksctl", "mount", "--block-device", path], path)
    }

    function unmount(path) {
        runAction(["udisksctl", "unmount", "--block-device", path], path)
    }

    function powerOff(diskPath) {
        runAction(["udisksctl", "power-off", "--block-device", diskPath], diskPath)
    }

    function open(device) {
        if (!device || !device.mountpoint || opener.running) return
        opener.command = ["xdg-open", device.mountpoint]
        opener.running = true
    }

    Process {
        id: deviceFetcher
        stdout: StdioCollector { onStreamFinished: controller.update(this.text || "") }
    }

    Process {
        id: deviceAction
        property string failureText: ""

        onRunningChanged: if (running) failureText = ""
        onExited: exitCode => {
            controller.busyPath = ""
            if (exitCode !== 0) {
                var detail = failureText.trim().replace(/^Error mounting[^:]*:\s*/i, "")
                    .replace(/^Error unmounting[^:]*:\s*/i, "")
                controller.errorMessage = detail || "Device operation failed"
            }
            refreshDelay.restart()
        }
        stderr: StdioCollector { onStreamFinished: deviceAction.failureText = this.text || "" }
    }

    Process { id: opener }

    Timer {
        id: refreshDelay
        interval: 350
        onTriggered: controller.refresh()
    }

    Timer {
        interval: 2500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: controller.refresh()
    }
}

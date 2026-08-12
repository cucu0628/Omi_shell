import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: controller

    property var visibleWorkspaceIds: [1, 2, 3, 4, 5]
    property var occupiedWorkspaceIds: []

    width: 0
    height: 0
    visible: false

    Component.onCompleted: {
        updateFromService()
        if (!Hyprland.workspaces || Hyprland.workspaces.values.length === 0) refresh()
    }

    function refresh() {
        fetcher.command = ["hyprctl", "workspaces", "-j"]
        fetcher.running = true
    }

    function updateFromService() {
        var workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : []
        if (!workspaces || workspaces.length === 0) return
        applyState(workspaces)
    }

    function update(output) {
        var workspaces = []
        try {
            workspaces = JSON.parse(output || "[]")
        } catch (error) {
            return
        }
        applyState(workspaces)
    }

    function windowCount(workspace) {
        if (!workspace) return 0
        if (workspace.windows !== undefined) return workspace.windows
        if (workspace.toplevels && workspace.toplevels.values) return workspace.toplevels.values.length
        if (workspace.clients && workspace.clients.values) return workspace.clients.values.length
        return 0
    }

    function arraysEqual(left, right) {
        if (left.length !== right.length) return false
        for (var i = 0; i < left.length; i++) {
            if (left[i] !== right[i]) return false
        }
        return true
    }

    function applyState(workspaces) {
        var seen = {}
        var ids = [1, 2, 3, 4, 5]
        var occupied = []
        for (var base = 0; base < ids.length; base++) seen[ids[base]] = true

        var focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
        for (var i = 0; i < workspaces.length; i++) {
            var id = workspaces[i].id
            var windows = windowCount(workspaces[i])
            if (windows > 0) occupied.push(id)
            if (id > 5 && (windows > 0 || id === focusedId) && !seen[id]) {
                ids.push(id)
                seen[id] = true
            }
        }

        if (focusedId > 5 && !seen[focusedId]) ids.push(focusedId)
        ids.sort((a, b) => a - b)
        if (!arraysEqual(visibleWorkspaceIds, ids)) visibleWorkspaceIds = ids
        if (!arraysEqual(occupiedWorkspaceIds, occupied)) occupiedWorkspaceIds = occupied
    }

    function isOccupied(id) {
        for (var i = 0; i < occupiedWorkspaceIds.length; i++) {
            if (occupiedWorkspaceIds[i] === id) return true
        }
        return false
    }

    Process {
        id: fetcher
        stdout: StdioCollector { onStreamFinished: controller.update(this.text || "") }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            controller.updateFromService()
        }
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            controller.updateFromService()
        }
    }
}

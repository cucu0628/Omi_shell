import QtQuick
import Quickshell
import "."
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets

ShellRoot {
    id: shellRoot

    // Globális beállítások
    property int barHeight: 26
    property string preferredPlayerDbusName: ""
    property int audioVolumePercent: 0
    property var visibleWorkspaceIds: [1, 2, 3, 4, 5]
    property var occupiedWorkspaceIds: []
    property bool vpnActive: false
    property string vpnName: ""
    property var calendarNow: new Date()
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // Omarchy téma beolvasása
    FileView {
        id: themeFile
        path: homeDir + "/.config/omarchy/current/theme/gum.env.conf"
        blockLoading: true
        watchChanges: true
    }

    QtObject {
        id: theme
        property string background: "#1e1e2e"
        property string foreground: "#cdd6f4"
        property string accent: "#89b4fa"

        function updateColors() {
            var text = themeFile.text()
            var lines = text.split("\n")
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith("env = BACKGROUND,")) {
                    background = line.split(",")[1].replace("##", "#")
                } else if (line.startsWith("env = FOREGROUND,")) {
                    foreground = line.split(",")[1].replace("##", "#")
                } else if (line.startsWith("env = BORDER_FOREGROUND,")) {
                    accent = line.split(",")[1].replace("##", "#")
                }
            }
        }
    }

    Connections {
        target: themeFile
        function onLoadedChanged() {
            if (themeFile.loaded) {
                theme.updateColors()
            }
        }
    }

    Component.onCompleted: {
        if (themeFile.loaded) {
            theme.updateColors()
        }
        refreshAudioVolume()
        refreshVisibleWorkspaces()
        refreshVpnStatus()
    }

    Process {
        id: processLauncher
    }

    Process {
        id: workspaceFetcher
        stdout: StdioCollector {
            onStreamFinished: updateVisibleWorkspaces(this.text || "")
        }
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: refreshVisibleWorkspaces()
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            updateVisibleWorkspacesFromService()
            workspaceRefreshTimer.restart()
        }
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateVisibleWorkspacesFromService()
            workspaceRefreshTimer.restart()
        }
    }

    Timer {
        id: workspaceRefreshTimer
        interval: 120
        onTriggered: refreshVisibleWorkspaces()
    }

    function refreshVisibleWorkspaces() {
        workspaceFetcher.command = ["hyprctl", "workspaces", "-j"]
        workspaceFetcher.running = true
    }

    function updateVisibleWorkspacesFromService() {
        var workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : []
        if (!workspaces || workspaces.length === 0) return
        applyWorkspaceState(workspaces)
    }

    function updateVisibleWorkspaces(output) {
        var workspaces = []
        try {
            workspaces = JSON.parse(output || "[]")
        } catch (error) {
            return
        }
        applyWorkspaceState(workspaces)
    }

    function workspaceWindowCount(workspace) {
        if (!workspace) return 0
        if (workspace.windows !== undefined) return workspace.windows
        if (workspace.toplevels && workspace.toplevels.values) return workspace.toplevels.values.length
        if (workspace.clients && workspace.clients.values) return workspace.clients.values.length
        return 0
    }

    function applyWorkspaceState(workspaces) {
        var seen = {}
        var ids = [1, 2, 3, 4, 5]
        var occupied = []
        for (var base = 0; base < ids.length; base++) seen[ids[base]] = true

        var focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
        for (var i = 0; i < workspaces.length; i++) {
            var id = workspaces[i].id
            var windows = workspaceWindowCount(workspaces[i])
            if (windows > 0) occupied.push(id)
            if (id > 5 && (windows > 0 || id === focusedId) && !seen[id]) {
                ids.push(id)
                seen[id] = true
            }
        }

        if (focusedId > 5 && !seen[focusedId]) ids.push(focusedId)
        ids.sort((a, b) => a - b)
        visibleWorkspaceIds = ids
        occupiedWorkspaceIds = occupied
    }

    function isWorkspaceOccupied(id) {
        for (var i = 0; i < occupiedWorkspaceIds.length; i++) {
            if (occupiedWorkspaceIds[i] === id) return true
        }
        return false
    }

    function focusedScreen() {
        var monitor = Hyprland.focusedMonitor
        if (monitor && monitor.name) {
            for (var i = 0; i < uniqueScreens.length; i++) {
                if (uniqueScreens[i] && uniqueScreens[i].name === monitor.name) return uniqueScreens[i]
            }
        }
        return uniqueScreens.length > 0 ? uniqueScreens[0] : null
    }

    Process {
        id: audioVolumeFetcher
        stdout: StdioCollector {
            onStreamFinished: {
                var match = (this.text || "").match(/Volume:\s+([0-9.]+)/)
                if (match) audioVolumePercent = Math.round(parseFloat(match[1]) * 100)
            }
        }
    }

    Process {
        id: vpnStatusFetcher
        stdout: StdioCollector {
            onStreamFinished: updateVpnStatus(this.text || "")
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: refreshAudioVolume()
    }

    Timer {
        interval: 12000
        running: true
        repeat: true
        onTriggered: refreshVpnStatus()
    }

    Timer {
        id: audioRefreshTimer
        interval: 80
        onTriggered: refreshAudioVolume()
    }

    function refreshAudioVolume() {
        audioVolumeFetcher.command = ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        audioVolumeFetcher.running = true
    }

    function refreshVpnStatus() {
        vpnStatusFetcher.command = ["nmcli", "-t", "-f", "TYPE,NAME", "connection", "show", "--active"]
        vpnStatusFetcher.running = true
    }

    function updateVpnStatus(output) {
        var lines = (output || "").trim().split("\n")
        var activeName = ""
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split(":")
            if (parts.length >= 2 && (parts[0] === "vpn" || parts[0] === "wireguard")) {
                activeName = parts.slice(1).join(":")
                break
            }
        }
        vpnActive = activeName !== ""
        vpnName = activeName
    }

    function toggleCenterPopup(nextScreen) {
        var openHere = mediaPopup.opened && nextScreen && mediaPopup.screen === nextScreen
        calendarNow = new Date()
        calendarPopup.opened = false
        audioPopup.opened = false
        if (nextScreen) mediaPopup.screen = nextScreen
        mediaPopup.opened = !openHere
    }

    function toggleNotificationsDnd() {
        notifications.dnd = !notifications.dnd
    }

    function setMenuOpen(open, nextScreen) {
        if (open) {
            appLauncher.opened = false
            clipboardHistory.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            if (nextScreen) omarchyMenu.screen = nextScreen
        }
        omarchyMenu.opened = open
    }

    function setLauncherOpen(open) {
        if (open) {
            omarchyMenu.opened = false
            clipboardHistory.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
        }
        appLauncher.opened = open
    }

    function setClipboardOpen(open) {
        if (open) {
            omarchyMenu.opened = false
            appLauncher.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
        }
        clipboardHistory.opened = open
    }

    function setThemeSwitcherOpen(open, nextMode) {
        if (open) {
            omarchyMenu.opened = false
            appLauncher.opened = false
            clipboardHistory.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            themeSwitcher.mode = nextMode
        }
        themeSwitcher.opened = open
    }

    function setPowerMenuOpen(open) {
        if (open) {
            omarchyMenu.opened = false
            appLauncher.opened = false
            clipboardHistory.opened = false
            themeSwitcher.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
        }
        powerMenu.opened = open
    }

    function setCalendarOpen(open, nextScreen) {
        if (open) {
            omarchyMenu.opened = false
            appLauncher.opened = false
            clipboardHistory.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            if (nextScreen) calendarPopup.screen = nextScreen
        }
        calendarPopup.opened = open
    }

    function setAudioOpen(open, nextScreen) {
        if (open) {
            omarchyMenu.opened = false
            appLauncher.opened = false
            clipboardHistory.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            mediaPopup.opened = false
            aboutPopup.opened = false
            if (nextScreen) audioPopup.screen = nextScreen
        }
        audioPopup.opened = open
    }

    function setAboutOpen(open, nextScreen) {
        if (open) {
            omarchyMenu.opened = false
            appLauncher.opened = false
            clipboardHistory.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            if (nextScreen) aboutPopup.screen = nextScreen
        }
        aboutPopup.opened = open
    }

    IpcHandler {
        target: "menu"

        function toggle(): void {
            var targetScreen = focusedScreen()
            setMenuOpen(!(omarchyMenu.opened && targetScreen && omarchyMenu.screen === targetScreen), targetScreen)
        }

        function open(): void {
            setMenuOpen(true, focusedScreen())
        }

        function close(): void {
            setMenuOpen(false)
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            setLauncherOpen(!appLauncher.opened)
        }

        function open(): void {
            setLauncherOpen(true)
        }

        function close(): void {
            setLauncherOpen(false)
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            setClipboardOpen(!clipboardHistory.opened)
        }

        function open(): void {
            setClipboardOpen(true)
        }

        function close(): void {
            setClipboardOpen(false)
        }
    }

    IpcHandler {
        target: "style"

        function theme(): void {
            setThemeSwitcherOpen(true, "theme")
        }

        function wallpaper(): void {
            setThemeSwitcherOpen(true, "wallpaper")
        }

        function close(): void {
            setThemeSwitcherOpen(false, themeSwitcher.mode)
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            setPowerMenuOpen(!powerMenu.opened)
        }

        function open(): void {
            setPowerMenuOpen(true)
        }

        function close(): void {
            setPowerMenuOpen(false)
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            toggleNotificationsDnd()
        }
    }

    IpcHandler {
        target: "audio"

        function toggle(): void {
            setAudioOpen(!audioPopup.opened)
        }

        function open(): void {
            setAudioOpen(true)
        }

        function close(): void {
            setAudioOpen(false)
        }
    }

    IpcHandler {
        target: "about"

        function toggle(): void {
            var targetScreen = focusedScreen()
            setAboutOpen(!(aboutPopup.opened && targetScreen && aboutPopup.screen === targetScreen), targetScreen)
        }

        function open(): void {
            setAboutOpen(true, focusedScreen())
        }

        function close(): void {
            setAboutOpen(false)
        }
    }

    // ÚJ: Omarchy Menü
    Menu {
        id: omarchyMenu
        theme: theme
    }

    Launcher {
        id: appLauncher
        theme: theme
    }

    Clipboard {
        id: clipboardHistory
        theme: theme
    }

    ThemeSwitcher {
        id: themeSwitcher
        theme: theme
    }

    PowerMenu {
        id: powerMenu
        theme: theme
    }

    CalendarPopup {
        id: calendarPopup
        theme: theme
    }

    AudioPopup {
        id: audioPopup
        theme: theme
    }

    AboutPopup {
        id: aboutPopup
        theme: theme
    }

    Notifications {
        id: notifications
        theme: theme
    }

    // AGRESSZÍV MONITOR SZŰRÉS (Csak egyedi nevű monitorok)
    readonly property var uniqueScreens: {
        var screens = Quickshell.screens
        var seenNames = {}
        var result = []
        for (var i = 0; i < screens.length; i++) {
            var s = screens[i]
            if (s && s.name && !seenNames[s.name]) {
                seenNames[s.name] = true
                result.push(s)
            }
        }
        return result
    }

    property var activePlayer: null

    function isBrowserPlayer(player) {
        if (!player) return false
        var name = ((player.identity || "") + " " + (player.dbusName || "")).toLowerCase()
        return name.indexOf("firefox") !== -1
            || name.indexOf("zen") !== -1
            || name.indexOf("chromium") !== -1
            || name.indexOf("chrome") !== -1
            || name.indexOf("brave") !== -1
            || name.indexOf("vivaldi") !== -1
            || name.indexOf("edge") !== -1
            || name.indexOf("browser") !== -1
    }

    function chooseActivePlayer() {
        var players = Mpris.players.values
        if (players.length === 0) return null

        // Browsers expose noisy MPRIS sessions for hover previews. Prefer real
        // media players first, even if a browser claims to be playing.
        for (var i = 0; i < players.length; i++) {
            if (!isBrowserPlayer(players[i]) && players[i].playbackState === MprisPlaybackState.Playing) {
                preferredPlayerDbusName = players[i].dbusName
                return players[i]
            }
        }

        if (preferredPlayerDbusName !== "") {
            for (var j = 0; j < players.length; j++) {
                if (players[j].dbusName === preferredPlayerDbusName) {
                    return players[j]
                }
            }
        }

        for (var k = 0; k < players.length; k++) {
            if (!isBrowserPlayer(players[k]) && (players[k].trackTitle !== "" || players[k].trackArtist !== "")) {
                preferredPlayerDbusName = players[k].dbusName
                return players[k]
            }
        }

        if (activePlayer) return activePlayer

        for (var l = 0; l < players.length; l++) {
            if (players[l].playbackState === MprisPlaybackState.Playing) {
                preferredPlayerDbusName = players[l].dbusName
                return players[l]
            }
        }

        return null
    }

    function updateActivePlayer() {
        activePlayer = chooseActivePlayer()
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: updateActivePlayer()
    }

    function volumePercent() {
        return audioVolumePercent
    }

    // TOPBAR LÉTREHOZÁSA (DMS stílusú Instantiatorral)
    Instantiator {
        model: shellRoot.uniqueScreens
        delegate: PanelWindow {
            id: barWindow
            screen: modelData
            
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: shellRoot.barHeight
            color: theme.background
            WlrLayershell.exclusiveZone: shellRoot.barHeight

            Item {
                anchors.fill: parent

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: theme.accent
                    opacity: 0.55
                }
                
                // BAL OLDAL
                Row {
                    anchors.left: parent.left
                    height: parent.height
                    
                    Rectangle {
                        id: menuItem
                        property bool menuOpenOnThisScreen: omarchyMenu.opened && omarchyMenu.screen === barWindow.screen
                        width: 30
                        height: parent.height
                        color: "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: theme.accent
                            opacity: menuMouse.containsMouse || menuItem.menuOpenOnThisScreen ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\ue900"
                            font.family: "omarchy"
                            font.pixelSize: 14
                            color: menuMouse.containsMouse || menuItem.menuOpenOnThisScreen ? theme.accent : theme.foreground
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: menuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                setMenuOpen(!(omarchyMenu.opened && omarchyMenu.screen === barWindow.screen), barWindow.screen)
                            }
                        }
                    }

                    Repeater {
                        model: shellRoot.visibleWorkspaceIds
                        Rectangle {
                            width: 25
                            height: parent.height
                            color: "transparent"
                            property int wsId: modelData
                            property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                            property bool isOccupied: shellRoot.isWorkspaceOccupied(wsId)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: isFocused ? 2 : 1
                                color: theme.accent
                                opacity: wsMouse.containsMouse || isFocused ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: wsId.toString()
                                color: wsMouse.containsMouse || isFocused ? theme.accent : (isOccupied ? Qt.lighter(theme.foreground, 1.25) : theme.foreground)
                                opacity: isFocused || isOccupied || wsMouse.containsMouse ? 1 : 0.62
                                font.pixelSize: 12
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            }
                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Hyprland.dispatch("workspace " + wsId)
                                }
                            }
                        }
                    }
                }

                // KÖZÉPSŐ ÓRA + MÉDIA
                Item {
                    id: centerCluster
                    property bool centerOpenOnThisScreen: (mediaPopup.opened && mediaPopup.screen === barWindow.screen) || (calendarPopup.opened && calendarPopup.screen === barWindow.screen)
                    anchors.centerIn: parent
                    width: centerContent.implicitWidth + 22
                    height: parent.height
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 2
                        color: theme.accent
                        opacity: centerMouse.containsMouse || centerCluster.centerOpenOnThisScreen ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 3
                        anchors.bottomMargin: 3
                        color: "transparent"
                        border.color: "transparent"
                        border.width: 0
                        radius: 0
                    }

                    Row {
                        id: centerContent
                        anchors.centerIn: parent
                        height: parent.height
                        spacing: 7

                        Text {
                            width: 16
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: shellRoot.activePlayer && shellRoot.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰐊" : "󰝚"
                            color: centerMouse.containsMouse || centerCluster.centerOpenOnThisScreen ? theme.accent : theme.foreground
                            font.pixelSize: 13
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Rectangle {
                            width: 1
                            height: 11
                            anchors.verticalCenter: parent.verticalCenter
                            color: theme.accent
                            opacity: centerMouse.containsMouse || centerCluster.centerOpenOnThisScreen ? 0.65 : 0.35
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            id: clockDisplay
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            color: centerMouse.containsMouse || centerCluster.centerOpenOnThisScreen ? theme.accent : theme.foreground
                            font.pixelSize: 12
                            font.letterSpacing: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: {
                                    var d = new Date()
                                    var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                                    clockDisplay.text = days[d.getDay()] + " " + d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0')
                                }
                                Component.onCompleted: triggered()
                            }
                        }
                    }

                    MouseArea {
                        id: centerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleCenterPopup(barWindow.screen)
                    }
                }

                // JOBB OLDAL
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    height: parent.height
                    spacing: 12
                    Item {
                        id: trayContainer
                        height: parent.height
                        property bool expanded: false
                        property bool hasItems: trayRepeater.count > 0
                        visible: hasItems
                        width: hasItems && expanded ? (18 + trayExpander.implicitWidth + 10) : 18
                        clip: true
                        onHasItemsChanged: if (!hasItems) expanded = false
                        Behavior on width {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                        MouseArea {
                            id: trayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: if (trayContainer.hasItems) trayContainer.expanded = true
                            onExited: trayContainer.expanded = false
                            acceptedButtons: Qt.NoButton
                        }
                        Row {
                            height: parent.height
                            spacing: 10
                            Text {
                                width: 18
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: trayContainer.expanded ? "" : ""
                                color: trayMouse.containsMouse && trayContainer.hasItems ? theme.accent : (trayContainer.hasItems ? theme.foreground : "#9f8f7c")
                                opacity: trayContainer.hasItems ? 1 : 0.45
                                font.pixelSize: 12
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            Row {
                                id: trayExpander
                                height: parent.height
                                spacing: 10
                                opacity: trayContainer.expanded ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 170
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Repeater {
                                    id: trayRepeater
                                    model: SystemTray.items
                                    Item {
                                        id: trayItem
                                        width: 18
                                        height: parent.height
                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 16
                                            height: 16
                                            source: modelData.icon || ""
                                            visible: source !== ""
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰀻"
                                            font.family: "omarchy"
                                            font.pixelSize: 13
                                            color: theme.foreground
                                            visible: !modelData.icon || modelData.icon === ""
                                        }
                                        QsMenuOpener {
                                            id: menuOpener
                                            menu: modelData.menu
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onClicked: (mouse) => {
                                                if (mouse.button === Qt.LeftButton) {
                                                    modelData.activate()
                                                } else {
                                                    var pos = trayItem.mapToGlobal(0, 0)
                                                    trayMenu.screen = barWindow.screen
                                                    trayMenu.menuModel = menuOpener.children
                                                    trayMenu.menuX = pos.x
                                                    trayMenu.visible = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        width: 18
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰤨"
                        color: wifiMouse.containsMouse ? theme.accent : theme.foreground
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: theme.accent
                            opacity: wifiMouse.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            id: wifiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                processLauncher.command = ["omarchy-launch-wifi"]
                                processLauncher.running = true
                            }
                        }
                    }
                    Item {
                        width: vpnMouse.containsMouse && shellRoot.vpnActive ? Math.min(115, 24 + vpnLabel.implicitWidth) : 18
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: theme.accent
                            opacity: vpnMouse.containsMouse || shellRoot.vpnActive ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5

                            Text {
                                width: 18
                                height: shellRoot.barHeight
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: shellRoot.vpnActive ? "󰦝" : "󰦜"
                                color: vpnMouse.containsMouse || shellRoot.vpnActive ? theme.accent : theme.foreground
                                font.pixelSize: 14
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                id: vpnLabel
                                text: shellRoot.vpnName
                                color: theme.accent
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: vpnMouse.containsMouse && shellRoot.vpnActive ? 1 : 0
                                elide: Text.ElideRight
                                width: Math.min(86, implicitWidth)
                                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            }
                        }

                        MouseArea {
                            id: vpnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                processLauncher.command = ["sh", "-c", "command -v protonvpn-app >/dev/null 2>&1 && protonvpn-app || nm-connection-editor"]
                                processLauncher.running = true
                            }
                        }
                    }
                    Item {
                        id: audioItem
                        property bool audioOpenOnThisScreen: audioPopup.opened && audioPopup.screen === barWindow.screen
                        width: audioMouse.containsMouse || audioOpenOnThisScreen ? 54 : 22
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: theme.accent
                            opacity: audioMouse.containsMouse || audioItem.audioOpenOnThisScreen ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5

                            Text {
                                width: 18
                                height: shellRoot.barHeight
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.muted ? "" : ""
                                color: audioMouse.containsMouse || audioItem.audioOpenOnThisScreen ? theme.accent : theme.foreground
                                font.pixelSize: 14
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                text: volumePercent() + "%"
                                color: theme.accent
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: audioMouse.containsMouse || audioItem.audioOpenOnThisScreen ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            }
                        }

                        MouseArea {
                            id: audioMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onWheel: (wheel) => {
                                processLauncher.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", wheel.angleDelta.y > 0 ? "5%+" : "5%-"]
                                processLauncher.running = true
                                audioRefreshTimer.restart()
                                wheel.accepted = true
                            }
                            onClicked: {
                                setAudioOpen(!(audioPopup.opened && audioPopup.screen === barWindow.screen), barWindow.screen)
                            }
                        }
                    }
                    Text {
                        width: 18
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: notifications.dnd ? "󰂛" : (notifications.hasToast ? "󰂚" : "󰂞")
                        color: notificationMouse.containsMouse || notifications.dnd || notifications.hasToast ? theme.accent : theme.foreground
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: theme.accent
                            opacity: notificationMouse.containsMouse || notifications.dnd || notifications.hasToast ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            id: notificationMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toggleNotificationsDnd()
                        }
                    }
                    Text {
                        width: 18
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰍛"
                        color: btopMouse.containsMouse ? theme.accent : theme.foreground
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: theme.accent
                            opacity: btopMouse.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            id: btopMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                processLauncher.command = ["omarchy-launch-or-focus-tui", "btop"]
                                processLauncher.running = true
                            }
                        }
                    }
                    Text {
                        width: 18
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰐥"
                        color: powerMouse.containsMouse || powerMenu.opened ? theme.accent : theme.foreground
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: theme.accent
                            opacity: powerMouse.containsMouse || powerMenu.opened ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: setPowerMenuOpen(!powerMenu.opened)
                        }
                    }
                }
            }
        }
    }

    MediaPopup {
        id: mediaPopup
        theme: theme
        barHeight: shellRoot.barHeight
        activePlayer: shellRoot.activePlayer
        calendarNow: shellRoot.calendarNow
        monthNames: shellRoot.monthNames
        dayNames: shellRoot.dayNames
    }

    TrayMenu {
        id: trayMenu
        theme: theme
        barHeight: shellRoot.barHeight
    }
}

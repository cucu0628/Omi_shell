import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "app" as App
import "core" as Core
import "features/about" as AboutFeature
import "features/appearance" as AppearanceFeature
import "features/audio" as AudioFeature
import "features/bar" as BarUi
import "features/clipboard" as ClipboardFeature
import "features/launcher" as LauncherFeature
import "features/lock" as LockFeature
import "features/media" as MediaFeature
import "features/menu" as MenuFeature
import "features/bluetooth" as BluetoothFeature
import "features/network" as NetworkFeature
import "features/notifications" as NotificationFeature
import "features/osd" as OsdFeature
import "features/polkit" as PolkitFeature
import "features/power" as PowerFeature
import "features/screenshot" as ScreenshotFeature
import "features/tray" as TrayFeature
import "features/vpn" as VpnFeature

ShellRoot {
    id: shellRoot

    // Globális beállítások
    property int barHeight: 26
    property alias preferredPlayerDbusName: mprisController.preferredPlayerDbusName
    property alias audioVolumePercent: audioSummaryController.volumePercent
    property alias audioMuted: audioSummaryController.muted
    property alias visibleWorkspaceIds: workspaceController.visibleWorkspaceIds
    property alias occupiedWorkspaceIds: workspaceController.occupiedWorkspaceIds
    property alias vpnActive: vpnController.active
    property alias vpnName: vpnController.name
    property alias networkType: networkStatusController.connectionType
    property alias currentWallpaper: wallpaperStore.currentWallpaper
    property alias activePlayer: mprisController.activePlayer
    property var calendarNow: new Date()
    property bool audioOsdReady: false
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string shellDir: homeDir + "/.config/quickshell/omi_shell"
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    Core.ThemeStore {
        id: theme
    }
    readonly property var shellTheme: theme

    Core.WallpaperController {
        id: wallpaperStore
        shellDir: shellRoot.shellDir
        screens: shellRoot.uniqueScreens
    }

    Core.WorkspaceController {
        id: workspaceController
    }

    Core.AudioSummaryController {
        id: audioSummaryController
        onSinkChanged: audioSinkRefreshTimer.restart()
    }

    Core.VpnController {
        id: vpnController
        networkController: networkStatusController
    }

    Core.NetworkStatusController {
        id: networkStatusController
    }

    Core.BluetoothStatusController {
        id: bluetoothStatusController
    }

    Core.BatteryStatusController {
        id: batteryStatusController
    }

    Core.MprisController {
        id: mprisController
    }

    Core.CavaController {
        id: cavaController
        active: shellRoot.activePlayer && shellRoot.activePlayer.playbackState === MprisPlaybackState.Playing
    }

    function loadThemeColors() { theme.load() }
    function loadCurrentWallpaper() { wallpaperStore.load() }
    function setCurrentWallpaper(path) { wallpaperStore.setCurrentWallpaper(path) }
    function wallpaperSource(path) { return wallpaperStore.source(path) }

    Component.onCompleted: {
        loadThemeColors()
        loadCurrentWallpaper()
        refreshVisibleWorkspaces()
        refreshVpnStatus()
        audioOsdReadyTimer.start()
    }

    onAudioVolumePercentChanged: showVolumeOsd()
    onAudioMutedChanged: showVolumeOsd()

    function showVolumeOsd() {
        if (!audioOsdReady) return
        volumeOsd.showVolume(audioVolumePercent, audioMuted, focusedScreen())
    }

    Timer {
        id: audioOsdReadyTimer
        interval: 500
        onTriggered: shellRoot.audioOsdReady = true
    }

    Timer {
        id: audioSinkRefreshTimer
        interval: 200
        onTriggered: shellRoot.showVolumeOsd()
    }

    Process {
        id: processLauncher
    }

    function launchBarCommand(command) {
        processLauncher.command = command
        processLauncher.running = true
    }

    function refreshVisibleWorkspaces() { workspaceController.refresh() }
    function updateVisibleWorkspacesFromService() { workspaceController.updateFromService() }
    function updateVisibleWorkspaces(output) { workspaceController.update(output) }
    function workspaceWindowCount(workspace) { return workspaceController.windowCount(workspace) }
    function applyWorkspaceState(workspaces) { workspaceController.applyState(workspaces) }
    function isWorkspaceOccupied(id) { return workspaceController.isOccupied(id) }

    function focusedScreen() {
        var monitor = Hyprland.focusedMonitor
        if (monitor && monitor.name) {
            for (var i = 0; i < uniqueScreens.length; i++) {
                if (uniqueScreens[i] && uniqueScreens[i].name === monitor.name) return uniqueScreens[i]
            }
        }
        return uniqueScreens.length > 0 ? uniqueScreens[0] : null
    }

    function refreshVpnStatus() { vpnController.refresh() }

    function toggleCenterPopup(nextScreen) { popupCoordinator.toggleCenterPopup(nextScreen) }
    function toggleNotificationsDnd() { popupCoordinator.toggleNotificationsDnd() }
    function setNotificationsOpen(open, nextScreen) { popupCoordinator.setNotificationsOpen(open, nextScreen) }
    function setMenuOpen(open, nextScreen) { popupCoordinator.setMenuOpen(open, nextScreen) }
    function setLauncherOpen(open, nextScreen) { popupCoordinator.setLauncherOpen(open, nextScreen) }
    function setClipboardOpen(open, nextScreen) { popupCoordinator.setClipboardOpen(open, nextScreen) }
    function setThemeSwitcherOpen(open, nextMode, nextScreen) { popupCoordinator.setThemeSwitcherOpen(open, nextMode, nextScreen) }
    function setPowerMenuOpen(open, nextScreen) { popupCoordinator.setPowerMenuOpen(open, nextScreen) }
    function setAudioOpen(open, nextScreen) { popupCoordinator.setAudioOpen(open, nextScreen) }
    function setAboutOpen(open, nextScreen) { popupCoordinator.setAboutOpen(open, nextScreen) }
    function captureScreenshot(mode) {
        screenshotController.capture(mode)
    }

    // Popup shells stay lightweight while their full object trees are unloaded.
    App.LazyPopup {
        id: omarchyMenu
        popupComponent: Component {
            MenuFeature.MenuPopup { theme: shellRoot.shellTheme }
        }
    }

    App.LazyPopup {
        id: appLauncher
        loaded: true
        unloadOnClose: false
        popupComponent: Component {
            LauncherFeature.LauncherPopup {
                theme: shellRoot.shellTheme
                screen: appLauncher.screen
            }
        }
    }

    ClipboardFeature.ClipboardController {
        id: clipboardStore
    }

    App.LazyPopup {
        id: clipboardHistory
        popupComponent: Component {
            ClipboardFeature.ClipboardPopup {
                theme: shellRoot.shellTheme
                clipboardController: clipboardStore
                screen: clipboardHistory.screen
            }
        }
    }

    App.LazyPopup {
        id: themeSwitcher
        popupComponent: Component {
            AppearanceFeature.AppearanceStudio {
                theme: shellRoot.shellTheme
                wallpaperController: shellRoot
                mode: themeSwitcher.mode
                screen: themeSwitcher.screen
            }
        }
    }

    App.LazyPopup {
        id: powerMenu
        popupComponent: Component {
            PowerFeature.PowerMenu { theme: shellRoot.shellTheme }
        }
    }

    App.LazyPopup {
        id: audioPopup
        popupComponent: Component {
            AudioFeature.AudioPopup {
                theme: shellRoot.shellTheme
                screen: audioPopup.screen
            }
        }
    }

    App.LazyPopup {
        id: networkPopup
        popupComponent: Component {
            NetworkFeature.NetworkPopup {
                theme: shellRoot.shellTheme
                statusController: networkStatusController
                screen: networkPopup.screen
            }
        }
    }

    App.LazyPopup {
        id: bluetoothPopup
        popupComponent: Component {
            BluetoothFeature.BluetoothPopup {
                theme: shellRoot.shellTheme
                statusController: bluetoothStatusController
                screen: bluetoothPopup.screen
            }
        }
    }

    App.LazyPopup {
        id: vpnPopup
        popupComponent: Component {
            VpnFeature.VpnPopup {
                theme: shellRoot.shellTheme
                controller: vpnController
                screen: vpnPopup.screen
            }
        }
    }

    App.LazyPopup {
        id: aboutPopup
        popupComponent: Component {
            AboutFeature.AboutPopup {
                theme: shellRoot.shellTheme
                screen: aboutPopup.screen
            }
        }
    }

    ScreenshotFeature.ScreenshotController {
        id: screenshotController
        shellDir: shellRoot.shellDir
    }

    LockFeature.LockRoot {
        id: lockRoot
    }

    NotificationFeature.NotificationsHost {
        id: notifications
        theme: theme
    }

    OsdFeature.VolumeOsd {
        id: volumeOsd
        theme: theme
    }

    PolkitFeature.PolkitDialog {
        theme: shellRoot.shellTheme
        screenProvider: function() { return shellRoot.focusedScreen() }
    }

    App.PopupCoordinator {
        id: popupCoordinator
        menu: omarchyMenu
        launcher: appLauncher
        clipboard: clipboardHistory
        themeSwitcher: themeSwitcher
        powerMenu: powerMenu
        mediaPopup: mediaPopup
        audioPopup: audioPopup
        networkPopup: networkPopup
        bluetoothPopup: bluetoothPopup
        vpnPopup: vpnPopup
        vpnCli: vpnController
        aboutPopup: aboutPopup
        notifications: notifications
        onCalendarRefreshRequested: shellRoot.calendarNow = new Date()
    }

    App.ShellIpc {
        coordinator: popupCoordinator
        lockProvider: lockRoot
        focusedScreenProvider: function() { return shellRoot.focusedScreen() }
        screenshotCaptureProvider: function(mode) { shellRoot.captureScreenshot(mode) }
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

    function isBrowserPlayer(player) { return mprisController.isBrowserPlayer(player) }
    function chooseActivePlayer() { return mprisController.chooseActivePlayer() }
    function updateActivePlayer() { mprisController.updateActivePlayer() }

    function volumePercent() {
        return audioVolumePercent
    }

    // TOPBAR LÉTREHOZÁSA (DMS stílusú Instantiatorral)
    Instantiator {
        model: shellRoot.uniqueScreens
        delegate: BarUi.BarWindow {
            required property var modelData

            targetScreen: modelData
            theme: shellRoot.shellTheme
            barHeight: shellRoot.barHeight
            visibleWorkspaceIds: shellRoot.visibleWorkspaceIds
            occupiedWorkspaceIds: shellRoot.occupiedWorkspaceIds
            activePlayer: shellRoot.activePlayer
            hasMediaSource: Mpris.players.values.length > 0
            cavaValues: cavaController.values
            menuOpen: omarchyMenu.opened && omarchyMenu.screen === targetScreen
            centerPopupOpen: mediaPopup.opened && mediaPopup.screen === targetScreen
            audioPopupOpen: audioPopup.opened && audioPopup.screen === targetScreen
            audioVolumePercent: shellRoot.audioVolumePercent
            vpnActive: shellRoot.vpnActive
            vpnName: shellRoot.vpnName
            vpnPopupOpen: vpnPopup.opened && vpnPopup.screen === targetScreen
            networkType: shellRoot.networkType
            networkPopupOpen: networkPopup.opened && networkPopup.screen === targetScreen
            bluetoothAvailable: bluetoothStatusController.available
            bluetoothEnabled: bluetoothStatusController.enabled
            bluetoothConnected: bluetoothStatusController.connected
            bluetoothPopupOpen: bluetoothPopup.opened && bluetoothPopup.screen === targetScreen
            batteryAvailable: batteryStatusController.available
            batteryPercentage: batteryStatusController.percentage
            batteryCharging: batteryStatusController.charging
            notificationsDnd: notifications.dnd
            notificationsHasToast: notifications.hasToast
            notificationsUnreadCount: notifications.unreadCount
            notificationsMenuOpened: notifications.menuOpened
            powerMenuOpened: powerMenu.opened && powerMenu.screen === targetScreen
            trayMenuOpen: trayMenu.visible && trayMenu.screen === targetScreen

            onMenuToggleRequested: popupCoordinator.toggleMenu(targetScreen)
            onCenterToggleRequested: popupCoordinator.toggleCenterPopup(targetScreen)
            onAudioToggleRequested: popupCoordinator.toggleAudio(targetScreen)
            onNetworkToggleRequested: popupCoordinator.toggleNetwork(targetScreen)
            onBluetoothToggleRequested: popupCoordinator.toggleBluetooth(targetScreen)
            onVpnToggleRequested: popupCoordinator.toggleVpn(targetScreen)
            onNotificationsToggleRequested: popupCoordinator.toggleNotifications(targetScreen)
            onPowerToggleRequested: popupCoordinator.togglePowerMenu(targetScreen)
            onLaunchCommand: command => launchBarCommand(command)
            onAudioVolumeStepRequested: increase => audioSummaryController.stepVolume(increase)
            onTrayMenuRequested: (model, globalX) => trayMenu.openFor(targetScreen, model, globalX)
        }
    }

    App.LazyPopup {
        id: mediaPopup
        property int currentTab: 0
        property string selectedPlayerDbusName: ""
        popupComponent: Component {
            MediaFeature.MediaPopup {
                theme: shellRoot.shellTheme
                screen: mediaPopup.screen
                currentTab: mediaPopup.currentTab
                selectedPlayerDbusName: mediaPopup.selectedPlayerDbusName
                barHeight: shellRoot.barHeight
                activePlayer: shellRoot.activePlayer
                cavaValues: cavaController.values
                calendarNow: shellRoot.calendarNow
                monthNames: shellRoot.monthNames
                dayNames: shellRoot.dayNames
                onCurrentTabChanged: mediaPopup.currentTab = currentTab
                onSelectedPlayerDbusNameChanged: mediaPopup.selectedPlayerDbusName = selectedPlayerDbusName
            }
        }
    }

    TrayFeature.TrayMenu {
        id: trayMenu
        theme: theme
        barHeight: shellRoot.barHeight
    }
}

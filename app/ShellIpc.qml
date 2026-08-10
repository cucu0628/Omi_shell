import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var coordinator
    required property var lockProvider
    required property var focusedScreenProvider
    required property var screenshotCaptureProvider
    property string pendingAboutAction: ""

    width: 0
    height: 0
    visible: false

    function scheduleAboutAction(action) {
        pendingAboutAction = action
        aboutMonitorDelay.restart()
    }

    Timer {
        id: aboutMonitorDelay
        interval: 75
        onTriggered: {
            var action = root.pendingAboutAction
            root.pendingAboutAction = ""
            var targetScreen = root.focusedScreenProvider()
            if (action === "toggle") root.coordinator.toggleAbout(targetScreen)
            else if (action === "open") root.coordinator.setAboutOpen(true, targetScreen)
        }
    }

    IpcHandler {
        target: "menu"

        function toggle(): void { coordinator.toggleMenu(focusedScreenProvider()) }
        function open(): void { coordinator.setMenuOpen(true, focusedScreenProvider()) }
        function close(): void { coordinator.setMenuOpen(false) }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            coordinator.toggleLauncher(coordinator.menu.loaded ? coordinator.menu.screen : focusedScreenProvider())
        }
        function open(): void {
            coordinator.setLauncherOpen(true, coordinator.menu.loaded ? coordinator.menu.screen : focusedScreenProvider())
        }
        function close(): void { coordinator.setLauncherOpen(false) }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            coordinator.toggleClipboard(coordinator.menu.loaded ? coordinator.menu.screen : focusedScreenProvider())
        }
        function open(): void {
            coordinator.setClipboardOpen(true, coordinator.menu.loaded ? coordinator.menu.screen : focusedScreenProvider())
        }
        function close(): void { coordinator.setClipboardOpen(false) }
    }

    IpcHandler {
        target: "style"

        function theme(): void {
            coordinator.setThemeSwitcherOpen(true, "theme", coordinator.menu.loaded ? coordinator.menu.screen : focusedScreenProvider())
        }
        function wallpaper(): void {
            coordinator.setThemeSwitcherOpen(true, "wallpaper", coordinator.menu.loaded ? coordinator.menu.screen : focusedScreenProvider())
        }
        function close(): void { coordinator.closeThemeSwitcher() }
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            coordinator.togglePowerMenu(coordinator.menu.loaded ? coordinator.menu.screen : focusedScreenProvider())
        }
        function open(): void {
            coordinator.setPowerMenuOpen(true, coordinator.menu.loaded ? coordinator.menu.screen : focusedScreenProvider())
        }
        function close(): void { coordinator.setPowerMenuOpen(false) }
    }

    IpcHandler {
        target: "lock"

        function lock(): void { lockProvider.lock() }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void { coordinator.toggleNotifications(focusedScreenProvider()) }
        function dnd(): void { coordinator.toggleNotificationsDnd() }
        function close(): void { coordinator.setNotificationsOpen(false) }
    }

    IpcHandler {
        target: "audio"

        function toggle(): void { coordinator.toggleAudioScreenAgnostic() }
        function open(): void { coordinator.setAudioOpen(true) }
        function close(): void { coordinator.setAudioOpen(false) }
    }

    IpcHandler {
        target: "network"

        function toggle(): void { coordinator.toggleNetwork(focusedScreenProvider()) }
        function open(): void { coordinator.setNetworkOpen(true, focusedScreenProvider()) }
        function close(): void { coordinator.setNetworkOpen(false) }
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void { coordinator.toggleBluetooth(focusedScreenProvider()) }
        function open(): void { coordinator.setBluetoothOpen(true, focusedScreenProvider()) }
        function close(): void { coordinator.setBluetoothOpen(false) }
    }

    IpcHandler {
        target: "vpn"

        function toggle(): void { coordinator.toggleVpn(focusedScreenProvider()) }
        function open(): void { coordinator.setVpnOpen(true, focusedScreenProvider()) }
        function close(): void { coordinator.setVpnOpen(false) }
        function connect(): void { coordinator.vpnQuickConnect(focusedScreenProvider()) }
        function disconnect(): void { coordinator.vpnDisconnect(focusedScreenProvider()) }
        function app(): void { coordinator.vpnOpenApp() }
    }

    IpcHandler {
        target: "about"

        function toggle(): void { root.scheduleAboutAction("toggle") }
        function open(): void { root.scheduleAboutAction("open") }
        function close(): void {
            aboutMonitorDelay.stop()
            root.pendingAboutAction = ""
            coordinator.setAboutOpen(false)
        }
    }

    IpcHandler {
        target: "screenshot"

        function capture(): void { screenshotCaptureProvider("smart") }
        function window(): void { screenshotCaptureProvider("window") }
        function workspace(): void { screenshotCaptureProvider("workspace") }
        function region(): void { screenshotCaptureProvider("region") }
    }
}

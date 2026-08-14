import QtQuick

QtObject {
    required property var menu
    required property var launcher
    required property var clipboard
    required property var themeSwitcher
    required property var mediaPopup
    required property var audioPopup
    required property var connectivityPopup
    required property var bluetoothPopup
    required property var removablePopup
    required property var privacyPopup
    required property var aiPopup
    required property var vpnCli
    required property var aboutPopup
    required property var notifications

    signal calendarRefreshRequested()

    function toggleCenterPopup(nextScreen) {
        var openHere = mediaPopup.opened && nextScreen && mediaPopup.screen === nextScreen
        calendarRefreshRequested()
        audioPopup.opened = false
        connectivityPopup.opened = false
        bluetoothPopup.opened = false
        removablePopup.opened = false
        aiPopup.opened = false
        notifications.menuOpened = false
        privacyPopup.opened = false
        if (nextScreen) mediaPopup.screen = nextScreen
        mediaPopup.opened = !openHere
    }

    function toggleNotificationsDnd() {
        notifications.dnd = !notifications.dnd
    }

    function clearNotifications() {
        notifications.clearHistory()
    }

    function toggleNotificationsGrouping() {
        notifications.grouping = !notifications.grouping
    }

    function setNotificationGroupsExpanded(expanded) {
        notifications.setAllGroupsExpanded(expanded)
    }

    function setNotificationsOpen(open, nextScreen) {
        if (open) {
            aiPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
        }
        notifications.setMenuOpen(open, nextScreen)
    }

    function setMenuOpen(open, nextScreen) {
        if (open) {
            aiPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            if (nextScreen) menu.screen = nextScreen
        }
        menu.opened = open
    }

    function setLauncherOpen(open, nextScreen) {
        if (open) {
            aiPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            menu.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            if (nextScreen) launcher.screen = nextScreen
        }
        launcher.opened = open
    }

    function setClipboardOpen(open, nextScreen) {
        if (open) {
            aiPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            menu.opened = false
            launcher.opened = false
            themeSwitcher.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            if (nextScreen) clipboard.screen = nextScreen
        }
        clipboard.opened = open
    }

    function setThemeSwitcherOpen(open, nextMode, nextScreen) {
        if (open) {
            aiPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            themeSwitcher.mode = nextMode
            if (nextScreen) themeSwitcher.screen = nextScreen
        }
        themeSwitcher.opened = open
    }

    function setAudioOpen(open, nextScreen) {
        if (open) {
            aiPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            mediaPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            if (nextScreen) audioPopup.screen = nextScreen
        }
        audioPopup.opened = open
    }

    function setAboutOpen(open, nextScreen) {
        if (open) {
            aiPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            if (nextScreen) aboutPopup.screen = nextScreen
        }
        aboutPopup.opened = open
    }

    // Wi-Fi and VPN live in one panel; `mode` only picks the tab it opens on.
    function setConnectivityOpen(open, mode, nextScreen) {
        if (open) {
            aiPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            if (mode) connectivityPopup.mode = mode
            if (nextScreen) connectivityPopup.screen = nextScreen
        }
        connectivityPopup.opened = open
    }

    // Asking for a tab the panel is not showing switches to it instead of
    // closing the panel that just answered a different question.
    function toggleConnectivity(mode, nextScreen) {
        var openHere = connectivityPopup.opened && nextScreen && connectivityPopup.screen === nextScreen
        if (openHere && mode && connectivityPopup.mode !== mode) {
            connectivityPopup.mode = mode
            return
        }
        setConnectivityOpen(!openHere, mode, nextScreen)
    }

    function setNetworkOpen(open, nextScreen) {
        setConnectivityOpen(open, "network", nextScreen)
    }

    function toggleMenu(nextScreen) {
        setMenuOpen(!(menu.opened && nextScreen && menu.screen === nextScreen), nextScreen)
    }

    function toggleLauncher(nextScreen) {
        setLauncherOpen(!launcher.opened, nextScreen)
    }

    function toggleClipboard(nextScreen) {
        setClipboardOpen(!(clipboard.opened && nextScreen && clipboard.screen === nextScreen), nextScreen)
    }

    function closeThemeSwitcher() {
        setThemeSwitcherOpen(false, themeSwitcher.mode, themeSwitcher.screen)
    }

    function toggleNotifications(nextScreen) {
        setNotificationsOpen(!(notifications.menuOpened && nextScreen && notifications.screen === nextScreen), nextScreen)
    }

    function toggleAudio(nextScreen) {
        setAudioOpen(!(audioPopup.opened && nextScreen && audioPopup.screen === nextScreen), nextScreen)
    }

    function toggleAudioScreenAgnostic() {
        setAudioOpen(!audioPopup.opened)
    }

    function toggleNetwork(nextScreen) {
        toggleConnectivity("network", nextScreen)
    }

    function setBluetoothOpen(open, nextScreen) {
        if (open) {
            aiPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            connectivityPopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            removablePopup.opened = false
            if (nextScreen) bluetoothPopup.screen = nextScreen
        }
        bluetoothPopup.opened = open
    }

    function toggleBluetooth(nextScreen) {
        setBluetoothOpen(!(bluetoothPopup.opened && nextScreen && bluetoothPopup.screen === nextScreen), nextScreen)
    }

    function setRemovableOpen(open, nextScreen) {
        if (open) {
            aiPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            if (nextScreen) removablePopup.screen = nextScreen
        }
        removablePopup.opened = open
    }

    function toggleRemovable(nextScreen) {
        setRemovableOpen(!(removablePopup.opened && nextScreen && removablePopup.screen === nextScreen), nextScreen)
    }

    function setVpnOpen(open, nextScreen) {
        setConnectivityOpen(open, "vpn", nextScreen)
    }

    function toggleVpn(nextScreen) {
        toggleConnectivity("vpn", nextScreen)
    }

    function setPrivacyOpen(open, nextScreen) {
        if (open) {
            aiPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) privacyPopup.screen = nextScreen
        }
        privacyPopup.opened = open
    }

    function togglePrivacy(nextScreen) {
        setPrivacyOpen(!(privacyPopup.opened && nextScreen && privacyPopup.screen === nextScreen), nextScreen)
    }

    function setAiOpen(open, nextScreen) {
        if (open) {
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            connectivityPopup.opened = false
            bluetoothPopup.opened = false
            removablePopup.opened = false
            notifications.menuOpened = false
            privacyPopup.opened = false
            if (nextScreen) aiPopup.screen = nextScreen
        }
        aiPopup.opened = open
    }

    function toggleAi(nextScreen) {
        setAiOpen(!(aiPopup.opened && nextScreen && aiPopup.screen === nextScreen), nextScreen)
    }

    // The panel is opened alongside the action so a keybinding still gives
    // visible feedback while the CLI works.
    function vpnQuickConnect(nextScreen) {
        setVpnOpen(true, nextScreen)
        vpnCli.connectFastest()
    }

    function vpnDisconnect(nextScreen) {
        setVpnOpen(true, nextScreen)
        vpnCli.disconnectVpn()
    }

    function vpnOpenApp() {
        setVpnOpen(false)
        vpnCli.openApp()
    }

    function toggleAbout(nextScreen) {
        setAboutOpen(!(aboutPopup.opened && nextScreen && aboutPopup.screen === nextScreen), nextScreen)
    }

}

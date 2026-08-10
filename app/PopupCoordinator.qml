import QtQuick

QtObject {
    required property var menu
    required property var launcher
    required property var clipboard
    required property var themeSwitcher
    required property var powerMenu
    required property var calendarPopup
    required property var mediaPopup
    required property var audioPopup
    required property var networkPopup
    required property var bluetoothPopup
    required property var aboutPopup
    required property var notifications

    signal calendarRefreshRequested()

    function toggleCenterPopup(nextScreen) {
        var openHere = mediaPopup.opened && nextScreen && mediaPopup.screen === nextScreen
        calendarRefreshRequested()
        calendarPopup.opened = false
        audioPopup.opened = false
        networkPopup.opened = false
        bluetoothPopup.opened = false
        notifications.menuOpened = false
        if (nextScreen) mediaPopup.screen = nextScreen
        mediaPopup.opened = !openHere
    }

    function toggleNotificationsDnd() {
        notifications.dnd = !notifications.dnd
    }

    function setNotificationsOpen(open, nextScreen) {
        if (open) {
            networkPopup.opened = false
            bluetoothPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
        }
        notifications.setMenuOpen(open, nextScreen)
    }

    function setMenuOpen(open, nextScreen) {
        if (open) {
            networkPopup.opened = false
            bluetoothPopup.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) menu.screen = nextScreen
        }
        menu.opened = open
    }

    function setLauncherOpen(open, nextScreen) {
        if (open) {
            networkPopup.opened = false
            bluetoothPopup.opened = false
            menu.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) launcher.screen = nextScreen
        }
        launcher.opened = open
    }

    function setClipboardOpen(open, nextScreen) {
        if (open) {
            networkPopup.opened = false
            bluetoothPopup.opened = false
            menu.opened = false
            launcher.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) clipboard.screen = nextScreen
        }
        clipboard.opened = open
    }

    function setThemeSwitcherOpen(open, nextMode, nextScreen) {
        if (open) {
            networkPopup.opened = false
            bluetoothPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            themeSwitcher.mode = nextMode
            if (nextScreen) themeSwitcher.screen = nextScreen
        }
        themeSwitcher.opened = open
    }

    function setPowerMenuOpen(open, nextScreen) {
        if (open) {
            networkPopup.opened = false
            bluetoothPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            calendarPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) powerMenu.screen = nextScreen
        }
        powerMenu.opened = open
    }

    function setCalendarOpen(open, nextScreen) {
        if (open) {
            networkPopup.opened = false
            bluetoothPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) calendarPopup.screen = nextScreen
        }
        calendarPopup.opened = open
    }

    function setAudioOpen(open, nextScreen) {
        if (open) {
            networkPopup.opened = false
            bluetoothPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            mediaPopup.opened = false
            aboutPopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) audioPopup.screen = nextScreen
        }
        audioPopup.opened = open
    }

    function setAboutOpen(open, nextScreen) {
        if (open) {
            networkPopup.opened = false
            bluetoothPopup.opened = false
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) aboutPopup.screen = nextScreen
        }
        aboutPopup.opened = open
    }

    function setNetworkOpen(open, nextScreen) {
        if (open) {
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            bluetoothPopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) networkPopup.screen = nextScreen
        }
        networkPopup.opened = open
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

    function togglePowerMenu(nextScreen) {
        setPowerMenuOpen(!(powerMenu.opened && nextScreen && powerMenu.screen === nextScreen), nextScreen)
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
        setNetworkOpen(!(networkPopup.opened && nextScreen && networkPopup.screen === nextScreen), nextScreen)
    }

    function setBluetoothOpen(open, nextScreen) {
        if (open) {
            menu.opened = false
            launcher.opened = false
            clipboard.opened = false
            themeSwitcher.opened = false
            powerMenu.opened = false
            calendarPopup.opened = false
            mediaPopup.opened = false
            audioPopup.opened = false
            aboutPopup.opened = false
            networkPopup.opened = false
            notifications.menuOpened = false
            if (nextScreen) bluetoothPopup.screen = nextScreen
        }
        bluetoothPopup.opened = open
    }

    function toggleBluetooth(nextScreen) {
        setBluetoothOpen(!(bluetoothPopup.opened && nextScreen && bluetoothPopup.screen === nextScreen), nextScreen)
    }

    function toggleAbout(nextScreen) {
        setAboutOpen(!(aboutPopup.opened && nextScreen && aboutPopup.screen === nextScreen), nextScreen)
    }

}

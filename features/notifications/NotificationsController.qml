import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: controller

    property bool dnd: false
    property var currentNotification: null
    property bool toastVisible: false
    property bool menuOpened: false
    property var history: []
    property int unreadCount: 0
    property int nextEntryId: 1
    property int currentEntryId: -1
    property int historyLimit: 100
    readonly property bool hasToast: toastVisible && currentNotification !== null

    width: 0
    height: 0
    visible: false

    function cleanText(value) {
        return (value || "").toString().replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").trim()
    }

    function displayNotification(notification) {
        var icon = notification.image !== "" ? notification.image : (notification.appIcon !== "" ? Quickshell.iconPath(notification.appIcon, true) : "")
        var defaultAction = null
        for (var actionIndex = 0; actionIndex < notification.actions.length; actionIndex++) {
            if (notification.actions[actionIndex].identifier === "default") {
                defaultAction = notification.actions[actionIndex]
                break
            }
        }
        var entryId = nextEntryId++
        var entry = {
            id: entryId,
            appName: cleanText(notification.appName || "Notification"),
            summary: cleanText(notification.summary),
            body: cleanText(notification.body),
            icon: icon,
            critical: notification.urgency === NotificationUrgency.Critical,
            time: Qt.formatTime(new Date(), "HH:mm"),
            unread: !menuOpened,
            notification: notification,
            defaultAction: defaultAction
        }
        var nextHistory = [entry]
        for (var i = 0; i < history.length && i < historyLimit - 1; i++) nextHistory.push(history[i])
        for (var dropped = historyLimit - 1; dropped < history.length; dropped++) {
            if (history[dropped].unread) unreadCount = Math.max(0, unreadCount - 1)
            if (history[dropped].notification) history[dropped].notification.expire()
        }
        history = nextHistory
        if (!menuOpened) unreadCount++

        notification.tracked = true

        if (dnd || menuOpened) {
            return
        }

        currentNotification = notification
        currentEntryId = entryId
        toastVisible = true
        expireTimer.interval = Math.max(2600, Math.min(7000, notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : 4200))
        expireTimer.restart()
    }

    function closeToast(explicitClose) {
        if (!currentNotification) return
        var notification = currentNotification
        var entryId = currentEntryId
        toastVisible = false
        currentNotification = null
        currentEntryId = -1
        expireTimer.stop()
        if (explicitClose) removeHistory(entryId, true)
    }

    function activateNotification() {
        if (!currentNotification) return

        var notification = currentNotification
        toastVisible = false
        currentNotification = null
        var entryId = currentEntryId
        currentEntryId = -1
        expireTimer.stop()
        activateHistoryEntry(entryId, notification)
    }

    function setMenuOpen(open) {
        menuOpened = open
        if (open) {
            unreadCount = 0
            if (toastVisible) hideToastForMenu()
        }
    }

    function hideToastForMenu() {
        toastVisible = false
        currentNotification = null
        currentEntryId = -1
        expireTimer.stop()
    }

    function removeHistory(entryId, dismissNotification) {
        var nextHistory = []
        for (var i = 0; i < history.length; i++) {
            var entry = history[i]
            if (entry.id === entryId) {
                if (entry.unread) unreadCount = Math.max(0, unreadCount - 1)
                if (dismissNotification && entry.notification) entry.notification.dismiss()
            } else {
                nextHistory.push(entry)
            }
        }
        history = nextHistory
    }

    function activateHistoryEntry(entryId, fallbackNotification) {
        var selectedEntry = null
        for (var i = 0; i < history.length; i++) {
            if (history[i].id === entryId) {
                selectedEntry = history[i]
                break
            }
        }
        removeHistory(entryId, false)
        var notification = selectedEntry && selectedEntry.notification ? selectedEntry.notification : fallbackNotification
        if (selectedEntry && selectedEntry.defaultAction) selectedEntry.defaultAction.invoke()
        if (notification) notification.dismiss()
    }

    function clearHistory() {
        for (var i = 0; i < history.length; i++) {
            if (history[i].notification) history[i].notification.dismiss()
        }
        history = []
        unreadCount = 0
    }

    function pauseToastTimer() {
        expireTimer.stop()
    }

    function resumeToastTimer() {
        if (toastVisible) expireTimer.restart()
    }

    NotificationServer {
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        keepOnReload: false
        onNotification: (notification) => controller.displayNotification(notification)
    }

    Connections {
        target: controller.currentNotification
        enabled: target !== null
        ignoreUnknownSignals: true

        function onClosed() {
            controller.toastVisible = false
            controller.currentNotification = null
            controller.currentEntryId = -1
        }
    }

    Timer {
        id: expireTimer
        onTriggered: controller.closeToast(false)
    }
}

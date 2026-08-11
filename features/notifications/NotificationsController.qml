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
    property var toastQueue: []
    property var currentActions: []
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

    function historyEntry(entryId) {
        for (var i = 0; i < history.length; i++) {
            if (history[i].id === entryId) return history[i]
        }
        return null
    }

    function removeQueuedEntry(entryId) {
        var nextQueue = []
        for (var i = 0; i < toastQueue.length; i++) {
            if (toastQueue[i] !== entryId) nextQueue.push(toastQueue[i])
        }
        toastQueue = nextQueue
    }

    function clearCurrentToast() {
        toastVisible = false
        currentNotification = null
        currentActions = []
        currentEntryId = -1
        expireTimer.stop()
    }

    function showNextToast() {
        if (currentNotification || menuOpened || dnd) return

        while (toastQueue.length > 0) {
            var entryId = toastQueue[0]
            toastQueue = toastQueue.slice(1)
            var entry = historyEntry(entryId)
            if (!entry || !entry.notification) continue

            currentNotification = entry.notification
            currentActions = entry.actions || []
            currentEntryId = entryId
            toastVisible = true
            expireTimer.interval = Math.max(2600, Math.min(7000, entry.notification.expireTimeout > 0 ? entry.notification.expireTimeout * 1000 : 4200))
            expireTimer.restart()
            return
        }
    }

    function refreshNotification(entryId) {
        var entry = historyEntry(entryId)
        if (!entry || !entry.notification) return

        var notification = entry.notification
        var actions = []
        var defaultAction = null
        for (var actionIndex = 0; actionIndex < notification.actions.length; actionIndex++) {
            var action = notification.actions[actionIndex]
            actions.push(action)
            if (action.identifier === "default") defaultAction = action
        }

        entry.appName = cleanText(notification.appName || "Notification")
        entry.summary = cleanText(notification.summary)
        entry.body = cleanText(notification.body)
        entry.icon = notification.image !== "" ? notification.image : (notification.appIcon !== "" ? Quickshell.iconPath(notification.appIcon, true) : "")
        entry.critical = notification.urgency === NotificationUrgency.Critical
        entry.actions = actions
        entry.defaultAction = defaultAction
        history = history.slice()

        if (currentEntryId === entryId) currentActions = actions
    }

    function scheduleNotificationRefresh(entryId) {
        Qt.callLater(function() { controller.refreshNotification(entryId) })
    }

    function displayNotification(notification) {
        var icon = notification.image !== "" ? notification.image : (notification.appIcon !== "" ? Quickshell.iconPath(notification.appIcon, true) : "")
        var actions = []
        var defaultAction = null
        for (var actionIndex = 0; actionIndex < notification.actions.length; actionIndex++) {
            var action = notification.actions[actionIndex]
            actions.push(action)
            if (action.identifier === "default") defaultAction = action
        }
        var entryId = nextEntryId++
        notification.tracked = true
        notification.closed.connect(function() { controller.handleNotificationClosed(entryId) })
        notification.actionsChanged.connect(function() { controller.scheduleNotificationRefresh(entryId) })
        notification.appNameChanged.connect(function() { controller.scheduleNotificationRefresh(entryId) })
        notification.appIconChanged.connect(function() { controller.scheduleNotificationRefresh(entryId) })
        notification.summaryChanged.connect(function() { controller.scheduleNotificationRefresh(entryId) })
        notification.bodyChanged.connect(function() { controller.scheduleNotificationRefresh(entryId) })
        notification.imageChanged.connect(function() { controller.scheduleNotificationRefresh(entryId) })
        notification.urgencyChanged.connect(function() { controller.scheduleNotificationRefresh(entryId) })
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
            actions: actions,
            defaultAction: defaultAction
        }
        var nextHistory = [entry]
        for (var i = 0; i < history.length && i < historyLimit - 1; i++) nextHistory.push(history[i])
        var droppedNotifications = []
        for (var dropped = historyLimit - 1; dropped < history.length; dropped++) {
            if (history[dropped].unread) unreadCount = Math.max(0, unreadCount - 1)
            removeQueuedEntry(history[dropped].id)
            if (history[dropped].notification) droppedNotifications.push(history[dropped].notification)
        }
        history = nextHistory
        if (!menuOpened) unreadCount++
        for (var expired = 0; expired < droppedNotifications.length; expired++) droppedNotifications[expired].expire()

        if (dnd || menuOpened) {
            return
        }

        toastQueue = toastQueue.concat([entryId])
        showNextToast()
    }

    function closeToast(explicitClose) {
        if (!currentNotification) return
        var entryId = currentEntryId
        clearCurrentToast()
        if (explicitClose) removeHistory(entryId, true)
        showNextToast()
    }

    function activateNotification() {
        if (!currentNotification) return

        var notification = currentNotification
        var entryId = currentEntryId
        clearCurrentToast()
        activateHistoryEntry(entryId, notification)
        showNextToast()
    }

    function activateCurrentAction(action) {
        if (!currentNotification || !action) return

        var notification = currentNotification
        var entryId = currentEntryId
        clearCurrentToast()
        invokeEntryAction(entryId, action, notification)
        showNextToast()
    }

    function setMenuOpen(open) {
        menuOpened = open
        if (open) {
            unreadCount = 0
            if (toastVisible) hideToastForMenu()
        }
    }

    function hideToastForMenu() {
        clearCurrentToast()
        toastQueue = []
    }

    function removeHistory(entryId, dismissNotification) {
        var nextHistory = []
        var removedNotification = null
        removeQueuedEntry(entryId)
        for (var i = 0; i < history.length; i++) {
            var entry = history[i]
            if (entry.id === entryId) {
                if (entry.unread) unreadCount = Math.max(0, unreadCount - 1)
                if (dismissNotification && entry.notification) removedNotification = entry.notification
            } else {
                nextHistory.push(entry)
            }
        }
        history = nextHistory
        if (removedNotification) removedNotification.dismiss()
    }

    function invokeEntryAction(entryId, action, fallbackNotification) {
        var entry = historyEntry(entryId)
        var notification = entry && entry.notification ? entry.notification : fallbackNotification
        var resident = notification && notification.resident

        if (action && resident) {
            if (entry && entry.unread) {
                entry.unread = false
                unreadCount = Math.max(0, unreadCount - 1)
                history = history.slice()
            }
            action.invoke()
            return
        }

        removeHistory(entryId, false)

        if (action) {
            action.invoke()
        } else if (notification) {
            notification.dismiss()
        }
    }

    function invokeHistoryAction(entryId, action) {
        if (!action) return
        invokeEntryAction(entryId, action, null)
    }

    function activateHistoryEntry(entryId, fallbackNotification) {
        var selectedEntry = null
        for (var i = 0; i < history.length; i++) {
            if (history[i].id === entryId) {
                selectedEntry = history[i]
                break
            }
        }
        invokeEntryAction(entryId, selectedEntry ? selectedEntry.defaultAction : null, fallbackNotification)
    }

    function handleNotificationClosed(entryId) {
        removeQueuedEntry(entryId)
        var wasCurrent = currentEntryId === entryId
        if (wasCurrent) clearCurrentToast()

        var nextHistory = []
        for (var i = 0; i < history.length; i++) {
            var entry = history[i]
            if (entry.id === entryId) {
                entry.notification = null
                entry.actions = []
                entry.defaultAction = null
            }
            nextHistory.push(entry)
        }
        history = nextHistory
        if (wasCurrent) Qt.callLater(showNextToast)
    }

    function clearHistory() {
        var notifications = []
        for (var i = 0; i < history.length; i++) {
            if (history[i].notification) notifications.push(history[i].notification)
        }
        clearCurrentToast()
        toastQueue = []
        history = []
        unreadCount = 0
        for (var dismissed = 0; dismissed < notifications.length; dismissed++) notifications[dismissed].dismiss()
    }

    function pauseToastTimer() {
        expireTimer.stop()
    }

    function resumeToastTimer() {
        if (toastVisible) expireTimer.restart()
    }

    onDndChanged: if (dnd) toastQueue = []

    NotificationServer {
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        keepOnReload: false
        onNotification: (notification) => controller.displayNotification(notification)
    }

    Timer {
        id: expireTimer
        onTriggered: controller.closeToast(false)
    }
}

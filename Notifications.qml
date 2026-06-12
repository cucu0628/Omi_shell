import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: notifyWindow

    property var theme: null
    property bool dnd: false
    property var currentNotification: null
    property bool toastVisible: false
    readonly property bool hasToast: toastVisible && currentNotification !== null

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"
    readonly property string inkBg: "#1b1613"

    function cleanText(value) {
        return (value || "").toString().replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").trim()
    }

    function displayNotification(notification) {
        if (dnd) {
            notification.tracked = true
            notification.expire()
            return
        }

        if (currentNotification && currentNotification !== notification) currentNotification.expire()
        currentNotification = notification
        notification.tracked = true
        notification.closed.connect(function() {
            if (currentNotification === notification) {
                toastVisible = false
                currentNotification = null
            }
        })
        toastVisible = true
        expireTimer.interval = Math.max(2600, Math.min(7000, notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : 4200))
        expireTimer.restart()
    }

    function closeToast(explicitClose) {
        if (!currentNotification) return
        var notification = currentNotification
        toastVisible = false
        currentNotification = null
        if (explicitClose) notification.dismiss()
        else notification.expire()
    }

    function activateNotification() {
        if (!currentNotification) return

        var notification = currentNotification
        var defaultAction = null
        for (var i = 0; i < notification.actions.length; i++) {
            if (notification.actions[i].identifier === "default") {
                defaultAction = notification.actions[i]
                break
            }
        }

        toastVisible = false
        currentNotification = null
        expireTimer.stop()

        if (defaultAction) defaultAction.invoke()
        else notification.dismiss()
    }

    NotificationServer {
        id: notificationServer
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        keepOnReload: false
        onNotification: (notification) => displayNotification(notification)
    }

    Timer {
        id: expireTimer
        onTriggered: closeToast(false)
    }

    visible: toastVisible || toast.opacity > 0
    implicitWidth: 360
    implicitHeight: 132
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: 34; right: 14 }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.notifications"
    WlrLayershell.exclusiveZone: -1

    Item {
        id: toast
        anchors.right: parent.right
        anchors.rightMargin: 0
        y: 0
        width: 360
        height: toastVisible ? Math.max(94, Math.min(132, toastBody.implicitHeight + 46)) : 0
        opacity: toastVisible ? 1 : 0
        clip: true
        Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: currentNotification && currentNotification.urgency === NotificationUrgency.Critical ? panelAccent : Qt.rgba(1, 1, 1, 0.18)
            border.width: currentNotification && currentNotification.urgency === NotificationUrgency.Critical ? 2 : 1
            radius: 0

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 3
                color: panelAccent
                opacity: currentNotification && currentNotification.urgency === NotificationUrgency.Low ? 0.45 : 1
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: expireTimer.stop()
                onExited: expireTimer.restart()
                onClicked: activateNotification()
            }

            Row {
                anchors.fill: parent
                anchors.margins: 14
                anchors.leftMargin: 18
                spacing: 12

                Rectangle {
                    width: 42
                    height: 42
                    anchors.verticalCenter: parent.verticalCenter
                    color: inkBg
                    border.color: Qt.rgba(1, 1, 1, 0.07)
                    border.width: 1
                    radius: 0
                    clip: true

                    Image {
                        id: notifyImage
                        anchors.fill: parent
                        anchors.margins: 7
                        source: currentNotification && currentNotification.image !== "" ? currentNotification.image : (currentNotification && currentNotification.appIcon !== "" ? Quickshell.iconPath(currentNotification.appIcon, true) : "")
                        visible: source !== ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        anchors.centerIn: parent
                        text: currentNotification && currentNotification.urgency === NotificationUrgency.Critical ? "󰀦" : "󰂚"
                        color: panelAccent
                        font.pixelSize: 17
                        visible: notifyImage.source === ""
                    }
                }

                Column {
                    id: toastBody
                    width: parent.width - 54
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Row {
                        width: parent.width
                        height: 14
                        spacing: 8
                        Text {
                            text: currentNotification ? cleanText(currentNotification.appName || "Notification").toUpperCase() : "NOTIFICATION"
                            color: panelAccent
                            font.pixelSize: 9
                            font.letterSpacing: 3
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width - 70
                        }
                        Text {
                            text: currentNotification && currentNotification.urgency === NotificationUrgency.Critical ? "CRITICAL" : ""
                            color: panelAccent
                            font.pixelSize: 9
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                            width: 62
                        }
                    }

                    Text {
                        width: parent.width
                        text: currentNotification ? cleanText(currentNotification.summary) : ""
                        color: panelFg
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        width: parent.width
                        text: currentNotification ? cleanText(currentNotification.body) : ""
                        color: panelFg
                        opacity: 0.62
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }
        }
    }
}

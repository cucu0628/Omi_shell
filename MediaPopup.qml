import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PanelWindow {
    id: mediaPopup

    property var theme: null
    property bool opened: false
    property int barHeight: 26
    property var activePlayer: null
    property var calendarNow: new Date()
    property var monthNames: []
    property var dayNames: []

    visible: opened || mediaMenuContainer.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.media"
    WlrLayershell.exclusiveZone: -1

    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        var total = Math.floor(seconds)
        var minutes = Math.floor(total / 60)
        var rest = total % 60
        return minutes + ":" + rest.toString().padStart(2, "0")
    }

    function playerProgress(player) {
        if (!player || !player.lengthSupported || player.length <= 0) return 0
        return Math.max(0, Math.min(1, player.position / player.length))
    }

    function firstCalendarDayOffset() {
        var first = new Date(calendarNow.getFullYear(), calendarNow.getMonth(), 1).getDay()
        return first === 0 ? 6 : first - 1
    }

    function daysInCalendarMonth() {
        return new Date(calendarNow.getFullYear(), calendarNow.getMonth() + 1, 0).getDate()
    }

    function calendarDayForCell(index) {
        return index - firstCalendarDayOffset() + 1
    }

    function isCalendarToday(day) {
        var today = new Date()
        return day === today.getDate() && calendarNow.getMonth() === today.getMonth() && calendarNow.getFullYear() === today.getFullYear()
    }

    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: "#9f8f7c"

    MouseArea { anchors.fill: parent; onClicked: mediaPopup.opened = false }

    Item {
        id: mediaMenuContainer
        anchors.horizontalCenter: parent.horizontalCenter
        y: mediaPopup.barHeight + 6
        width: Math.min(738, mediaPopup.width - 20)
        height: mediaPopup.opened ? 260 : 0
        clip: true
        opacity: mediaPopup.opened ? 1 : 0
        Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 1
            radius: 0
            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 3
                color: panelAccent
                opacity: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? 1 : 0.35
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Row {
                anchors.fill: parent
                anchors.margins: 14
                anchors.leftMargin: 16
                spacing: 14

                Rectangle {
                    width: 126
                    height: 126
                    y: 8
                    radius: 0
                    color: panelFg
                    opacity: 0.12
                    clip: true

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: activePlayer && activePlayer.trackArtUrl !== "" ? activePlayer.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: source !== ""
                    }

                    Rectangle { anchors.fill: parent; color: panelBg; opacity: 0.14; visible: albumArt.visible }
                    Text { anchors.centerIn: parent; text: ""; color: panelFg; font.pixelSize: 36; visible: !albumArt.visible }
                }

                Item {
                    width: 270
                    height: parent.height

                    Row {
                        width: parent.width
                        y: 0
                        height: 18
                        spacing: 8
                        Text { text: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? "NOW PLAYING" : "MEDIA"; color: panelAccent; font.pixelSize: 9; font.letterSpacing: 4; font.bold: true }
                        Text { text: activePlayer && activePlayer.identity ? "// " + activePlayer.identity : ""; color: panelFg; font.pixelSize: 10; opacity: 0.45; elide: Text.ElideRight; width: parent.width - 130 }
                    }

                    Text { x: 0; width: parent.width; height: 20; y: 28; verticalAlignment: Text.AlignVCenter; text: activePlayer && activePlayer.trackTitle !== "" ? activePlayer.trackTitle : "No music playing"; color: panelFg; font.pixelSize: 15; font.bold: true; elide: Text.ElideRight; maximumLineCount: 1 }
                    Text { x: 0; width: parent.width; height: 16; y: 52; verticalAlignment: Text.AlignVCenter; text: activePlayer && activePlayer.trackArtist !== "" ? activePlayer.trackArtist : (activePlayer && activePlayer.trackAlbum !== "" ? activePlayer.trackAlbum : "Open a player to start playback"); color: panelFg; font.pixelSize: 11; opacity: 0.62; elide: Text.ElideRight; maximumLineCount: 1 }

                    Item {
                        width: parent.width
                        y: 86
                        height: 14
                        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: 3; color: panelFg; opacity: 0.13 }
                        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: parent.width * playerProgress(activePlayer); height: 3; color: panelAccent; Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
                    }

                    Row {
                        id: controlsRow
                        width: controlsRow.implicitWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 104
                        height: 28
                        spacing: 8

                        Text { text: activePlayer && activePlayer.lengthSupported ? formatTime(activePlayer.position) + " / " + formatTime(activePlayer.length) : "--:--"; color: panelFg; opacity: 0.55; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; width: 120; elide: Text.ElideRight }

                        Rectangle {
                            width: 26; height: 26
                            color: prevMouse.containsMouse ? panelAccent : "transparent"
                            border.color: panelAccent
                            border.width: prevMouse.containsMouse ? 1 : 0
                            opacity: activePlayer && activePlayer.canGoPrevious ? 1 : 0.35
                            Text { anchors.centerIn: parent; text: "󰒮"; color: prevMouse.containsMouse ? panelBg : panelFg; font.pixelSize: 15 }
                            MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (activePlayer && activePlayer.canGoPrevious) activePlayer.previous() }
                        }

                        Rectangle {
                            width: 30; height: 26
                            color: playMouse.containsMouse || (activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing) ? panelAccent : "transparent"
                            border.color: panelAccent
                            border.width: playMouse.containsMouse || (activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing) ? 1 : 0
                            opacity: activePlayer && activePlayer.canTogglePlaying ? 1 : 0.35
                            Text { anchors.centerIn: parent; text: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"; color: playMouse.containsMouse || (activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing) ? panelBg : panelFg; font.pixelSize: 18 }
                            MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (activePlayer && activePlayer.canTogglePlaying) activePlayer.togglePlaying() }
                        }

                        Rectangle {
                            width: 26; height: 26
                            color: nextMouse.containsMouse ? panelAccent : "transparent"
                            border.color: panelAccent
                            border.width: nextMouse.containsMouse ? 1 : 0
                            opacity: activePlayer && activePlayer.canGoNext ? 1 : 0.35
                            Text { anchors.centerIn: parent; text: "󰒭"; color: nextMouse.containsMouse ? panelBg : panelFg; font.pixelSize: 15 }
                            MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (activePlayer && activePlayer.canGoNext) activePlayer.next() }
                        }
                    }

                    Row {
                        width: parent.width
                        y: 164
                        height: 34
                        spacing: 10
                        opacity: activePlayer ? 0.85 : 0.62
                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Row { anchors.verticalCenter: parent.verticalCenter; spacing: 4; Repeater { model: [11, 19, 14, 25, 17, 22, 12]; Rectangle { width: 3; height: modelData; anchors.verticalCenter: parent.verticalCenter; color: panelAccent; opacity: 0.35 } } }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: activePlayer ? "SIGNAL / 音" : "SHIZUKA / 静か"; color: panelAccent; font.pixelSize: 10; font.letterSpacing: 3; font.bold: true }
                    }
                }

                Rectangle { width: 1; height: parent.height - 8; anchors.verticalCenter: parent.verticalCenter; color: panelAccent; opacity: 0.28 }

                Item {
                    width: parent.width - 126 - 270 - 1 - 42
                    height: parent.height
                    Column {
                        anchors.fill: parent
                        spacing: 9
                        Row {
                            width: parent.width
                            height: 36
                            spacing: 10
                            Rectangle { width: 3; height: parent.height; color: panelAccent }
                            Column { anchors.verticalCenter: parent.verticalCenter; spacing: 2; Text { text: "KOYOMI"; color: panelAccent; font.pixelSize: 9; font.letterSpacing: 4; font.bold: true } Text { text: monthNames[calendarNow.getMonth()] + " " + calendarNow.getFullYear(); color: panelFg; font.pixelSize: 18; font.weight: Font.DemiBold } }
                        }
                        Rectangle { width: parent.width; height: 1; color: panelAccent; opacity: 0.45 }
                        Grid { width: parent.width; columns: 7; rowSpacing: 6; columnSpacing: 5; Repeater { model: dayNames; Text { width: (parent.width - 30) / 7; height: 16; text: modelData; color: mutedFg; font.pixelSize: 10; font.letterSpacing: 1; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } } }
                        Grid {
                            width: parent.width
                            columns: 7
                            rowSpacing: 4
                            columnSpacing: 5
                            Repeater {
                                model: 42
                                Rectangle {
                                    property int day: calendarDayForCell(index)
                                    property bool activeDay: day > 0 && day <= daysInCalendarMonth()
                                    property bool today: activeDay && isCalendarToday(day)
                                    width: (parent.width - 30) / 7
                                    height: 22
                                    color: today ? panelAccent : (activeDay ? Qt.rgba(1, 1, 1, 0.035) : "transparent")
                                    border.color: activeDay && !today ? Qt.rgba(1, 1, 1, 0.055) : "transparent"
                                    border.width: activeDay && !today ? 1 : 0
                                    radius: 0
                                    Text { anchors.centerIn: parent; text: parent.activeDay ? parent.day.toString() : ""; color: parent.today ? panelBg : panelFg; opacity: parent.activeDay ? 1 : 0; font.pixelSize: 11; font.weight: parent.today ? Font.DemiBold : Font.Normal }
                                }
                            }
                        }
                    }
                }
            }
        }

        Timer {
            interval: 1000
            running: mediaPopup.opened && activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing
            repeat: true
            onTriggered: activePlayer.positionChanged()
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import "." as AboutUi
import "../../ui" as SharedUi

PanelWindow {
    id: aboutWindow

    property var theme: null
    property bool opened: false
    property alias themeName: systemInfo.themeName
    property int shellUptime: 0

    readonly property string panelBg: theme ? theme.background : "#11130f"
    readonly property string panelFg: theme ? theme.foreground : "#e8ddc7"
    readonly property string panelAccent: theme ? theme.accent : "#b7372f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#958b7a"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#191b16"

    readonly property string screensText: {
        var count = Quickshell.screens ? Quickshell.screens.length : 0
        return count === 1 ? "1 connected" : count + " connected"
    }

    readonly property var shellItems: [
        { icon: "󰋼", label: "Version", value: systemInfo.shellVersion },
        { icon: "󰔛", label: "Running", value: formatUptime(shellUptime) },
        { icon: "󰒓", label: "Runtime", value: systemInfo.quickshellVersion },
        { icon: "󰐱", label: "Modules", value: systemInfo.moduleSummary },
        { icon: "󱄄", label: "Screens", value: screensText },
        { icon: "󰉉", label: "Wallpaper", value: systemInfo.wallpaperName },
        { icon: "󰉋", label: "Config", value: systemInfo.configPath }
    ].filter(function (item) { return item.value !== ""; })

    readonly property int shellRows: Math.max(1, shellItems.length)
    // DashPanel chrome (header, rule, margins) is 60px; rows are 32 with 6 between.
    readonly property int panelHeight: 60 + shellRows * 32 + (shellRows - 1) * 6
    readonly property int frameHeight: 16 + 44 + 12 + 1 + 12 + panelHeight + 16

    function formatUptime(seconds) {
        if (seconds <= 0) return "just started"
        var days = Math.floor(seconds / 86400)
        var hours = Math.floor((seconds % 86400) / 3600)
        var minutes = Math.floor((seconds % 3600) / 60)
        if (days > 0) return days + "d " + hours + "h"
        if (hours > 0) return hours + "h " + minutes + "m"
        if (minutes > 0) return minutes + "m " + (seconds % 60) + "s"
        return seconds + "s"
    }

    function updateUptime() {
        var launched = Quickshell.launchTime
        if (!launched) return
        shellUptime = Math.max(0, Math.floor((Date.now() - launched.getTime()) / 1000))
    }

    onOpenedChanged: if (opened) {
        systemInfo.refreshInfo()
        updateUptime()
    }

    function parseInfo(output) { systemInfo.parseInfo(output) }
    function refreshInfo() { systemInfo.refreshInfo() }

    AboutUi.SystemInfoController { id: systemInfo }

    Timer {
        interval: 1000
        running: aboutWindow.opened
        repeat: true
        onTriggered: aboutWindow.updateUptime()
    }

    visible: opened || content.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.about"
    WlrLayershell.exclusiveZone: -1

    MouseArea { anchors.fill: parent; enabled: opened; onClicked: opened = false }

    Item {
        id: content
        anchors.centerIn: parent
        enabled: opened
        width: Math.min(860, parent.width - 44)
        height: Math.min(aboutWindow.frameHeight, parent.height - 64)
        opacity: opened ? 1 : 0
        scale: opened ? 1 : 0.98
        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 1
            radius: 0
            clip: true

            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Item {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 16
                height: 44

                Column {
                    anchors.left: parent.left
                    anchors.right: headerMeta.left
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "ABOUT OMI SHELL"
                        color: panelFg
                        font.pixelSize: 12
                        font.letterSpacing: 3
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: "Identity, runtime and configuration"
                        color: mutedFg
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Column {
                    id: headerMeta
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        anchors.right: parent.right
                        text: systemInfo.shellVersion !== "" ? systemInfo.shellVersion : "omi shell"
                        color: panelFg
                        font.pixelSize: 15
                        font.weight: Font.Light
                    }

                    Text {
                        anchors.right: parent.right
                        text: aboutWindow.themeName !== "" ? aboutWindow.themeName.toUpperCase() : "NO THEME"
                        color: panelAccent
                        font.pixelSize: 9
                        font.letterSpacing: 2
                        font.bold: true
                    }
                }
            }

            Rectangle {
                id: headerRule
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 12
                height: 1
                color: mutedFg
                opacity: 0.35
            }

            Row {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: headerRule.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 12
                anchors.bottomMargin: 16
                spacing: 14

                Rectangle {
                    width: 286
                    height: body.height
                    color: inkBg
                    border.color: panelAccent
                    border.width: 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        color: panelAccent
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 36
                        spacing: 9

                        Item {
                            width: 210
                            height: 210
                            anchors.horizontalCenter: parent.horizontalCenter

                            Image {
                                id: fastfetchLogo
                                anchors.fill: parent
                                source: "file://" + Quickshell.env("HOME") + "/.config/fastfetch/omi.png"
                                sourceSize: Qt.size(420, 420)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                mipmap: true
                            }

                            SharedUi.ShellLogo {
                                anchors.centerIn: parent
                                visible: fastfetchLogo.status === Image.Error
                                size: 150
                                color: panelAccent
                            }
                        }

                        Text {
                            width: parent.width
                            text: "OMI SHELL"
                            color: panelFg
                            font.pixelSize: 18
                            font.bold: true
                            font.letterSpacing: 4
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            width: parent.width
                            text: systemInfo.userHost !== "" ? systemInfo.userHost : "Quickshell desktop shell"
                            color: mutedFg
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 56
                            height: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: panelAccent
                        }

                        Text {
                            width: parent.width
                            text: aboutWindow.themeName !== "" ? aboutWindow.themeName.toUpperCase() : "NO ACTIVE THEME"
                            color: panelAccent
                            font.pixelSize: 8
                            font.bold: true
                            font.letterSpacing: 2
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                AboutUi.InfoSectionCard {
                    width: body.width - 286 - body.spacing
                    height: body.height
                    theme: aboutWindow.theme
                    title: "SHELL DETAILS"
                    kanji: ""
                    trailing: shellItems.length + " ITEMS"
                    entries: aboutWindow.shellItems
                    border.color: Qt.rgba(1, 1, 1, 0.09)
                }
            }
        }
    }
}

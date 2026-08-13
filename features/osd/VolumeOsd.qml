import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: osd

    property var theme: null
    property int volumePercent: 0
    property bool muted: false
    property bool shown: false

    readonly property color panelBg: theme ? theme.background : "#15110f"
    readonly property color panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property color panelAccent: theme ? theme.accent : "#d7472f"
    readonly property color mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property color inkBg: theme && theme.surface ? theme.surface : "#1b1613"
    readonly property real volumeRatio: Math.max(0, Math.min(1, volumePercent / 150))

    function showVolume(percent, isMuted, targetScreen) {
        if (targetScreen) screen = targetScreen
        volumePercent = percent
        muted = isMuted
        shown = true
        hideTimer.restart()
    }

    visible: shown || content.opacity > 0
    implicitWidth: 300
    implicitHeight: 66
    color: "transparent"
    mask: Region {}
    anchors.bottom: true
    margins.bottom: 42
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.volume-osd"
    WlrLayershell.exclusiveZone: -1

    Rectangle {
        id: content

        anchors.fill: parent
        color: osd.panelBg
        border.color: osd.panelAccent
        border.width: 2
        radius: 0
        opacity: osd.shown ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.Linear } }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            color: osd.panelAccent
        }

        Row {
            anchors.fill: parent
            anchors.margins: 12
            anchors.leftMargin: 16
            spacing: 12

            Rectangle {
                width: 38
                height: 38
                anchors.verticalCenter: parent.verticalCenter
                color: osd.inkBg
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: osd.muted || osd.volumePercent === 0 ? "" : ""
                    color: osd.muted ? osd.mutedFg : osd.panelAccent
                    font.family: "Symbols Nerd Font Mono"
                    font.pixelSize: 21
                }
            }

            Column {
                width: parent.width - 50
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7

                Row {
                    width: parent.width

                    Text {
                        width: parent.width - 48
                        text: "VOLUME"
                        color: osd.panelAccent
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    Text {
                        width: 48
                        text: osd.muted ? "MUTE" : osd.volumePercent + "%"
                        color: osd.muted ? osd.mutedFg : osd.panelFg
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Item {
                    width: parent.width
                    height: 6

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(1, 1, 1, 0.12)
                    }

                    Rectangle {
                        width: parent.width * osd.volumeRatio
                        height: parent.height
                        color: osd.muted ? osd.mutedFg : osd.panelAccent
                        opacity: osd.muted ? 0.45 : 1
                        Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: osd.shown = false
    }
}

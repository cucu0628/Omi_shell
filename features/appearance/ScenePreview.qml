import QtQuick
import "../../ui" as SharedUi

Rectangle {
    id: preview

    property var theme: null
    property var selectedTheme: null
    property var selectedWallpaper: null
    property var imageSource: function(path) { return path }
    property string activeSection: "wallpaper"
    property color previewBg: "#11130f"
    property color previewFg: "#e8ddc7"
    property color previewAccent: "#b7372f"
    property color previewSurface: "#191b16"
    property color previewMuted: "#958b7a"
    property color panelAccent: "#b7372f"
    property bool sceneApplied: false

    readonly property bool focused: activeSection === "wallpaper"

    radius: 0
    color: previewBg
    border.color: focused ? previewAccent : Qt.rgba(1, 1, 1, 0.07)
    border.width: 1
    clip: true
    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Image {
        anchors.fill: parent
        source: preview.selectedWallpaper ? preview.imageSource(preview.selectedWallpaper.path) : ""
        sourceSize: Qt.size(1280, 1280)
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: false
    }

    Rectangle { anchors.fill: parent; color: preview.previewBg; opacity: 0.18 }

    // Mock of the real bar: torii mark, workspaces, clock.
    Rectangle {
        id: mockBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 28
        color: preview.previewBg
        opacity: 0.94

        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: preview.previewAccent; opacity: 0.55 }

        SharedUi.ShellLogo {
            id: mockLogo
            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            size: 14
            color: preview.previewFg
        }

        Row {
            anchors.left: mockLogo.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 11

            Repeater {
                model: ["1", "2", "3", "4"]

                Text {
                    required property string modelData
                    required property int index
                    text: modelData
                    color: index === 0 ? preview.previewAccent : preview.previewFg
                    opacity: index === 0 ? 1 : 0.6
                    font.pixelSize: 9
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: Qt.formatTime(new Date(), "HH:mm")
            color: preview.previewFg
            font.pixelSize: 9
            font.letterSpacing: 1
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9

            Repeater {
                model: ["󰤨", "󰕾", "󰂚"]

                Text {
                    required property string modelData
                    text: modelData
                    color: preview.previewFg
                    font.pixelSize: 9
                }
            }
        }
    }

    // Mock of a shell popup, drawn with the candidate palette.
    Rectangle {
        width: Math.min(236, parent.width * 0.38)
        height: 186
        x: 26
        y: mockBar.height + 26
        color: preview.previewBg
        opacity: 0.96
        border.color: preview.previewAccent
        border.width: 1

        Rectangle {
            id: mockSeal
            x: 14
            y: 14
            width: 30
            height: 30
            color: preview.previewAccent

            SharedUi.ShellLogo {
                anchors.centerIn: parent
                size: 18
                color: preview.previewBg
            }
        }

        Text {
            id: mockTitle
            anchors.left: mockSeal.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 14
            y: 17
            text: "SHELL MENU"
            color: preview.previewFg
            font.pixelSize: 10
            font.letterSpacing: 3
            font.bold: true
        }

        Text {
            anchors.left: mockTitle.left
            anchors.right: mockTitle.right
            y: 32
            text: "献立  /  komorebi"
            color: preview.previewMuted
            font.pixelSize: 8
            elide: Text.ElideRight
        }

        Rectangle {
            id: mockRule
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            y: 56
            height: 1
            color: preview.previewAccent
            opacity: 0.3
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.top: mockRule.bottom
            anchors.topMargin: 12
            spacing: 6

            Repeater {
                model: ["Applications", "Clipboard", "System"]

                Rectangle {
                    required property string modelData
                    required property int index

                    width: parent.width
                    height: 28
                    color: index === 0 ? preview.previewSurface : "transparent"
                    border.color: index === 0 ? preview.previewAccent : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: preview.previewAccent
                        opacity: index === 0 ? 1 : 0.4
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: index === 0 ? preview.previewAccent : preview.previewFg
                        font.pixelSize: 10
                    }
                }
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: "景\n色"
        color: preview.previewFg
        opacity: 0.16
        font.pixelSize: 38
        lineHeight: 0.82
    }

    // Flat plaque rather than bare text: the name sits over arbitrary artwork,
    // so it needs its own ground to stay readable on bright wallpapers.
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        width: plaque.implicitWidth + 44
        height: plaque.implicitHeight + 24
        color: preview.previewBg
        opacity: 0.92
        border.color: preview.previewAccent
        border.width: 1

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: preview.previewAccent
        }

        Column {
            id: plaque
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.right: parent.right
                text: preview.selectedWallpaper ? preview.selectedWallpaper.name.toUpperCase() : "NO WALLPAPER"
                color: preview.previewFg
                font.pixelSize: 18
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Text {
                anchors.right: parent.right
                text: preview.selectedTheme ? preview.selectedTheme.name : "No palette"
                color: preview.previewAccent
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 2
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 196
        height: 76
        visible: preview.sceneApplied
        color: preview.previewBg
        border.color: preview.previewAccent
        border.width: 1
        opacity: preview.sceneApplied ? 0.96 : 0

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "適用"; color: preview.previewAccent; font.pixelSize: 20; font.bold: true }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "SCENE APPLIED"; color: preview.previewFg; font.pixelSize: 9; font.bold: true; font.letterSpacing: 2 }
        }
    }
}

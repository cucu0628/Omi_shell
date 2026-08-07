import QtQuick
import "../../ui" as SharedUi

SharedUi.DashPanel {
    id: filmstrip

    property var wallpaperItems: []
    property int selectedWallpaperIndex: 0
    property string activeSection: "wallpaper"
    property var imageSource: function(path) { return path }
    property color panelBg: "#11130f"
    property color panelFg: "#e8ddc7"
    property color panelAccent: "#b7372f"
    property color panelSurface: "#191b16"
    property color mutedFg: "#958b7a"
    property bool imagesEnabled: false

    signal wallpaperSelected(int index)

    title: "WALLPAPER FILM"
    kanji: "壁紙"
    trailing: filmstrip.activeSection === "wallpaper"
        ? wallpaperItems.length + " FRAMES  ·  ← →"
        : wallpaperItems.length + " FRAMES  ·  TAB"

    function ensureVisible() {
        var itemWidth = 126
        var left = selectedWallpaperIndex * itemWidth
        var maxX = Math.max(0, wallpaperList.contentWidth - wallpaperList.width)
        wallpaperList.contentX = Math.max(0, Math.min(left - wallpaperList.width * 0.35, maxX))
        if (!imagesEnabled) thumbnailEnableTimer.restart()
    }

    onWallpaperItemsChanged: if (wallpaperItems.length === 0) imagesEnabled = false

    Timer {
        id: thumbnailEnableTimer
        interval: 0
        onTriggered: filmstrip.imagesEnabled = true
    }

    ListView {
        id: wallpaperList
        anchors.fill: parent
        orientation: ListView.Horizontal
        model: filmstrip.wallpaperItems
        spacing: 8
        reuseItems: true
        cacheBuffer: 64
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        WheelHandler {
            target: null
            onWheel: (event) => {
                var delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y
                var maxX = Math.max(0, wallpaperList.contentWidth - wallpaperList.width)
                wallpaperList.contentX = Math.max(0, Math.min(wallpaperList.contentX - delta, maxX))
                event.accepted = true
            }
        }

        delegate: Rectangle {
            id: frame
            property bool current: index === filmstrip.selectedWallpaperIndex

            width: 118
            height: wallpaperList.height
            radius: 0
            color: filmstrip.panelBg
            border.color: frame.current
                ? filmstrip.panelAccent
                : (wallpaperMouse.containsMouse ? filmstrip.mutedFg : Qt.rgba(1, 1, 1, 0.06))
            border.width: 1
            opacity: frame.current || wallpaperMouse.containsMouse ? 1 : 0.6
            clip: true
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: filmstrip.imagesEnabled ? filmstrip.imageSource(modelData.path) : ""
                sourceSize: Qt.size(256, 256)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                cache: false
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 1
                height: 18
                color: filmstrip.panelBg
                opacity: 0.9
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 7
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                text: modelData.name
                color: frame.current ? filmstrip.panelAccent : filmstrip.panelFg
                font.pixelSize: 8
                font.bold: true
                elide: Text.ElideRight
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                color: filmstrip.panelAccent
                visible: frame.current
            }

            MouseArea {
                id: wallpaperMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: filmstrip.wallpaperSelected(index)
            }
        }
    }
}

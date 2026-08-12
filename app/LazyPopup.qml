import QtQuick

Item {
    id: lazyPopup

    property Component popupComponent
    property bool opened: false
    property bool loaded: false
    property bool unloadOnClose: true
    property var screen: null
    property string mode: ""
    readonly property var popup: popupLoader.item

    width: 0
    height: 0
    visible: false

    onOpenedChanged: {
        if (opened) {
            unloadTimer.stop()
            loaded = true
            if (popup) popup.opened = true
        } else {
            if (popup) popup.opened = false
            if (unloadOnClose) unloadTimer.restart()
        }
    }

    onScreenChanged: {
        if (popup && screen !== null) popup.screen = screen
    }

    Timer {
        id: unloadTimer
        interval: 300
        onTriggered: {
            if (!lazyPopup.opened) {
                if (lazyPopup.popup && lazyPopup.popup.releaseResources)
                    lazyPopup.popup.releaseResources()
                lazyPopup.loaded = false
            }
        }
    }

    Loader {
        id: popupLoader
        active: lazyPopup.loaded
        asynchronous: true
        sourceComponent: lazyPopup.popupComponent

        onLoaded: {
            item.opened = lazyPopup.opened
            if (lazyPopup.screen !== null) item.screen = lazyPopup.screen
        }
    }

    Connections {
        target: popupLoader.item
        enabled: popupLoader.item !== null
        ignoreUnknownSignals: true

        function onOpenedChanged() {
            if (popupLoader.item.opened !== lazyPopup.opened)
                lazyPopup.opened = popupLoader.item.opened
        }

        function onScreenChanged() {
            if (popupLoader.item.screen !== lazyPopup.screen)
                lazyPopup.screen = popupLoader.item.screen
        }
    }
}

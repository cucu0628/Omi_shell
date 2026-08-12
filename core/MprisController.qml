import QtQuick
import Quickshell.Services.Mpris

Item {
    id: controller

    property string preferredPlayerDbusName: ""
    property var activePlayer: null

    width: 0
    height: 0
    visible: false

    function isBrowserPlayer(player) {
        if (!player) return false
        var name = ((player.identity || "") + " " + (player.dbusName || "")).toLowerCase()
        return name.indexOf("firefox") !== -1
            || name.indexOf("zen") !== -1
            || name.indexOf("chromium") !== -1
            || name.indexOf("chrome") !== -1
            || name.indexOf("brave") !== -1
            || name.indexOf("vivaldi") !== -1
            || name.indexOf("edge") !== -1
            || name.indexOf("browser") !== -1
    }

    function chooseActivePlayer() {
        var players = Mpris.players.values
        if (players.length === 0) {
            preferredPlayerDbusName = ""
            return null
        }

        for (var i = 0; i < players.length; i++) {
            if (!isBrowserPlayer(players[i]) && players[i].playbackState === MprisPlaybackState.Playing) {
                preferredPlayerDbusName = players[i].dbusName
                return players[i]
            }
        }

        if (preferredPlayerDbusName !== "") {
            for (var j = 0; j < players.length; j++) {
                if (players[j].dbusName === preferredPlayerDbusName) return players[j]
            }
        }

        for (var k = 0; k < players.length; k++) {
            if (!isBrowserPlayer(players[k]) && (players[k].trackTitle !== "" || players[k].trackArtist !== "")) {
                preferredPlayerDbusName = players[k].dbusName
                return players[k]
            }
        }

        if (activePlayer) {
            for (var activeIndex = 0; activeIndex < players.length; activeIndex++) {
                if (players[activeIndex] === activePlayer) return activePlayer
            }
        }

        for (var l = 0; l < players.length; l++) {
            if (players[l].playbackState === MprisPlaybackState.Playing) {
                preferredPlayerDbusName = players[l].dbusName
                return players[l]
            }
        }

        return null
    }

    function updateActivePlayer() {
        activePlayer = chooseActivePlayer()
    }

    Component.onCompleted: updateActivePlayer()

    Connections {
        target: Mpris.players

        function onValuesChanged() {
            controller.updateActivePlayer()
        }
    }

    Instantiator {
        model: Mpris.players

        delegate: Item {
            required property var modelData

            width: 0
            height: 0
            visible: false

            Connections {
                target: modelData

                function onPlaybackStateChanged() { controller.updateActivePlayer() }
                function onTrackTitleChanged() { controller.updateActivePlayer() }
                function onTrackArtistChanged() { controller.updateActivePlayer() }
            }
        }
    }
}

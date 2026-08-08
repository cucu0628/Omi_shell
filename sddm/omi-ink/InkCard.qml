import QtQuick
import "." as Ink

FocusScope {
    id: card

    required property var greeter

    readonly property bool opened: greeter.revealStep >= 2 && !greeter.closing
    readonly property int panelHeight: 252
    readonly property int panelWidth: Math.max(480, Math.min(card.width - 160, 780))
    readonly property color baseColor: greeter.background

    readonly property bool hasKeyboard: (typeof keyboard !== "undefined") && keyboard.enabled && keyboard.layouts.length > 0
    readonly property string layoutText: hasKeyboard ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""

    // Az eppen nyitott lista tipusa – zaraskor is megmarad, hogy a kihalvanyodo
    // legordulo tartalma ne valtson at menet kozben.
    property string activePicker: ""

    focus: true

    function positionDropdown() {
        var source = card.activePicker === "user"
            ? userPicker
            : (card.activePicker === "session" ? sessionPicker : null)
        if (!source) return

        var point = source.mapToItem(card, 0, source.height)
        dropdown.x = Math.max(12, Math.min(card.width - dropdown.width - 12, point.x - 10))
        dropdown.y = point.y + 12
    }

    Connections {
        target: card.greeter

        function onOpenPickerChanged() {
            if (card.greeter.openPicker !== "") {
                card.activePicker = card.greeter.openPicker
                card.positionDropdown()
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (card.greeter.openPicker !== "") card.greeter.openPicker = ""
            else card.greeter.clearPassword()
            event.accepted = true
        }
    }

    // Kattintas a felulet barmely mas pontjara bezarja a nyitott listat.
    MouseArea {
        anchors.fill: parent
        z: 40
        enabled: card.greeter.openPicker !== ""
        onClicked: card.greeter.openPicker = ""
    }

    Item {
        id: panelClip

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -18
        width: card.panelWidth
        height: card.opened ? card.panelHeight : 0
        clip: true

        Behavior on height {
            NumberAnimation { duration: card.greeter.closing ? 200 : 480; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: panel

            width: parent.width
            height: card.panelHeight
            y: (parent.height - height) / 2
            radius: 0
            color: Qt.rgba(card.baseColor.r, card.baseColor.g, card.baseColor.b, 0.88)
            border.color: card.greeter.failed ? card.greeter.alertColor : card.greeter.accent
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 160 } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.color: card.greeter.accent
                border.width: 1
                opacity: 0.2
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                height: 2
                color: card.greeter.accent
                opacity: 0.75
            }

            Item {
                id: body

                anchors.fill: parent
                anchors.leftMargin: 30
                anchors.rightMargin: 30
                anchors.topMargin: 26
                anchors.bottomMargin: 26

                readonly property int leftWidth: Math.round(width * 0.42)

                Ink.InkClock {
                    id: clockView

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: body.leftWidth - 26
                    greeter: card.greeter
                    timeSize: 68
                    barWidth: width * 0.84
                    opacity: card.greeter.revealStep >= 3 ? 1 : 0

                    transform: Translate {
                        x: card.greeter.revealStep >= 3 ? 0 : -12
                        Behavior on x { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
                    }

                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    id: divider

                    x: body.leftWidth
                    width: 1
                    height: parent.height
                    color: card.greeter.accent
                    opacity: 0.16
                }

                Item {
                    anchors.left: divider.right
                    anchors.leftMargin: 28
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: authColumn.height
                    opacity: card.greeter.revealStep >= 4 ? 1 : 0

                    transform: Translate {
                        y: card.greeter.revealStep >= 4 ? 0 : 10
                        Behavior on y { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
                    }

                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

                    Column {
                        id: authColumn

                        width: parent.width
                        spacing: 15

                        Row {
                            spacing: 15

                            Ink.InkSeal {
                                diameter: 56
                                greeter: card.greeter
                                busy: card.greeter.busy
                                alert: card.greeter.failed
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    text: card.greeter.userLabel
                                    color: card.greeter.foreground
                                    font.pixelSize: 20
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: card.greeter.hostText !== ""
                                        ? card.greeter.hostText.toUpperCase()
                                        : card.greeter.themeName.toUpperCase()
                                    color: card.greeter.muted
                                    font.pixelSize: 10
                                    font.letterSpacing: 1
                                }
                            }
                        }

                        Ink.InkPasswordField {
                            id: passwordField

                            width: parent.width
                            greeter: card.greeter
                        }

                        Text {
                            width: parent.width
                            text: card.greeter.statusText
                            color: card.greeter.failed ? card.greeter.alertColor : card.greeter.muted
                            font.pixelSize: 11
                            font.letterSpacing: 0.6
                            elide: Text.ElideRight
                            opacity: card.greeter.revealStep >= 5 ? 1 : 0

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }

    // --- also sav: felhasznalo, munkamenet, billentyuzet, energia ---
    Item {
        id: strip

        z: 50
        width: card.panelWidth
        height: 36
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: card.panelHeight / 2 + 8
        opacity: card.greeter.revealStep >= 5 && !card.greeter.closing ? 1 : 0

        transform: Translate {
            y: card.greeter.revealStep >= 5 ? 0 : 10
            Behavior on y { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 26

            Ink.InkPicker {
                id: userPicker

                greeter: card.greeter
                pickerId: "user"
                kanji: "利用者"
                label: "USER"
                entries: card.greeter.users
                currentIndex: card.greeter.userIndex
                anchors.verticalCenter: parent.verticalCenter
            }

            Ink.InkPicker {
                id: sessionPicker

                greeter: card.greeter
                pickerId: "session"
                kanji: "環境"
                label: "SESSION"
                entries: card.greeter.sessions
                currentIndex: card.greeter.sessionIndex
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Billentyuzetkiosztas – kattintasra korbe lepteti a kiosztasokat.
            Ink.InkPowerButton {
                greeter: card.greeter
                visible: card.hasKeyboard
                kanji: card.layoutText
                label: "LAYOUT"
                anchors.verticalCenter: parent.verticalCenter
                onActivated: {
                    if (keyboard.layouts.length > 1)
                        keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
                    passwordField.forceInputFocus()
                }
            }

            Rectangle {
                width: 1
                height: 18
                color: card.greeter.accent
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }

            Ink.InkPowerButton {
                greeter: card.greeter
                kanji: "休止"
                label: "SLEEP"
                enabled: sddm.canSuspend
                anchors.verticalCenter: parent.verticalCenter
                onActivated: sddm.suspend()
            }

            Ink.InkPowerButton {
                greeter: card.greeter
                kanji: "再起動"
                label: "RESTART"
                enabled: sddm.canReboot
                anchors.verticalCenter: parent.verticalCenter
                onActivated: sddm.reboot()
            }

            Ink.InkPowerButton {
                greeter: card.greeter
                kanji: "電源"
                label: "SHUTDOWN"
                danger: true
                enabled: sddm.canPowerOff
                anchors.verticalCenter: parent.verticalCenter
                onActivated: sddm.powerOff()
            }
        }
    }

    // A legordulo lista a kartya kozvetlen gyereke: igy semmilyen szuloi hatar
    // vagy alatta fekvo kattintasfogo nem nyeli el az egereseményeket.
    Ink.InkPickerList {
        id: dropdown

        z: 60
        greeter: card.greeter
        open: card.greeter.openPicker !== ""
        entries: card.activePicker === "user" ? card.greeter.users : card.greeter.sessions
        currentIndex: card.activePicker === "user" ? card.greeter.userIndex : card.greeter.sessionIndex

        onPicked: (index) => {
            if (card.activePicker === "user") card.greeter.selectUser(index)
            else card.greeter.selectSession(index)
            card.greeter.openPicker = ""
            passwordField.forceInputFocus()
        }
    }

    // A jelszomezo tartja a fokuszt; ha barmi elvenne, visszaadjuk neki.
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            if (!passwordField.inputActive) passwordField.forceInputFocus()
        }
    }

    Component.onCompleted: passwordField.forceInputFocus()
}

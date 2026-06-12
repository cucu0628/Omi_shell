import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    property string password: ""
    property bool unlockInProgress: false
    property bool failed: false
    property string statusText: "Enter password"
    property string background: "#1e1e2e"
    property string foreground: "#cdd6f4"
    property string accent: "#89b4fa"
    property bool ready: false
    property bool closing: false
    property var currentTime: new Date()
    property string powerText: "Desktop power"

    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.config/omarchy/current/theme/gum.env.conf"
        blockLoading: true
        watchChanges: true
    }

    function updateColors() {
        var text = themeFile.text()
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.startsWith("env = BACKGROUND,")) background = line.split(",")[1].replace("##", "#")
            else if (line.startsWith("env = FOREGROUND,")) foreground = line.split(",")[1].replace("##", "#")
            else if (line.startsWith("env = BORDER_FOREGROUND,")) accent = line.split(",")[1].replace("##", "#")
        }
    }

    Component.onCompleted: {
        if (themeFile.loaded) updateColors()
        refreshPowerStatus()
        introTimer.start()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentTime = new Date()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: refreshPowerStatus()
    }

    Process {
        id: powerFetcher
        stdout: StdioCollector {
            onStreamFinished: root.powerText = (this.text || "Desktop power").trim()
        }
    }

    function refreshPowerStatus() {
        powerFetcher.command = ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] || continue; cap=$(cat \"$b/capacity\"); status=$(cat \"$b/status\" 2>/dev/null); printf '%s%% · %s\\n' \"$cap\" \"$status\"; exit; done; for a in /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/Mains*; do [ -e \"$a\" ] && printf 'AC power\\n' && exit; done; printf 'Desktop power\\n'"]
        powerFetcher.running = true
    }

    Timer {
        id: introTimer
        interval: 80
        onTriggered: ready = true
    }

    Connections {
        target: themeFile
        function onLoadedChanged() {
            if (themeFile.loaded) updateColors()
        }
    }

    function tryUnlock() {
        if (password === "" || unlockInProgress) return
        unlockInProgress = true
        failed = false
        statusText = "Checking..."
        pam.start()
    }

    function finishUnlock() {
        closing = true
        unlockExitTimer.start()
    }

    Timer {
        id: unlockExitTimer
        interval: 260
        onTriggered: {
            sessionLock.locked = false
            Qt.quit()
        }
    }

    PamContext {
        id: pam
        config: "hyprlock"

        onPamMessage: {
            if (responseRequired) respond(root.password)
        }

        onCompleted: (result) => {
            unlockInProgress = false
            if (result == PamResult.Success || result == 0 || PamResult.toString(result) === "Success") {
                finishUnlock()
            } else {
                password = ""
                failed = true
                statusText = "Wrong password"
            }
        }

        onError: (error) => {
            unlockInProgress = false
            password = ""
            failed = true
            statusText = PamError.toString(error)
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            id: surface
            color: root.background

            Rectangle {
                anchors.fill: parent
                color: root.background

                Behavior on color { ColorAnimation { duration: 180 } }
            }

            Rectangle {
                id: topGlow
                width: 220
                height: 220
                radius: 110
                color: root.accent
                opacity: root.ready && !root.closing ? 0.075 : 0
                x: parent.width - 140 + glowDrift.x
                y: -95 + glowDrift.y

                Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 180 } }
            }

            Rectangle {
                id: bottomGlow
                width: 180
                height: 180
                radius: 90
                color: "#f0b35a"
                opacity: root.ready && !root.closing ? 0.08 : 0
                x: -70 - glowDrift.x * 0.7
                y: parent.height - 90 - glowDrift.y * 0.7

                Behavior on opacity { NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }
            }

            QtObject {
                id: glowDrift
                property real x: 0
                property real y: 0
            }

            SequentialAnimation {
                running: true
                loops: Animation.Infinite

                ParallelAnimation {
                    NumberAnimation { target: glowDrift; property: "x"; to: 18; duration: 5200; easing.type: Easing.InOutSine }
                    NumberAnimation { target: glowDrift; property: "y"; to: 10; duration: 5200; easing.type: Easing.InOutSine }
                }

                ParallelAnimation {
                    NumberAnimation { target: glowDrift; property: "x"; to: -10; duration: 5600; easing.type: Easing.InOutSine }
                    NumberAnimation { target: glowDrift; property: "y"; to: -8; duration: 5600; easing.type: Easing.InOutSine }
                }
            }

            Item {
                id: ensoMark
                width: Math.min(parent.width, parent.height) * 0.58
                height: width
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 0
                anchors.verticalCenterOffset: 0
                opacity: root.ready && !root.closing ? 0.18 : 0
                rotation: 0
                scale: root.ready && !root.closing ? 1 : 0.96

                Behavior on opacity { NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }

                NumberAnimation on rotation {
                    running: true
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 42000
                }

                Rectangle {
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    color: "transparent"
                    border.color: root.accent
                    border.width: 1
                    opacity: 0.56
                }

                Rectangle {
                    width: parent.width * 0.42
                    height: parent.height * 0.24
                    radius: height / 2
                    color: root.background
                    anchors.right: parent.right
                    anchors.rightMargin: parent.width * -0.08
                    anchors.top: parent.top
                    anchors.topMargin: parent.height * 0.09
                    opacity: 0.96
                }

                Rectangle {
                    width: parent.width * 0.11
                    height: 2
                    radius: 1
                    color: root.accent
                    opacity: 0.46
                    anchors.right: parent.right
                    anchors.rightMargin: parent.width * 0.01
                    anchors.top: parent.top
                    anchors.topMargin: parent.height * 0.25
                    rotation: -18
                }
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: true

                Column {
                    id: lockCard
                    width: Math.min(parent.width * 0.82, 560)
                    spacing: 16
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -8
                    opacity: root.ready && !root.closing ? 1 : 0
                    scale: root.closing ? 0.975 : (root.ready ? 1 : 0.985)
                    transform: Translate {
                        y: root.closing ? -18 : (root.ready ? 0 : 20)
                        Behavior on y { NumberAnimation { duration: root.closing ? 180 : 360; easing.type: Easing.OutCubic } }
                    }

                    Behavior on opacity { NumberAnimation { duration: root.closing ? 150 : 280; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: root.closing ? 180 : 360; easing.type: Easing.OutCubic } }

                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: Qt.formatDateTime(root.currentTime, "HH:mm")
                            color: root.foreground
                            font.pixelSize: 78
                            font.weight: Font.Light
                            font.letterSpacing: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: Qt.formatDateTime(root.currentTime, "dddd, MMMM d")
                            color: "#9f8f7c"
                            font.pixelSize: 13
                            font.letterSpacing: 1.4
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Rectangle {
                        width: Math.min(parent.width * 0.54, 300)
                        height: 1
                        color: root.accent
                        opacity: 0.24
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Item {
                        width: parent.width
                        height: 120

                        Column {
                            spacing: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 46
                                height: 46
                                radius: 0
                                color: "transparent"
                                border.color: root.accent
                                border.width: 1
                                opacity: 0.92
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: "守"
                                    color: root.accent
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    anchors.centerIn: parent
                                }
                            }

                            Text {
                                text: "MAMORU"
                                color: root.accent
                                font.pixelSize: 10
                                font.letterSpacing: 8
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Locked"
                                color: root.foreground
                                font.pixelSize: 28
                                font.weight: Font.DemiBold
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Row {
                                spacing: 12
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: "quiet screen"
                                    color: "#9f8f7c"
                                    font.pixelSize: 12
                                }

                                Text {
                                    text: "// " + root.powerText
                                    color: root.accent
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: passwordBox
                        width: parent.width
                        height: 54
                        color: Qt.darker(root.background, 1.18)
                        border.color: root.failed ? "#d7472f" : root.accent
                        border.width: root.failed ? 2 : 1
                        radius: 0
                        transform: Translate { id: failedShake; x: 0 }

                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Behavior on border.width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        Connections {
                            target: root
                            function onFailedChanged() {
                                if (root.failed) shakeAnimation.restart()
                            }
                        }

                        SequentialAnimation {
                            id: shakeAnimation
                            NumberAnimation { target: failedShake; property: "x"; to: -10; duration: 45; easing.type: Easing.OutQuad }
                            NumberAnimation { target: failedShake; property: "x"; to: 10; duration: 70; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: failedShake; property: "x"; to: -7; duration: 60; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: failedShake; property: "x"; to: 5; duration: 55; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: failedShake; property: "x"; to: 0; duration: 80; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            width: 3
                            height: parent.height
                            anchors.left: parent.left
                            color: root.failed ? "#d7472f" : root.accent

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            text: ""
                            font.family: "omarchy"
                            font.pixelSize: 16
                            color: root.failed ? "#d7472f" : root.accent
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Rectangle {
                            id: checkingLine
                            property real slideMargin: 18

                            width: root.unlockInProgress ? 32 : 0
                            height: 1
                            anchors.right: parent.right
                            anchors.rightMargin: slideMargin
                            anchors.bottom: parent.bottom
                            color: root.accent
                            opacity: root.unlockInProgress ? 0.9 : 0

                            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            SequentialAnimation on slideMargin {
                                running: root.unlockInProgress
                                loops: Animation.Infinite
                                NumberAnimation { to: 58; duration: 640; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 18; duration: 640; easing.type: Easing.InOutSine }
                            }
                        }

                        TextInput {
                            id: passwordInput
                            anchors.left: parent.left
                            anchors.leftMargin: 56
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height - 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.foreground
                            font.pixelSize: 16
                            echoMode: TextInput.Password
                            inputMethodHints: Qt.ImhSensitiveData
                            enabled: !root.unlockInProgress
                            focus: true
                            text: root.password
                            onTextChanged: root.password = text
                            onAccepted: root.tryUnlock()

                            Text {
                                text: "Password"
                                color: "#9f8f7c"
                                visible: parent.text === ""
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 22
                        opacity: 0.86

                        Text {
                            text: "// " + root.statusText
                            color: root.failed ? "#d7472f" : "#9f8f7c"
                            font.pixelSize: 12
                            width: parent.width
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Text {
                        text: "press enter to unlock"
                        color: "#9f8f7c"
                        opacity: 0.58
                        font.pixelSize: 10
                        font.letterSpacing: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                Timer {
                    interval: 50
                    running: true
                    repeat: true
                    onTriggered: passwordInput.forceActiveFocus()
                }
            }
        }
    }
}

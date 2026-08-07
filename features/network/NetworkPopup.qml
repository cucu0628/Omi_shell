import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: networkWindow

    property var theme: null
    property var statusController: null
    property bool opened: false
    property bool wifiEnabled: true
    property bool scanning: false
    property bool connecting: false
    property bool selectedSecure: false
    property string busySsid: ""
    property string selectedSsid: ""
    property string errorMessage: ""
    property var networks: []
    readonly property string panelBg: theme ? theme.background : "#15110f"
    readonly property string panelFg: theme ? theme.foreground : "#f1e7d0"
    readonly property string panelAccent: theme ? theme.accent : "#d7472f"
    readonly property string mutedFg: theme && theme.muted ? theme.muted : "#9f8f7c"
    readonly property string inkBg: theme && theme.surface ? theme.surface : "#1b1613"
    readonly property color hoverBg: Qt.rgba(1, 1, 1, 0.075)

    function splitEscaped(line) {
        var fields = [];
        var field = "";
        var escaped = false;
        for (var i = 0; i < line.length; i++) {
            var character = line[i];
            if (escaped) {
                field += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":") {
                fields.push(field);
                field = "";
            } else {
                field += character;
            }
        }
        fields.push(field);
        return fields;
    }

    function refresh() {
        if (statusController)
            statusController.refresh();

        queryRadio();
        scanNetworks();
    }

    function queryRadio() {
        if (radioQuery.running)
            return ;

        radioQuery.command = ["nmcli", "-t", "-f", "WIFI", "general"];
        radioQuery.running = true;
    }

    function scanNetworks() {
        if (scanProcess.running || !wifiEnabled)
            return ;

        scanning = true;
        scanProcess.command = ["nmcli", "-t", "-e", "yes", "-f", "IN-USE,SSID,SIGNAL,SECURITY,DEVICE", "device", "wifi", "list", "--rescan", "yes"];
        scanProcess.running = true;
    }

    function parseNetworks(output) {
        var bySsid = {
        };
        var lines = (output || "").trim().split("\n");
        for (var i = 0; i < lines.length; i++) {
            if (lines[i] === "")
                continue;

            var fields = splitEscaped(lines[i]);
            if (fields.length < 5 || fields[1] === "")
                continue;

            var security = fields[3];
            var item = {
                "active": fields[0] === "*" || fields[0] === "yes",
                "ssid": fields[1],
                "signal": parseInt(fields[2]) || 0,
                "security": security,
                "secure": security !== "" && security !== "--",
                "enterprise": security.indexOf("802.1X") !== -1 || security.indexOf("EAP") !== -1,
                "device": fields[4]
            };
            if (!bySsid[item.ssid] || item.active || item.signal > bySsid[item.ssid].signal)
                bySsid[item.ssid] = item;

        }
        var result = [];
        for (var ssid in bySsid) result.push(bySsid[ssid])
        result.sort((a, b) => {
            return (b.active ? 1 : 0) - (a.active ? 1 : 0) || b.signal - a.signal;
        });
        networks = result;
        scanning = false;
    }

    function signalIcon(signal) {
        if (signal >= 75)
            return "󰤨";

        if (signal >= 50)
            return "󰤥";

        if (signal >= 25)
            return "󰤢";

        return "󰤟";
    }

    function chooseNetwork(network) {
        errorMessage = "";
        passwordInput.text = "";
        if (selectedSsid === network.ssid) {
            selectedSsid = "";
            return ;
        }
        selectedSsid = network.ssid;
        selectedSecure = network.secure;
        if (network.secure)
            passwordInput.forceActiveFocus();

    }

    function connectSelected() {
        if (selectedSsid === "" || connectProcess.running)
            return ;

        var command = ["nmcli"];
        if (selectedSecure)
            command.push("--ask");

        command.push("device", "wifi", "connect", selectedSsid);
        connecting = true;
        errorMessage = "";
        connectProcess.command = command;
        connectProcess.running = true;
    }

    function disconnectNetwork(network) {
        if (networkAction.running)
            return ;

        var device = network.device || (statusController ? statusController.device : "");
        if (device === "") {
            errorMessage = "切断失敗 / A Wi-Fi eszköz nem található";
            return ;
        }
        busySsid = network.ssid;
        networkAction.command = ["nmcli", "device", "disconnect", device];
        networkAction.running = true;
    }

    function openAdvancedSettings() {
        advancedLauncher.command = ["kcmshell6", "kcm_networkmanagement"];
        advancedLauncher.running = true;
        opened = false;
    }

    function connectionError(output) {
        var message = (output || "").trim();
        var lower = message.toLowerCase();
        if (lower.indexOf("secrets were required") !== -1 || lower.indexOf("not provided") !== -1)
            return "暗号エラー / Jelszó szükséges vagy hibás";

        if (lower.indexOf("no network with ssid") !== -1)
            return "電波なし / A hálózat már nem érhető el";

        if (lower.indexOf("activation failed") !== -1)
            return "接続失敗 / A kapcsolódás sikertelen";

        var lines = message.split("\n");
        return lines.length > 0 && lines[lines.length - 1] !== "" ? lines[lines.length - 1] : "接続失敗 / Connection failed";
    }

    function toggleWifi() {
        if (radioToggle.running)
            return ;

        radioToggle.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"];
        radioToggle.running = true;
    }

    onOpenedChanged: {
        if (opened) {
            refresh();
        } else {
            selectedSsid = "";
            passwordInput.text = "";
            errorMessage = "";
        }
    }
    visible: opened || content.opacity > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell.network"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        enabled: opened
        onClicked: opened = false
    }

    Item {
        id: content

        anchors.right: parent.right
        anchors.rightMargin: 10
        enabled: opened
        y: 32
        width: Math.min(430, parent.width - 20)
        height: opened ? Math.min(570, parent.height - 46, 280 + Math.min(networks.length, 5) * 56 + (selectedSsid !== "" ? 88 : 0)) : 0
        clip: true
        opacity: opened ? 1 : 0

        Rectangle {
            anchors.fill: parent
            color: panelBg
            border.color: panelAccent
            border.width: 1
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => {
                    return mouse.accepted = true;
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Row {
                    width: parent.width
                    height: 36
                    spacing: 10

                    Rectangle {
                        width: 36
                        height: 36
                        color: panelAccent

                        Text {
                            anchors.centerIn: parent
                            text: "網"
                            color: panelBg
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                    }

                    Column {
                        width: parent.width - 123
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: "NETWORK CONTROL"
                            color: panelFg
                            font.pixelSize: 12
                            font.letterSpacing: 3
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: statusController && statusController.connected ? "接続済み  /  " + (statusController.connectionType === "ethernet" ? "wired" : statusController.connectionName) : "無接続  /  offline"
                            color: mutedFg
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }

                    }

                    Rectangle {
                        width: 67
                        height: 30
                        anchors.verticalCenter: parent.verticalCenter
                        color: wifiEnabled ? panelAccent : inkBg
                        border.color: wifiEnabled ? panelAccent : mutedFg

                        Text {
                            anchors.centerIn: parent
                            text: wifiEnabled ? "WI-FI ON" : "WI-FI OFF"
                            color: wifiEnabled ? panelBg : mutedFg
                            font.family: "monospace"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toggleWifi()
                        }

                    }

                }

                Rectangle {
                    width: parent.width
                    height: 72
                    color: inkBg
                    border.color: "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        width: 3
                        height: parent.height
                        color: statusController && statusController.connected ? panelAccent : mutedFg
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Text {
                            width: 34
                            anchors.verticalCenter: parent.verticalCenter
                            text: statusController && statusController.connectionType === "ethernet" ? "󰈀" : (statusController && statusController.connected ? "󰤨" : "󰤭")
                            color: statusController && statusController.connected ? panelAccent : mutedFg
                            font.family: "Symbols Nerd Font Mono"
                            font.pixelSize: 25
                        }

                        Column {
                            width: parent.width - 46
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: statusController && statusController.connected ? (statusController.connectionType === "ethernet" ? "Ethernet / " : "Wi-Fi / ") + statusController.device : "接続なし / No connection"
                                color: panelFg
                                font.pixelSize: 13
                            }

                            Text {
                                text: "内網住所 / LAN IP    " + (statusController && statusController.lanIp !== "" ? statusController.lanIp : "---.---.---.---")
                                color: mutedFg
                                font.pixelSize: 12
                                font.letterSpacing: 0.5
                            }

                        }

                    }

                }

                Row {
                    width: parent.width
                    height: 28

                    Text {
                        width: parent.width - 190
                        text: scanning ? "探索中 / SCANNING..." : "AVAILABLE WI-FI  /  " + networks.length
                        color: panelAccent
                        font.family: "monospace"
                        font.pixelSize: 8
                        font.letterSpacing: 2
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: 110
                        height: parent.height
                        text: "詳細 / 802.1X"
                        color: advancedMouse.containsMouse ? panelAccent : mutedFg
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 10
                        font.family: "monospace"

                        MouseArea {
                            id: advancedMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: openAdvancedSettings()
                        }

                    }

                    Text {
                        width: 80
                        height: parent.height
                        text: "更新 / Refresh"
                        color: refreshMouse.containsMouse ? panelAccent : mutedFg
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 11
                        font.family: "monospace"

                        MouseArea {
                            id: refreshMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: refresh()
                        }

                    }

                }

                Item {
                    width: parent.width
                    height: parent.height - 184 - (selectedSsid !== "" ? 88 : 0)

                    Text {
                        anchors.centerIn: parent
                        visible: !wifiEnabled || (!scanning && networks.length === 0)
                        text: wifiEnabled ? "電波なし / No networks found" : "無線停止 / Wi-Fi is off"
                        color: mutedFg
                        font.pixelSize: 13
                    }

                    Flickable {
                        anchors.fill: parent
                        visible: wifiEnabled && networks.length > 0
                        contentHeight: networkColumn.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: networkColumn

                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: networks

                                Rectangle {
                                    width: networkColumn.width
                                    height: 52
                                    color: networkMouse.containsMouse || modelData.active || selectedSsid === modelData.ssid ? inkBg : "transparent"
                                    border.color: "transparent"
                                    border.width: 0

                                    Rectangle {
                                        anchors.left: parent.left
                                        width: 3
                                        height: parent.height
                                        color: panelAccent
                                        opacity: modelData.active || selectedSsid === modelData.ssid ? 1 : 0
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 10

                                        Text {
                                            width: 25
                                            height: parent.height
                                            text: signalIcon(modelData.signal)
                                            color: modelData.active ? panelAccent : panelFg
                                            font.family: "Symbols Nerd Font Mono"
                                            font.pixelSize: 19
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Column {
                                            width: parent.width - 129
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            Text {
                                                width: parent.width
                                                text: modelData.ssid
                                                color: panelFg
                                                font.pixelSize: 13
                                                font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: modelData.active ? "接続済み / Connected" : modelData.signal + "% / " + (modelData.secure ? modelData.security : "公開 / Open")
                                                color: modelData.active ? panelAccent : mutedFg
                                                font.family: "monospace"
                                                font.pixelSize: 9
                                            }

                                        }

                                        Text {
                                            width: 51
                                            height: parent.height
                                            text: modelData.active ? (busySsid === modelData.ssid ? "切断中" : "切断") : (modelData.enterprise ? "802.1X" : (modelData.secure ? "" : ""))
                                            color: modelData.active ? panelAccent : mutedFg
                                            font.family: modelData.active || modelData.enterprise ? "sans-serif" : "Symbols Nerd Font Mono"
                                            font.pixelSize: modelData.enterprise ? 9 : 11
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignRight
                                        }

                                    }

                                    MouseArea {
                                        id: networkMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.active)
                                                disconnectNetwork(modelData);
                                            else if (modelData.enterprise)
                                                openAdvancedSettings();
                                            else
                                                chooseNetwork(modelData);
                                        }
                                    }

                                }

                            }

                        }

                    }

                }

                Rectangle {
                    width: parent.width
                    height: selectedSsid !== "" ? 76 : 0
                    visible: height > 0
                    clip: true
                    color: inkBg
                    border.color: panelAccent
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Row {
                            width: parent.width
                            height: 34
                            spacing: 7

                            Rectangle {
                                width: parent.width - 92
                                height: parent.height
                                color: panelBg
                                border.color: passwordInput.activeFocus ? panelAccent : mutedFg

                                TextInput {
                                    id: passwordInput

                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    color: panelFg
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    font.pixelSize: 12
                                    Keys.onReturnPressed: connectSelected()

                                    Text {
                                        anchors.fill: parent
                                        visible: passwordInput.text === ""
                                        text: selectedSecure ? "暗号 / Password" : "暗号不要 / No password"
                                        color: mutedFg
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 11
                                    }

                                }

                            }

                            Rectangle {
                                width: 85
                                height: parent.height
                                color: panelAccent

                                Text {
                                    anchors.centerIn: parent
                                    text: connecting ? "接続中..." : "接続する"
                                    color: panelBg
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !connecting
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: connectSelected()
                                }

                            }

                        }

                        Text {
                            width: parent.width
                            text: errorMessage !== "" ? errorMessage : selectedSsid
                            color: errorMessage !== "" ? panelAccent : mutedFg
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }

                    }

                }

            }

        }

        Behavior on height {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }

        }

    }

    Process {
        id: radioQuery

        stdout: StdioCollector {
            onStreamFinished: networkWindow.wifiEnabled = (this.text || "").trim() === "enabled"
        }

    }

    Process {
        id: scanProcess

        onExited: networkWindow.scanning = false

        stdout: StdioCollector {
            onStreamFinished: networkWindow.parseNetworks(this.text || "")
        }

    }

    Process {
        id: radioToggle

        onExited: {
            networkWindow.queryRadio();
            radioRefreshTimer.restart();
        }
    }

    Process {
        id: connectProcess

        property string failureText: ""

        stdinEnabled: true
        onRunningChanged: {
            if (running)
                failureText = "";

        }
        onStarted: {
            if (networkWindow.selectedSecure)
                write(passwordInput.text + "\n");

        }
        onExited: (exitCode) => {
            networkWindow.connecting = false;
            if (exitCode === 0) {
                networkWindow.selectedSsid = "";
                passwordInput.text = "";
                connectionRefreshTimer.restart();
            } else {
                networkWindow.errorMessage = networkWindow.connectionError(failureText);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: connectProcess.failureText = this.text || ""
        }

    }

    Process {
        id: networkAction

        property string failureText: ""

        onRunningChanged: {
            if (running)
                failureText = "";

        }
        onExited: (exitCode) => {
            networkWindow.busySsid = "";
            if (exitCode !== 0)
                networkWindow.errorMessage = networkWindow.connectionError(failureText);

            connectionRefreshTimer.restart();
        }

        stderr: StdioCollector {
            onStreamFinished: networkAction.failureText = this.text || ""
        }

    }

    Process {
        id: advancedLauncher
    }

    Timer {
        id: radioRefreshTimer

        interval: 500
        onTriggered: networkWindow.refresh()
    }

    Timer {
        id: connectionRefreshTimer

        interval: 800
        onTriggered: networkWindow.refresh()
    }

}

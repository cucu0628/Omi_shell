import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property var theme
    required property int barHeight
    required property var visibleWorkspaceIds
    required property var occupiedWorkspaceIds
    property var activePlayer: null
    property bool hasMediaSource: false
    property var cavaValues: [0, 0, 0, 0, 0, 0]
    property bool menuOpen: false
    property bool centerPopupOpen: false
    property bool audioPopupOpen: false
    property int audioVolumePercent: 0
    property bool vpnActive: false
    property string vpnName: ""
    property string networkType: "offline"
    property bool networkPopupOpen: false
    property bool bluetoothAvailable: false
    property bool bluetoothEnabled: false
    property bool bluetoothConnected: false
    property bool bluetoothPopupOpen: false
    property bool notificationsDnd: false
    property bool notificationsHasToast: false
    property int notificationsUnreadCount: 0
    property bool notificationsMenuOpened: false
    property bool powerMenuOpened: false
    property bool trayMenuOpen: false

    signal menuToggleRequested()
    signal centerToggleRequested()
    signal audioToggleRequested()
    signal networkToggleRequested()
    signal bluetoothToggleRequested()
    signal notificationsToggleRequested()
    signal powerToggleRequested()
    signal launchCommand(var command)
    signal audioVolumeStepRequested(bool increase)
    signal trayMenuRequested(var model, real globalX)

    screen: targetScreen
    anchors { top: true; left: true; right: true }
    implicitHeight: barHeight
    color: theme.background
    WlrLayershell.exclusiveZone: barHeight

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: root.theme.accent
            opacity: 0.55
        }

        WorkspaceGroup {
            anchors.left: parent.left
            theme: root.theme
            visibleWorkspaceIds: root.visibleWorkspaceIds
            occupiedWorkspaceIds: root.occupiedWorkspaceIds
            menuOpen: root.menuOpen
            onMenuClicked: root.menuToggleRequested()
        }

        CenterClock {
            anchors.centerIn: parent
            theme: root.theme
            activePlayer: root.activePlayer
            hasMediaSource: root.hasMediaSource
            cavaValues: root.cavaValues
            popupOpen: root.centerPopupOpen
            onClicked: root.centerToggleRequested()
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 10
            height: parent.height
            spacing: 12

            TrayGroup {
                theme: root.theme
                contextMenuOpen: root.trayMenuOpen
                onContextMenuRequested: (model, globalX) => root.trayMenuRequested(model, globalX)
            }

            WifiStatusItem {
                theme: root.theme
                connectionType: root.networkType
                popupOpen: root.networkPopupOpen
                onClicked: root.networkToggleRequested()
            }

            BluetoothStatusItem {
                theme: root.theme
                available: root.bluetoothAvailable
                enabled: root.bluetoothEnabled
                connected: root.bluetoothConnected
                popupOpen: root.bluetoothPopupOpen
                onClicked: root.bluetoothToggleRequested()
            }

            VpnStatusItem {
                theme: root.theme
                barHeight: root.barHeight
                active: root.vpnActive
                vpnName: root.vpnName
                onClicked: root.launchCommand(["sh", "-c", "command -v protonvpn-app >/dev/null 2>&1 && protonvpn-app || nm-connection-editor"])
            }

            AudioStatusItem {
                theme: root.theme
                barHeight: root.barHeight
                popupOpen: root.audioPopupOpen
                volumePercent: root.audioVolumePercent
                onClicked: root.audioToggleRequested()
                onVolumeStepRequested: increase => root.audioVolumeStepRequested(increase)
            }

            NotificationStatusItem {
                theme: root.theme
                dnd: root.notificationsDnd
                hasToast: root.notificationsHasToast
                unreadCount: root.notificationsUnreadCount
                menuOpened: root.notificationsMenuOpened
                onClicked: root.notificationsToggleRequested()
            }

            BtopStatusItem {
                theme: root.theme
                onClicked: root.launchCommand(["sh", "-c", "exec \"$HOME/.config/quickshell/omi_shell/scripts/floating-terminal\" btop"])
            }

            PowerStatusItem {
                theme: root.theme
                menuOpened: root.powerMenuOpened
                onClicked: root.powerToggleRequested()
            }
        }
    }
}

import QtQuick
import Quickshell

QtObject {
    readonly property string shellPath: "~/.config/quickshell/omi_shell/shell.qml"
    readonly property string scriptsPath: "~/.config/quickshell/omi_shell/scripts"
    readonly property var lockscreenMonitorItems: Quickshell.screens.length > 1 ? [
        { name: "Lockscreen Input Monitor", icon: "󰍹", dynamic: {
            cmd: scriptsPath + "/lockscreen-monitor list",
            icon: "󰍹",
            prefix: scriptsPath + "/lockscreen-monitor set"
        }}
    ] : []

    readonly property var items: [
        { name: "Apps", icon: "󰀻", command: "quickshell ipc --path " + shellPath + " call launcher toggle" },
        { name: "Clipboard", icon: "", command: "quickshell ipc --path " + shellPath + " call clipboard toggle" },
        { name: "Audio", icon: "", command: "quickshell ipc --path " + shellPath + " call audio toggle" },
        { name: "Notifications", icon: "󰂞", command: "quickshell ipc --path " + shellPath + " call notifications toggle" },
        { name: "Style", icon: "", sub: [
            { name: "Keshiki Studio", icon: "󰸌", command: "quickshell ipc --path " + shellPath + " call style wallpaper" },
            { name: "Open on Palette", icon: "", command: "quickshell ipc --path " + shellPath + " call style theme" },
            { name: "Current Theme", icon: "󰸌", command: scriptsPath + "/floating-terminal " + scriptsPath + "/theme-current" },
            { name: "Refresh Shell", icon: "", command: scriptsPath + "/theme-refresh" }
        ]},
        { name: "Setup", icon: "", sub: [
            { name: "Network", icon: "", command: "quickshell ipc --path " + shellPath + " call network toggle" },
            { name: "Bluetooth", icon: "󰂯", command: scriptsPath + "/launch-bluetooth" },
            { name: "Weather Location", icon: "󰖕", command: scriptsPath + "/floating-terminal " + scriptsPath + "/weather-location" },
            { name: "Power Profile", icon: "󱐋", dynamic: { cmd: "powerprofilesctl list | grep -o '^  [a-z-]*' | sed 's/^  //'", icon: "󱐋", prefix: "powerprofilesctl set" } },
            { name: "Hyprland Config", icon: "", command: "xdg-open ~/.config/hypr" },
            { name: "Network Editor", icon: "󰤨", command: "nm-connection-editor" }
        ]},
        { name: "Install", icon: "󰉉", sub: [
            { name: "Pacman Package", icon: "󰣇", command: scriptsPath + "/floating-terminal " + scriptsPath + "/pkg-install" },
            { name: "AUR", icon: "󰣇", command: scriptsPath + "/floating-terminal " + scriptsPath + "/aur-install" },
            { name: "Web App", icon: "", command: scriptsPath + "/floating-terminal " + scriptsPath + "/webapp-install" },
            { name: "TUI", icon: "", command: scriptsPath + "/floating-terminal " + scriptsPath + "/tui-install" }
        ]},
        { name: "Remove", icon: "󰭌", sub: [
            { name: "Package", icon: "󰣇", command: scriptsPath + "/floating-terminal " + scriptsPath + "/pkg-remove" },
            { name: "Web App", icon: "", command: scriptsPath + "/floating-terminal " + scriptsPath + "/webapp-remove" },
            { name: "TUI", icon: "", command: scriptsPath + "/floating-terminal " + scriptsPath + "/tui-remove" }
        ]},
        { name: "System", icon: "", sub: lockscreenMonitorItems.concat([
            { name: "Lock", icon: "", command: "uwsm-app -- quickshell --path ~/.config/quickshell/omi_shell/LockShell.qml" },
            { name: "Power Menu", icon: "󰐥", command: "quickshell ipc --path " + shellPath + " call power toggle" },
            { name: "About", icon: "", command: "quickshell ipc --path " + shellPath + " call about toggle" }
        ])}
    ]
}

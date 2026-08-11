import QtQuick
import Quickshell.Services.UPower

QtObject {
    readonly property var device: UPower.displayDevice
    readonly property bool available: device.ready && device.isLaptopBattery && device.isPresent
    readonly property int percentage: available ? Math.max(0, Math.min(100, Math.round(device.percentage * 100))) : 0
    readonly property bool charging: available && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge || device.state === UPowerDeviceState.FullyCharged)
}

import QtQuick

// Retegzett, puha fenyfolt – olcsobb mint egy blur effekt, es nem kell shader.
Item {
    id: glow

    property color glowColor: "#ffffff"
    property real intensity: 0.08
    property int layers: 9

    Repeater {
        model: glow.layers

        Rectangle {
            required property int index

            readonly property real factor: Math.pow((index + 1) / glow.layers, 0.72)

            width: glow.width * factor
            height: glow.height * factor
            radius: width / 2
            anchors.centerIn: parent
            color: glow.glowColor
            opacity: glow.intensity / glow.layers
        }
    }
}

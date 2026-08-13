import QtQuick

// Vellum Shell mark: a torii gate drawn from flat rectangles so it stays crisp at
// bar size and takes the theme colour like the glyph it replaces. Geometry is
// laid out on a 16x16 grid and scaled by `size`.
Item {
    id: logo

    property color color: "#e8ddc7"
    property real size: 16

    readonly property real u: size / 16

    implicitWidth: size
    implicitHeight: size
    width: implicitWidth
    height: implicitHeight

    // Upswept ends of the kasagi (top lintel)
    Rectangle {
        x: 0
        y: logo.u
        width: 2.4 * logo.u
        height: logo.u
        color: logo.color
    }

    Rectangle {
        x: logo.size - 2.4 * logo.u
        y: logo.u
        width: 2.4 * logo.u
        height: logo.u
        color: logo.color
    }

    // Kasagi
    Rectangle {
        x: 0
        y: 2 * logo.u
        width: logo.size
        height: 2 * logo.u
        color: logo.color
    }

    // Nuki (second beam), protruding past the pillars
    Rectangle {
        x: 2 * logo.u
        y: 6 * logo.u
        width: 12 * logo.u
        height: 1.6 * logo.u
        color: logo.color
    }

    // Gakuzuka (short centre post between the beams)
    Rectangle {
        x: 7.4 * logo.u
        y: 4 * logo.u
        width: 1.2 * logo.u
        height: 2 * logo.u
        color: logo.color
    }

    // Hashira (pillars)
    Rectangle {
        x: 3 * logo.u
        y: 4 * logo.u
        width: 2 * logo.u
        height: 11 * logo.u
        color: logo.color
    }

    Rectangle {
        x: 11 * logo.u
        y: 4 * logo.u
        width: 2 * logo.u
        height: 11 * logo.u
        color: logo.color
    }
}

import QtQuick

Rectangle {
    id: field

    property alias text: input.text
    property bool opened: false
    property string indicator: "⌕"
    property string placeholder: "Search..."
    property color foreground: "#f1e7d0"
    property color accent: "#d7472f"
    property color muted: "#9f8f7c"
    property color surface: "#1b1613"
    property int inputLeftMargin: 40
    property int inputVerticalPadding: 12
    signal textEdited(string text)
    signal keyPressed(var event)

    function forceInputFocus() {
        input.forceActiveFocus()
    }

    function forceActiveFocus() {
        input.forceActiveFocus()
    }

    height: 46
    radius: 0
    color: surface
    border.color: input.activeFocus ? accent : muted
    border.width: input.activeFocus ? 2 : 1
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Text {
        text: field.indicator
        color: field.accent
        font.pixelSize: 18
        anchors.left: parent.left
        anchors.leftMargin: 13
        anchors.verticalCenter: parent.verticalCenter
    }

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.leftMargin: field.inputLeftMargin
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - field.inputVerticalPadding
        verticalAlignment: TextInput.AlignVCenter
        color: field.foreground
        font.pixelSize: 15
        focus: field.opened
        onTextChanged: field.textEdited(text)
        Keys.onPressed: (event) => field.keyPressed(event)

        Text {
            text: field.placeholder
            color: field.muted
            visible: parent.text === ""
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
        }
    }
}

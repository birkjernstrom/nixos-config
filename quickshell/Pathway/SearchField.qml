import QtQuick
import qs.Common
import qs.Widgets

// A FocusScope, not a plain Item: focus set on this element has to reach the
// TextInput inside it. A plain Item would swallow it - keys would go nowhere and
// only clicking the input directly would let you type.
FocusScope {
    id: root

    property alias text: input.text
    property string placeholder: "Search apps and commands..."

    implicitHeight: 56

    // Named takeFocus rather than overriding the built-in forceActiveFocus,
    // which QML itself calls internally.
    function takeFocus() {
        input.forceActiveFocus();
    }

    StyledText {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        icon: true
        text: Icons.search
        color: Theme.fgDim
    }

    TextInput {
        id: input

        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.fg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSize + 4
        selectionColor: Theme.accent
        selectedTextColor: Theme.onAccent
        clip: true
        // Arrow keys are handled by the list, not by cursor movement.
        focus: true

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.fgDim
            font.pointSize: Theme.fontSize + 4
            visible: input.text === ""
        }
    }
}

import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property alias text: input.text
    property string placeholder: "Search apps and commands..."

    implicitHeight: 56

    function forceActiveFocus() {
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

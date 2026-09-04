import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Common
import qs.Widgets

// One ResultItem. Purely presentational - selection and activation are the
// list's job.
Rectangle {
    id: root

    required property var item
    required property bool selected

    implicitHeight: Theme.pathwayRowHeight
    radius: Theme.radius
    color: root.selected ? Theme.bgHover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    IconImage {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 24
        // `true` asks for a fallback rather than an error when the theme has no
        // matching icon.
        source: root.item.icon ? Quickshell.iconPath(root.item.icon, true) : ""
        visible: source !== ""
    }

    StyledText {
        id: fallbackIcon

        anchors.centerIn: icon
        icon: true
        text: Icons.app
        color: Theme.fgDim
        visible: !icon.visible
    }

    StyledText {
        id: name

        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.item.name ?? ""
        color: root.selected ? Theme.fg : Theme.fg
        font.pointSize: Theme.fontSize + 1
    }

    StyledText {
        anchors.left: name.right
        anchors.leftMargin: 10
        anchors.right: chevron.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.item.subtitle ?? ""
        color: Theme.fgDim
        elide: Text.ElideRight
    }

    StyledText {
        id: chevron

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        icon: true
        text: Icons.chevronRight
        color: Theme.fgDim
        visible: root.item.kind === "module"
    }
}

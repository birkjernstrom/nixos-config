import QtQuick
import QtQuick.Layouts
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
        // matching icon - but that fallback can still resolve to nothing, so
        // render only on a confirmed load and let the glyph below cover the rest.
        source: root.item.icon ? Quickshell.iconPath(root.item.icon, true) : ""
        visible: source !== "" && icon.status === Image.Ready
    }

    StyledText {
        id: fallbackIcon

        anchors.centerIn: icon
        icon: true
        text: {
            if (root.item.kind === "clip")
                return Icons.clipboard;
            if (root.item.kind === "clip-binary")
                return Icons.image;
            return Icons.app;
        }
        color: Theme.fgDim
        visible: !icon.visible
    }

    // Bounded on both sides so a long name (a clipboard preview is the whole
    // entry) elides rather than running under the chevron.
    RowLayout {
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: chevron.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        StyledText {
            // Caps at its natural width so the subtitle gets the slack, but is
            // still allowed to shrink and elide when the name alone overflows.
            Layout.fillWidth: true
            Layout.maximumWidth: implicitWidth
            Layout.minimumWidth: 0

            text: root.item.name ?? ""
            color: Theme.fg
            font.pointSize: Theme.fontSize + 1
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            Layout.minimumWidth: 0

            text: root.item.subtitle ?? ""
            color: Theme.fgDim
            elide: Text.ElideRight
            visible: text !== ""
        }
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

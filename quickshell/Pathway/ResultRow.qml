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
            if (root.item.kind === "theme" || root.item.id === "command:theme")
                return Icons.theme;
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
        anchors.right: swatch.visible ? swatch.left : chevron.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        StyledText {
            // Takes its natural width and no more, so the subtitle gets all the
            // slack. fillWidth here would make the two share the row and elide
            // the name even when there is room for it. minimumWidth 0 still lets
            // it shrink when the name alone overflows, as clipboard entries do.
            Layout.fillWidth: false
            Layout.preferredWidth: implicitWidth
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

    // Colour preview for theme rows. Nothing else sets `swatch`, so this costs
    // other rows one invisible Row.
    Row {
        id: swatch

        anchors.right: chevron.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        visible: root.item.swatch !== undefined

        Repeater {
            model: root.item.swatch ?? []

            Rectangle {
                required property color modelData

                width: 14
                height: 14
                radius: 3
                color: modelData
                border.color: Theme.border
                border.width: 1
            }
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

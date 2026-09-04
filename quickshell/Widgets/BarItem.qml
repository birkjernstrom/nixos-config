import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common

// The waybar module CSS, as QML: padding 0 10px, margin 4px 2px, hover
// background, optional click handling and an optional hover tooltip.
//
// Bar modules wrap themselves in this rather than each re-deriving the metrics.
Rectangle {
    id: root

    default property alias content: inner.data

    property int hPadding: Theme.paddingH
    property bool interactive: false
    property string tooltip: ""

    readonly property bool hovered: mouse.containsMouse

    signal clicked
    signal rightClicked
    signal wheel(int delta)

    implicitWidth: inner.implicitWidth + root.hPadding * 2
    implicitHeight: inner.implicitHeight

    Layout.topMargin: Theme.marginV
    Layout.bottomMargin: Theme.marginV
    Layout.leftMargin: Theme.marginH
    Layout.rightMargin: Theme.marginH

    radius: Theme.radius
    color: root.interactive && root.hovered ? Theme.bgHover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    Item {
        id: inner

        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: event => event.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: event => root.wheel(event.angleDelta.y)
    }

    // Anchoring to `item` also resolves the containing window, so the popup does
    // not need a reference to the PanelWindow it lives in.
    PopupWindow {
        anchor.item: root
        anchor.rect.y: root.height + 4
        anchor.gravity: Edges.Bottom
        visible: root.tooltip !== "" && root.hovered
        implicitWidth: tooltipText.implicitWidth + 20
        implicitHeight: tooltipText.implicitHeight + 12
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Theme.bg
            border.color: Theme.accent
            border.width: 1
            radius: Theme.radius

            StyledText {
                id: tooltipText

                anchors.centerIn: parent
                text: root.tooltip
                color: Theme.fg
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}

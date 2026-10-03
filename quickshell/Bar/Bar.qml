import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Bar.modules
import qs.Common

// Geometry and slots only - every module below is self-contained and this file
// is the single place where the bar's contents are declared.
//
// Deliberately minimal: workspaces on the left, the clock in the middle,
// status on the right. Anything else belongs in Pathway, not here.
Scope {
    id: root

    property bool solid: false

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData

            screen: modelData
            color: root.solid ? Theme.bg : "transparent"
            implicitHeight: Theme.barHeight

            anchors {
                top: true
                left: true
                right: true
            }

            // Reserve the space so windows tile below the bar instead of under it.
            exclusiveZone: Theme.barHeight

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-bar"

            MouseArea {
                anchors.fill: parent
                onDoubleClicked: root.solid = !root.solid
            }

            RowLayout {
                id: leftSlot

                anchors.left: parent.left
                anchors.leftMargin: Theme.edgeMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Workspaces {}
            }

            // Centre: the clock. Anchored to the window rather than packed
            // between the other two slots, so it stays on the screen's
            // midline regardless of how wide either side's content is.
            RowLayout {
                id: centreSlot

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Clock {}
            }

            RowLayout {
                id: rightSlot

                anchors.right: parent.right
                anchors.rightMargin: Theme.edgeMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                // Order matches the waybar it replaces: audio, bluetooth,
                // network, battery, hard against the edge. Agents lead, since
                // they are the one item that asks something of you.
                AgentStatus {}

                Volume {}

                Bluetooth {}

                Wifi {}

                Tailnet {}

                Battery {}
            }
        }
    }
}

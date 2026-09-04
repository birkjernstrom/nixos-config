import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Bar.modules
import qs.Common

// Geometry and slots only - every module below is self-contained and this file
// is the single place where the bar's contents are declared.
//
// Deliberately minimal: workspaces, clock, battery, wifi. Anything else belongs
// in Pathway, not here.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData

            screen: modelData
            color: Theme.bg
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

            RowLayout {
                id: leftSlot

                anchors.left: parent.left
                anchors.leftMargin: Theme.edgeMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Workspaces {}
            }

            // Anchored to the true window centre; a spacer-based RowLayout would
            // drift as the side slots change width.
            RowLayout {
                id: centerSlot

                anchors.centerIn: parent
                spacing: 0

                Clock {}
            }

            RowLayout {
                id: rightSlot

                anchors.right: parent.right
                anchors.rightMargin: Theme.edgeMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                // Order matches the waybar it replaces: network, then battery.
                Wifi {}

                Battery {}
            }
        }
    }
}

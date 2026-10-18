import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

// logind ignores the power key; Hyprland routes it here instead.
Scope {
    id: root

    property bool open: false
    property bool confirmFocused: false
    property int remaining: 0

    readonly property int timeout: 30

    function show(): void {
        root.confirmFocused = false;
        root.remaining = root.timeout;
        root.open = true;
    }

    function cancel(): void {
        root.open = false;
    }

    function confirm(): void {
        root.open = false;
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    Timer {
        running: root.open
        interval: 1000
        repeat: true
        onTriggered: {
            root.remaining -= 1;
            if (root.remaining <= 0)
                root.cancel();
        }
    }

    PanelWindow {
        id: win

        visible: root.open
        color: "transparent"
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => keys.forceActiveFocus());
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "power"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim

            MouseArea {
                anchors.fill: parent
                onClicked: root.cancel()
            }
        }

        Item {
            id: keys

            focus: true

            Keys.onEscapePressed: root.cancel()
            Keys.onTabPressed: root.confirmFocused = !root.confirmFocused
            Keys.onBacktabPressed: root.confirmFocused = !root.confirmFocused
            Keys.onLeftPressed: root.confirmFocused = false
            Keys.onRightPressed: root.confirmFocused = true
            Keys.onReturnPressed: root.confirmFocused ? root.confirm() : root.cancel()
            Keys.onEnterPressed: root.confirmFocused ? root.confirm() : root.cancel()
        }

        Rectangle {
            id: card

            anchors.centerIn: parent
            width: Theme.pathwayWidth
            height: content.implicitHeight + 2 * 24
            color: Theme.bgAlt
            radius: Theme.radiusLarge
            border.color: Theme.critical
            border.width: 1

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: content

                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    StyledText {
                        icon: true
                        text: Icons.power
                        color: Theme.critical
                        font.pointSize: Theme.fontSize + 8
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Shut down?"
                        color: Theme.fg
                        font.pointSize: Theme.fontSize + 4
                        font.weight: Font.DemiBold
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: `The power button was pressed. Cancelling automatically in ${root.remaining}s.`
                    color: Theme.fgSubtle
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item {
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: [
                            { label: "Cancel", danger: false },
                            { label: "Shut down", danger: true }
                        ]

                        delegate: Rectangle {
                            id: button

                            required property var modelData

                            readonly property bool focused: modelData.danger === root.confirmFocused
                            readonly property color tint: modelData.danger ? Theme.critical : Theme.accent

                            implicitWidth: label.implicitWidth + 2 * 20
                            implicitHeight: 40
                            radius: Theme.radius
                            color: focused ? tint : (mouse.containsMouse ? Theme.bgHover : Theme.bg)
                            border.color: focused ? tint : Theme.border
                            border.width: 1

                            StyledText {
                                id: label

                                anchors.centerIn: parent
                                text: button.modelData.label
                                color: button.focused ? Theme.onAccent : Theme.fg
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: mouse

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: button.modelData.danger ? root.confirm() : root.cancel()
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Tab to switch · Enter to choose · Esc to cancel"
                    color: Theme.fgDim
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}

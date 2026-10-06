import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import qs.Common
import qs.Widgets

// The session's polkit agent: pkexec, 1Password's system unlock, udisks and
// friends all prompt here. Only one agent can register per session, so this
// stays unregistered while another one (hyprpolkitagent) is running.
Scope {
    id: root

    readonly property AuthFlow flow: agent.flow
    readonly property bool open: agent.isActive && root.flow !== null

    PolkitAgent {
        id: agent
    }

    PanelWindow {
        id: win

        visible: root.open
        color: "transparent"
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => input.forceActiveFocus());
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "polkit"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim
        }

        Rectangle {
            id: card

            anchors.centerIn: parent
            width: Theme.pathwayWidth
            height: content.implicitHeight + 2 * 24
            color: Theme.bgAlt
            radius: Theme.radiusLarge
            border.color: Theme.accent
            border.width: 1

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
                        text: Icons.lock
                        color: Theme.accent
                        font.pointSize: Theme.fontSize + 8
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Authentication required"
                        color: Theme.fg
                        font.pointSize: Theme.fontSize + 4
                        font.weight: Font.DemiBold
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.flow?.message ?? ""
                    color: Theme.fgSubtle
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: Theme.radius
                    color: Theme.bg
                    border.color: input.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: input

                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter

                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSize + 2
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.onAccent
                        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        enabled: root.flow?.isResponseRequired ?? false
                        clip: true
                        focus: true

                        Keys.onReturnPressed: root.submit()
                        Keys.onEnterPressed: root.submit()
                        Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                const who = root.flow?.selectedIdentity?.displayName;
                                const prompt = (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "");
                                return who ? `${prompt || "Password"} for ${who}` : prompt || "Password";
                            }
                            color: Theme.fgDim
                            font.pointSize: Theme.fontSize + 2
                            visible: input.text === ""
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.flow?.supplementaryMessage ?? ""
                    color: root.flow?.supplementaryIsError ? Theme.critical : Theme.fgSubtle
                    wrapMode: Text.Wrap
                    visible: text !== ""
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Enter to authenticate · Esc to cancel"
                    color: Theme.fgDim
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    function submit(): void {
        if (!root.flow?.isResponseRequired)
            return;
        root.flow.submit(input.text);
        input.text = "";
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        function onAuthenticationFailed() {
            input.text = "";
            input.forceActiveFocus();
        }
    }
}

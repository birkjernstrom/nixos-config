import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Common
import qs.Pathway.providers

// The command menu. Owns window lifecycle, focus and keyboard routing; the
// search/rank logic lives in Search.qml and the rows in ResultList.qml.
Scope {
    id: root

    property bool open: false

    // Owned by the Nav singleton so providers can push a view without holding
    // a reference to this window.
    readonly property Component moduleView: Nav.moduleView

    function show() {
        root.open = true;
    }

    function hide() {
        root.open = false;
    }

    function toggle() {
        root.open = !root.open;
    }

    // Opens straight into one provider's list, e.g. SUPER+V for the clipboard.
    // Order matters: the scope is set before showing, and closing is what clears
    // it, so opening scoped does not immediately reset itself.
    function showScoped(provider, title) {
        Nav.pushScope(provider, title);
        search.text = "";
        list.selectedIndex = 0;
        root.open = true;
        search.takeFocus();
    }

    onOpenChanged: {
        // Every open starts from a clean slate rather than resuming the last query.
        if (root.open) {
            search.text = "";
            list.selectedIndex = 0;
            search.takeFocus();
        } else {
            Nav.popModule();
            Nav.popScope();
        }
    }

    PanelWindow {
        id: win

        visible: root.open
        color: "transparent"

        // The focus calls on open run before the layer surface is mapped, so
        // they cannot land. Re-assert once the window actually exists.
        onVisibleChanged: {
            if (visible)
                Qt.callLater(search.takeFocus);
        }

        // Full-screen scrim so clicking anywhere outside the card dismisses.
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Ignore, not a zero zone: setting exclusiveZone explicitly forces
        // exclusionMode back to Normal, which would inset the scrim below the
        // bar instead of covering the whole output.
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "pathway"
        // OnDemand rather than Exclusive: Hyprland keeps its own keybinds, so
        // SUPER+space still reaches the compositor while Pathway has focus.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // Acquires focus and gives click-outside dismissal. The scrim MouseArea
        // below is the fallback if the grab is refused.
        HyprlandFocusGrab {
            active: root.open
            windows: [win]
            onCleared: root.hide()
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }
        }

        Rectangle {
            id: card

            anchors.centerIn: parent
            width: Theme.pathwayWidth
            height: Theme.pathwayHeight
            color: Theme.bgAlt
            radius: Theme.radiusLarge
            border.color: Theme.accent
            border.width: 1

            // Swallow clicks on the card so they don't reach the dismiss scrim.
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 0

                SearchField {
                    id: search

                    Layout.fillWidth: true
                    focus: root.open
                    placeholder: Nav.scope ? `Search ${Nav.scopeTitle.toLowerCase()}...` : "Search apps and commands..."


                    // Arrow keys and Enter belong to the list even while the
                    // text field holds focus.
                    // Escape unwinds one level at a time before closing.
                    Keys.onEscapePressed: {
                        if (root.moduleView)
                            Nav.popModule();
                        else if (Nav.scope)
                            Nav.popScope();
                        else
                            root.hide();
                    }
                    Keys.onUpPressed: list.moveSelection(-1)
                    Keys.onDownPressed: list.moveSelection(1)
                    Keys.onReturnPressed: list.activateSelected()
                    Keys.onEnterPressed: list.activateSelected()
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.border
                }

                ModuleHost {
                    id: host

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    source: root.moduleView

                    ResultList {
                        id: list

                        anchors.fill: parent
                        query: search.text
                        onActivated: root.hide()
                    }
                }
            }
        }
    }

    Connections {
        function onCloseRequested() {
            root.hide();
        }

        // Entering or leaving a scope starts a fresh query. Without this the
        // text that found the command stays in the field and filters the list it
        // just opened - searching "theme" would open the theme scope and then
        // immediately filter every theme out of it.
        function onScopeChanged() {
            search.text = "";
            list.selectedIndex = 0;
        }

        target: Nav
    }
}

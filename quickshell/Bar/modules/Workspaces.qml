import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

// Left slot: one pill per workspace, ported from waybar's hyprland/workspaces
// with persistent-workspaces { "*" = 5; }.
RowLayout {
    id: root

    // Bar.qml runs one instance per screen, so the pills have to know which
    // monitor they belong to. monitorFor() would give the HyprlandMonitor
    // directly but is a plain method call - it would not re-run if Hyprland's
    // monitor list is still filling in when the bar is built. The screen name
    // is a stable string available the moment the window resolves, and every
    // comparison against it lives in a per-pill binding that Hyprland's own
    // property notifications keep current.
    readonly property string screenName: QsWindow.window?.screen?.name ?? ""

    // 1-5 are waybar's persistent workspaces; anything above that appears only
    // while it exists. Ids from every monitor are listed here so that each pill
    // can decide its own visibility - see below.
    readonly property var workspaceIds: {
        const ids = [1, 2, 3, 4, 5];
        for (const ws of Hyprland.workspaces.values) {
            if (ws && ws.id > 5)
                ids.push(ws.id);
        }
        return ids.sort((a, b) => a - b);
    }

    spacing: 0

    Repeater {
        model: root.workspaceIds

        BarItem {
            id: pill

            required property int modelData

            // Walked inside the binding rather than cached, so adding or
            // removing a workspace re-resolves this on its own.
            readonly property var workspace: {
                for (const ws of Hyprland.workspaces.values) {
                    if (ws && ws.id === pill.modelData)
                        return ws;
                }
                return null;
            }

            // Reading monitor.name here (instead of pre-filtering the id list)
            // is what subscribes each pill to its own workspace's monitor, so a
            // workspace moved between outputs hops bars without a refresh.
            visible: pill.modelData <= 5 || pill.workspace?.monitor?.name === root.screenName

            // waybar: #workspaces button { padding: 0 8px }
            hPadding: 8
            interactive: true

            // `active` rather than `focused`: waybar highlights the workspace
            // shown on each output, not just the one holding keyboard focus.
            color: {
                if (pill.workspace?.urgent)
                    return Theme.critical;
                if (pill.workspace?.active)
                    return Theme.accent;
                if (pill.hovered)
                    return Theme.bgHover;
                return "transparent";
            }

            StyledText {
                // waybar's format-icons mapped 10 to "0".
                text: pill.modelData === 10 ? "0" : String(pill.modelData)
                color: {
                    if (pill.workspace?.urgent || pill.workspace?.active)
                        return Theme.onAccent;
                    return pill.hovered ? Theme.fg : Theme.fgDim;
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                    }
                }
            }

            // Lua dispatcher syntax, not the classic "workspace N" string: this
            // config sets hyprland.configType = "lua", and Hyprland then wraps
            // whatever it receives in hl.dispatch(...), where the plain form is a
            // syntax error. Matches the SUPER+N binds in hyprland/bindings.nix.
            //
            // dispatch rather than workspace.activate(): a persistent pill for an
            // id Hyprland has not created yet has no object to activate.
            onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${pill.modelData} })`)
        }
    }
}

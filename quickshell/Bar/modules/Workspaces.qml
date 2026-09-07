import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

// Left slot: one pill per workspace, ported from waybar's hyprland/workspaces.
// Both bars list every workspace; the pills styled below say which screen each
// one actually lives on.
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

    // Matches hyprland/lib.nix workspaceCount. hyprland/workspaces.nix makes
    // all eight persistent, so every pill has a real workspace behind it and
    // can be attributed to a monitor even while empty. Ids above the range only
    // show up on the bar that owns them.
    readonly property int workspaceCount: 8

    readonly property var workspaceIds: {
        const ids = [];
        for (let i = 1; i <= root.workspaceCount; i++)
            ids.push(i);
        for (const ws of Hyprland.workspaces.values) {
            if (ws && ws.id > root.workspaceCount)
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
            //
            // Undecided (Hyprland has not created the workspace yet) counts as
            // local: the alternative is every pill flashing faded on startup.
            // Undocked, every workspace is on the one monitor and nothing fades.
            readonly property bool elsewhere: pill.workspace?.monitor
                ? pill.workspace.monitor.name !== root.screenName
                : false

            // Hyprland hands a newly attached output a scratch workspace of
            // its own before it announces the monitor, and keeps it around as
            // that screen's last workspace even once reflow has moved the real
            // ones in. Empty and out of range means nobody needs to see it.
            visible: pill.modelData <= root.workspaceCount
                || (!pill.elsewhere && (pill.workspace?.windows ?? 0) > 0)

            // waybar: #workspaces button { padding: 0 8px }
            hPadding: 8
            interactive: true

            // Solid pill = this workspace is on this screen. Outlined = it is
            // the active one on the other screen, so SUPER+N will move focus
            // there rather than switching what is in front of you. Faded plain
            // number = idle, over there.
            opacity: pill.elsewhere ? 0.45 : 1.0

            border.width: pill.elsewhere && pill.workspace?.active ? 1 : 0
            border.color: pill.workspace?.urgent ? Theme.critical : Theme.accent

            // `active` rather than `focused`: waybar highlights the workspace
            // shown on each output, not just the one holding keyboard focus.
            color: {
                if (pill.elsewhere)
                    return pill.hovered ? Theme.bgHover : "transparent";
                if (pill.workspace?.urgent)
                    return Theme.critical;
                if (pill.workspace?.active)
                    return Theme.accent;
                if (pill.hovered)
                    return Theme.bgHover;
                return "transparent";
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }

            StyledText {
                text: String(pill.modelData)
                color: {
                    if (pill.elsewhere)
                        return pill.workspace?.urgent ? Theme.critical : pill.workspace?.active ? Theme.accent : Theme.fgDim;
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

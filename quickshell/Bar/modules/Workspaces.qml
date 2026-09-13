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

    // A tiled window sits inside the gap and its own border, so a column flush
    // against the edge of the screen starts a few px in. Anything past this
    // much slack is genuinely hanging off the side.
    readonly property int edgeSlack: 4

    spacing: 0

    // Window geometry reaches the bar only in HyprlandToplevel.lastIpcObject,
    // which is a snapshot of `hyprctl clients` rather than a live binding, and
    // Quickshell only re-reads it on configreloaded. Everything below is about
    // asking for a fresh one at the right moments.
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            switch (event.name) {
            case "openwindow":
            case "closewindow":
            case "movewindow":
            case "movewindowv2":
            case "activewindow":
            case "activewindowv2":
            case "changefloatingmode":
            case "fullscreen":
            case "workspace":
            case "workspacev2":
            case "focusedmon":
                resync.restart();
                break;
            }
        }
    }

    // One action fires several of those events; this collapses the burst into
    // a single query a frame or two later, once the layout has settled.
    Timer {
        id: resync

        interval: 50
        onTriggered: Hyprland.refreshToplevels()
    }

    // Hyprland emits nothing at all when the tape itself moves - SUPER+R
    // resizing a column, SUPER+C recentring, a scroll that does not change
    // which window is focused all change geometry silently. Those are the only
    // thing this backstop exists for, so it runs slowly: a second of staleness
    // on a hint this subtle is not worth polling harder for.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
    }

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

            // Whether this workspace's tape runs past the edge of its screen,
            // and by how many windows. The scrolling layout lays every
            // workspace out as though it were the one on display, so this
            // reads the same whether or not you are looking at it.
            //
            // Floating windows are skipped: one parked half off screen is not
            // something scrolling would bring back, so it is not news.
            readonly property var offscreen: {
                const mon = pill.workspace?.monitor;
                const tops = pill.workspace?.toplevels;
                const none = { left: 0, right: 0 };
                if (!mon || !tops || !mon.scale)
                    return none;

                // Monitors report their size in physical pixels and their
                // position, like window geometry, in logical ones.
                const viewLeft = mon.x;
                const viewRight = mon.x + mon.width / mon.scale;
                let out = { left: 0, right: 0 };

                for (const top of tops.values) {
                    const w = top?.lastIpcObject;
                    if (!w || w.floating || !w.mapped || !w.at || !w.size)
                        continue;
                    if (w.at[0] < viewLeft - root.edgeSlack)
                        out.left++;
                    if (w.at[0] + w.size[0] > viewRight + root.edgeSlack)
                        out.right++;
                }
                return out;
            }

            tooltip: {
                const off = pill.offscreen;
                if (off.left === 0 && off.right === 0)
                    return "";
                const parts = [];
                if (off.left > 0)
                    parts.push(`${off.left} left`);
                if (off.right > 0)
                    parts.push(`${off.right} right`);
                return `Off screen: ${parts.join(", ")}`;
            }

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
                id: label

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

            // A tick hard against the side the tape continues on: content is
            // over there, scroll for it. No ticks means the screen is showing
            // the whole workspace. They live in the overlay slot so they sit
            // in the pill's padding without widening it or nudging the number
            // off centre as they come and go.
            overlay: [
                Repeater {
                    // A constant model, with only the opacity bound: a model
                    // rebuilt from the counts would replace both delegates on
                    // every change and the fade below would never run.
                    model: ["left", "right"]

                    Rectangle {
                        required property string modelData

                        readonly property bool showing: modelData === "left"
                            ? pill.offscreen.left > 0
                            : pill.offscreen.right > 0

                        anchors.left: modelData === "left" ? parent.left : undefined
                        anchors.right: modelData === "right" ? parent.right : undefined
                        anchors.leftMargin: 3
                        anchors.rightMargin: 3
                        anchors.verticalCenter: parent.verticalCenter

                        width: 2
                        height: Math.round(parent.height * 0.5)
                        radius: 1
                        color: label.color
                        opacity: showing ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animFast
                            }
                        }
                    }
                }
            ]

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

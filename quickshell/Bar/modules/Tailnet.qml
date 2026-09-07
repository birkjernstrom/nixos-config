import QtQuick
import qs.Common
import qs.Widgets

// Right slot: whether this machine is on the work tailnet, as a single glyph.
//
// Three states share one silhouette, the way the bluetooth module's do: off,
// on, and on-through-an-exit-node. The exit node earns its own frame rather
// than a tooltip line because it is the one Tailscale state that changes what
// every other application on the machine sees, and noticing it by accident an
// hour later is the failure this is meant to prevent.
//
// Clicking toggles rather than opening a pane, which is where this parts
// company with the wifi and bluetooth modules. Those open a TUI because picking
// a network or a device is a choice among many; Tailscale has no TUI, and the
// only routine question - on or off - is answerable by the click itself.
BarItem {
    id: root

    // tailscaled not running at all is a machine that has not been set up,
    // rather than one that is disconnected; nothing to say.
    visible: Tailscale.available

    interactive: true

    onClicked: Tailscale.toggle()

    // Everything the glyph cannot carry, in the order it is wanted: what state
    // we are in, then who we are, then what the tailnet looks like.
    tooltip: {
        if (!Tailscale.available)
            return "";
        if (Tailscale.needsLogin)
            return "Tailscale — not logged in\nClick to authenticate";
        if (!Tailscale.connected)
            return "Tailscale — off\nClick to connect";

        const lines = [`Tailscale — ${Tailscale.selfName}`];
        if (Tailscale.exitNode !== "")
            lines.push(`exit node: ${Tailscale.exitNode}`);
        lines.push(`${Tailscale.peersOnline} peer${Tailscale.peersOnline === 1 ? "" : "s"} online`);
        return lines.join("\n");
    }

    Icon {
        glyph: {
            if (!Tailscale.connected)
                return Icons.tailscaleOff;
            return Tailscale.exitNode !== "" ? Icons.tailscaleExitNode : Icons.tailscale;
        }
        // Matches the bluetooth module: a disabled radio is dimmed rather than
        // hidden, so the bar's shape does not change as it goes on and off.
        opacity: Tailscale.connected ? 1.0 : 0.5
    }
}

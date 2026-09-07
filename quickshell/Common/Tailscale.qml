pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live view of the tailnet, for the bar's Tailscale module.
//
// There is no daemon socket to talk to the way Herdr does: tailscaled's local
// API is HTTP over a unix socket that only root and the configured operator may
// open, and Quickshell has no HTTP client. So this polls the CLI, which is the
// same thing every other Tailscale frontend does.
//
// `tailscale status --json` is cheap - it reads the daemon's in-memory netmap,
// it does not touch the network - so a five second poll costs nothing. The
// number is chosen against how fast the state actually moves: coming up takes a
// second or two, and nothing else changes on its own.
Singleton {
    id: root

    readonly property int pollInterval: 5000

    // BackendState as tailscaled reports it. The four that matter here:
    //   Running    - up, authenticated, carrying traffic
    //   Stopped    - logged in but `tailscale down`
    //   NeedsLogin - never authenticated, or the node key expired
    //   NoState    - daemon is still starting
    property string backendState: ""
    // This machine's name on the tailnet, minus the trailing dot and tailnet
    // suffix that DNSName carries.
    property string selfName: ""
    // DNSName of the exit node currently carrying traffic, "" when routing
    // directly. Worth surfacing because it is the one piece of Tailscale state
    // that silently changes what every other application on the machine sees.
    property string exitNode: ""
    property int peersOnline: 0
    // Whether the CLI answered at all. False means tailscaled is not running,
    // which is a different thing from being logged out, and is what hides the
    // module rather than showing a struck-through icon forever.
    property bool available: false

    readonly property bool connected: root.backendState === "Running"
    readonly property bool needsLogin: root.backendState === "NeedsLogin"

    // `up` and `down` go through the daemon, which authorises the caller as
    // root or as the operator. services.tailscale.extraSetFlags pins the
    // operator to this user, which is what lets the bar toggle without asking
    // for a password - see modules/nixos/tailscale.nix.
    //
    // Detached because `up` on a node that has never logged in blocks while it
    // waits for the browser, and the bar must not block with it.
    function toggle() {
        Quickshell.execDetached({
            command: ["tailscale", root.connected ? "down" : "up", "--accept-routes"]
        });
        // Do not wait for the next tick to show the change; the poll will
        // correct this if the command failed.
        statusProc.running = true;
    }

    function _parse(text) {
        if (!text) {
            root.available = false;
            return;
        }
        try {
            const s = JSON.parse(text);
            root.available = true;
            root.backendState = s.BackendState ?? "";
            // DNSName is fully qualified with a trailing dot; the bar wants the
            // hostname alone.
            root.selfName = (s.Self?.DNSName ?? "").split(".")[0];

            let online = 0;
            let exit = "";
            for (const key in (s.Peer ?? {})) {
                const peer = s.Peer[key];
                if (peer.Online)
                    online++;
                // ExitNode is the peer currently in use, as distinct from
                // ExitNodeOption, which merely offers to be one.
                if (peer.ExitNode)
                    exit = (peer.DNSName ?? "").split(".")[0];
            }
            root.peersOnline = online;
            root.exitNode = exit;
        } catch (e) {
            // A half-written or empty read is a lost poll, not a reason to
            // blank the module.
            console.warn("tailscale: unparseable status:", e);
        }
    }

    Process {
        id: statusProc

        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            id: collector
        }
        // A non-zero exit is tailscaled being absent or unreachable. Reported
        // as unavailable rather than parsed.
        onExited: exitCode => exitCode === 0 ? root._parse(collector.text) : root.available = false
    }

    Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProc.running)
                statusProc.running = true;
        }
    }
}

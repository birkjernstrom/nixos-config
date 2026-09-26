pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live view of power-profiles-daemon's active profile, for the battery
// module's tooltip. Quickshell has no binding for the daemon and no generic
// D-Bus signal API, so this polls the CLI the same way Tailscale.qml does for
// tailscaled - profile switches are rare and user-initiated, so a slow poll
// costs nothing and stays close enough to live.
Singleton {
    id: root

    readonly property int pollInterval: 10000

    // "performance" | "balanced" | "power-saver", or "" if the daemon is not
    // reachable (services.power-profiles-daemon is only enabled on some hosts
    // - see hosts/*/configuration.nix).
    property string profile: ""
    property bool available: false

    Process {
        id: getProc

        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            id: collector
        }
        onExited: exitCode => {
            root.available = exitCode === 0;
            root.profile = root.available ? collector.text.trim() : "";
        }
    }

    Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!getProc.running)
                getProc.running = true;
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// mako's do-not-disturb mode (modules/nixos/mako.nix) is the source of truth.
Singleton {
    id: root

    property bool active: false

    function toggle(): void {
        root.active = !root.active;
        Quickshell.execDetached(["makoctl", "mode", root.active ? "-a" : "-r", "do-not-disturb"]);
    }

    Process {
        running: true
        command: ["makoctl", "mode"]
        stdout: StdioCollector {
            id: modes
        }
        onExited: root.active = modes.text.split("\n").includes("do-not-disturb")
    }
}

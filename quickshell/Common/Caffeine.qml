pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// hypridle's suspend listener skips while this flag file exists.
Singleton {
    id: root

    readonly property string flag: `${Quickshell.env("XDG_RUNTIME_DIR")}/caffeinated`

    property bool active: false

    function toggle(): void {
        root.active = !root.active;
        Quickshell.execDetached(root.active ? ["touch", root.flag] : ["rm", "-f", root.flag]);
    }

    Process {
        running: true
        command: ["test", "-e", root.flag]
        onExited: exitCode => root.active = exitCode === 0
    }
}

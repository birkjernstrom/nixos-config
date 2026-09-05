pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common.themes

// The switchable colour layer. Theme.qml maps these slots onto semantic tokens,
// and every widget reads only those tokens - so changing `currentId` re-evaluates
// the whole shell through ordinary bindings. That is the entire live-reload
// mechanism; there is no reloading to do.
//
// Palettes come from tools/gen-themes.sh. Adding one is a line in that script's
// SCHEMES list plus an entry below.
Singleton {
    id: root

    readonly property var available: [
        {
            id: "kanagawa-dragon",
            name: "Kanagawa Dragon",
            palette: KanagawaDragon,
            overrides: ({})
        },
        {
            id: "tokyo-night-storm",
            name: "Tokyo Night Storm",
            palette: TokyoNightStorm,
            // Storm does not follow base16 terminal semantics: its base08 is a
            // pale blue and base0A a cyan, with the red parked in base0F and no
            // yellow anywhere. Remapping the two slots the semantic layer treats
            // as red and yellow keeps low-battery and urgent states legible;
            // the orange is Tokyo Night's own, borrowed from the terminal variant.
            overrides: ({
                base08: "#f7768e",
                base0A: "#ff9e64"
            })
        }
    ]

    property string currentId: root.available[0].id

    // An id from a stale or hand-edited state file must not take the shell down.
    readonly property var entry: root.available.find(t => t.id === root.currentId) ?? root.available[0]

    readonly property color base00: root._slot("base00")
    readonly property color base01: root._slot("base01")
    readonly property color base02: root._slot("base02")
    readonly property color base03: root._slot("base03")
    readonly property color base04: root._slot("base04")
    readonly property color base05: root._slot("base05")
    readonly property color base06: root._slot("base06")
    readonly property color base07: root._slot("base07")
    readonly property color base08: root._slot("base08")
    readonly property color base09: root._slot("base09")
    readonly property color base0A: root._slot("base0A")
    readonly property color base0B: root._slot("base0B")
    readonly property color base0C: root._slot("base0C")
    readonly property color base0D: root._slot("base0D")
    readonly property color base0E: root._slot("base0E")
    readonly property color base0F: root._slot("base0F")

    readonly property string dir: Quickshell.statePath("shell")
    readonly property string path: root.dir + "/theme.json"

    function select(id) {
        if (!root.available.some(t => t.id === id))
            return;
        root.currentId = id;
        file.setText(JSON.stringify({
            id: id
        }));
        // Quickshell restyles itself through bindings; everything else needs
        // pushing out and reloading.
        ThemeExport.apply(true);
    }

    function _slot(name) {
        return root.entry.overrides[name] ?? root.entry.palette[name];
    }

    FileView {
        id: file

        path: root.path
        atomicWrites: true
        // A missing file on first run is expected, not an error worth logging.
        printErrors: false
        preload: true
        blockLoading: true
    }

    // FileView will not create the parent directory itself, so the first save
    // would otherwise fail silently.
    Process {
        command: ["mkdir", "-p", root.dir]
        running: true
    }

    Component.onCompleted: {
        // Blocking read: the right palette has to be live before the first frame,
        // otherwise the shell flashes the default theme on every start.
        const raw = file.text();
        if (!raw)
            return;
        try {
            const parsed = JSON.parse(raw);
            if (parsed && parsed.id)
                root.currentId = parsed.id;
        } catch (e) {
            console.warn("themes: discarding unreadable theme state:", e);
        }
        // Keep the exported files in step with the restored theme, but do not
        // signal running terminals just because the shell restarted.
        ThemeExport.apply(false);
    }
}

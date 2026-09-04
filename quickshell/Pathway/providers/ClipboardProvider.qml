pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, backed by cliphist - the replacement for the
// `cliphist list | wofi --show dmenu | cliphist decode | wl-copy` pipeline that
// SUPER+V used to run.
//
// Unlike AppsProvider this is not a standing list: it is re-read every time the
// clipboard scope is opened, because the history changes constantly.
Singleton {
    id: root

    readonly property int limit: 200

    property var items: []

    function refresh() {
        listProc.running = true;
    }

    function _parse(text) {
        const out = [];
        const lines = (text ?? "").split("\n");
        for (let i = 0; i < lines.length && out.length < root.limit; ++i) {
            const line = lines[i];
            if (line === "")
                continue;
            // cliphist emits "<id>\t<single-line preview>".
            const tab = line.indexOf("\t");
            if (tab <= 0)
                continue;
            const id = line.slice(0, tab);
            const preview = line.slice(tab + 1);
            // Images come through as "[[ binary data 232 KiB png 1257x1541 ]]".
            const binary = preview.startsWith("[[ binary data");
            out.push({
                id: "clip:" + id,
                name: preview,
                subtitle: "",
                icon: "",
                keywords: [],
                kind: binary ? "clip-binary" : "clip",
                // cliphist recycles ids as entries age out, so ranking them by
                // frecency would attach a score to whatever later took the slot.
                frecency: false,
                activate: () => root.copy(id)
            });
        }
        root.items = out;
    }

    // Passing the id as "$1" rather than interpolating it into the script keeps
    // the value out of the shell's parsing entirely.
    function copy(id) {
        Quickshell.execDetached({
            command: ["sh", "-c", 'cliphist decode "$1" | wl-copy', "pathway-clipboard", String(id)]
        });
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            id: collector
        }
        onExited: root._parse(collector.text)
    }
}

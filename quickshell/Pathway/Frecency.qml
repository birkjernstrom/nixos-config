pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persisted launch scores: frequency decayed by recency, so the apps actually
// in rotation float to the top of the empty-query list within days.
//
// Deliberately uses text()/setText() rather than a JsonAdapter - writeAdapter()
// is not part of the FileView surface in quickshell 0.3.x.
Singleton {
    id: root

    readonly property string dir: Quickshell.statePath("pathway")
    readonly property string path: root.dir + "/frecency.json"

    // A launch is worth half as much after this many days.
    readonly property real halfLifeDays: 14

    // id -> { count: int, last: unix seconds }
    property var entries: ({})

    function score(id) {
        const e = root.entries[id];
        if (!e || !e.count)
            return 0;
        const ageDays = (Date.now() / 1000 - (e.last ?? 0)) / 86400;
        if (!isFinite(ageDays) || ageDays < 0)
            return e.count;
        return e.count * Math.pow(0.5, ageDays / root.halfLifeDays);
    }

    function bump(id) {
        if (!id)
            return;
        const e = root.entries[id] ?? {
            count: 0,
            last: 0
        };
        // Reassign the whole object so the property change propagates - mutating
        // in place would not re-evaluate bindings on `entries`.
        const next = Object.assign({}, root.entries);
        next[id] = {
            count: e.count + 1,
            last: Math.floor(Date.now() / 1000)
        };
        root.entries = next;
        saveTimer.restart();
    }

    function _save() {
        file.setText(JSON.stringify(root.entries));
    }

    // Rapid bumps (or a burst on startup) collapse into one write.
    Timer {
        id: saveTimer

        interval: 500
        onTriggered: root._save()
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

    // mkdir -p: FileView will not create the parent directory itself, so the
    // very first save would otherwise fail silently.
    Process {
        id: mkdir

        command: ["mkdir", "-p", root.dir]
        running: true
    }

    Component.onCompleted: {
        // Blocking read, so entries are populated before the first query runs.
        const raw = file.text();
        if (!raw)
            return;
        try {
            const parsed = JSON.parse(raw);
            if (parsed && typeof parsed === "object")
                root.entries = parsed;
        } catch (e) {
            // Corrupt state must never take the shell down; start fresh instead.
            console.warn("pathway: discarding unreadable frecency state:", e);
        }
    }
}

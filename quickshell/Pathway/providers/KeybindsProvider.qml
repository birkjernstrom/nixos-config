pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live Hyprland binds, grouped by the "Group: Action" descriptions set in
// modules/nixos/hyprland/lib.nix.
Singleton {
    id: root

    // Unlisted groups follow alphabetically.
    readonly property var groupOrder: ["Launcher", "Apps", "Windows", "Workspaces", "Monitors", "Screen capture", "Dictation", "Media", "System"]

    readonly property bool wide: true
    property var items: []

    function refresh() {
        listProc.running = true;
    }

    function _parse(text) {
        let binds;
        try {
            binds = JSON.parse(text);
        } catch (e) {
            return;
        }

        const groups = new Map();
        for (const b of binds) {
            const sep = (b.description ?? "").indexOf(": ");
            if (sep <= 0)
                continue;
            const group = b.description.slice(0, sep);
            const action = b.description.slice(sep + 2);
            if (!groups.has(group))
                groups.set(group, []);
            root._add(groups.get(group), b.modmask, b.key, action);
        }

        const rank = g => {
            const i = root.groupOrder.indexOf(g);
            return i < 0 ? root.groupOrder.length : i;
        };
        const names = [...groups.keys()].sort((a, b) => rank(a) - rank(b) || a.localeCompare(b));

        const out = [];
        for (const group of names) {
            out.push({
                id: "keybind-group:" + group,
                name: group,
                kind: "section"
            });
            for (const row of groups.get(group)) {
                const combo = root._combo(row.modmask, row.keys);
                out.push({
                    id: "keybind:" + combo,
                    name: combo,
                    subtitle: row.action,
                    icon: "",
                    keywords: [group],
                    kind: "keybind",
                    frecency: false,
                    activate: () => {}
                });
            }
        }
        root.items = out;
    }

    // Folds SUPER+1..8 style binds into one row.
    function _add(rows, modmask, key, action) {
        const digit = /^\d$/.test(key) && action.endsWith(" " + key);
        if (digit) {
            const stem = action.slice(0, -key.length - 1);
            const row = rows.find(r => r.stem === stem && r.modmask === modmask);
            if (row) {
                row.digits.push(key);
                row.keys = row.digits[0] + "–" + row.digits[row.digits.length - 1];
                return;
            }
            rows.push({
                modmask: modmask,
                keys: key,
                action: stem,
                stem: stem,
                digits: [key]
            });
            return;
        }
        rows.push({
            modmask: modmask,
            keys: root._key(key),
            action: action
        });
    }

    function _combo(modmask, key) {
        const mods = [];
        if (modmask & 64)
            mods.push("SUPER");
        if (modmask & 4)
            mods.push("CTRL");
        if (modmask & 8)
            mods.push("ALT");
        if (modmask & 1)
            mods.push("SHIFT");
        return mods.concat([key]).join(" + ");
    }

    function _key(key) {
        const named = {
            "return": "Enter",
            "space": "Space",
            "bracketleft": "[",
            "bracketright": "]"
        };
        return named[key] ?? (key.length === 1 ? key.toUpperCase() : key);
    }

    Process {
        id: listProc

        command: ["hyprctl", "-j", "binds"]
        stdout: StdioCollector {
            id: collector
        }
        onExited: root._parse(collector.text)
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common.themes

// The switchable colour layer. Theme.qml maps these slots onto semantic tokens,
// and every widget reads only those tokens - so changing `currentId` re-evaluates
// the whole shell through ordinary bindings, instantly.
//
// Everything outside the shell - GTK, Ghostty, Hyprland, tmux, mako, Neovim and
// the rest of what Stylix themes - is switched by `theme-switch`, which
// activates that theme's pre-built home-manager specialisation
// (modules/nixos/themes). The theme ids and overrides here must match its list.
//
// Palettes come from tools/gen-themes.sh. Adding a theme is a line in that
// script's SCHEMES list, an entry below, and one in modules/nixos/themes.
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
        },
        {
            id: "vesper",
            name: "Vesper",
            // Hand-mapped from the original theme (tools/schemes/vesper.yaml)
            // rather than the loose base16-schemes version, so no overrides.
            palette: Vesper,
            overrides: ({})
        },
        {
            id: "nord",
            name: "Nord",
            palette: Nord,
            // Nord's base07 is a frost teal, but base07 is the terminal's bright
            // white - bold text would come out teal. Snow Storm's white instead.
            overrides: ({
                base07: "#eceff4"
            })
        },
        {
            id: "grayscale-dark",
            name: "Grayscale Dark",
            palette: GrayscaleDark,
            // Every accent slot in Grayscale is a mid-grey, so errors, warnings,
            // urgent workspaces and agents waiting on you would vanish into the
            // rest. One muted red and one muted amber keep those readable
            // without breaking the monochrome look.
            overrides: ({
                base08: "#c76b6b",
                base0A: "#c9a866"
            })
        },
        {
            id: "rose-pine",
            name: "Rosé Pine",
            palette: RosePine,
            // The base16 port puts a dark grey in base07, the terminal's bright
            // white, and the pale "rose" in base0A, where warnings and agents
            // waiting on you would barely show. Rosé Pine's text colour and its
            // gold instead.
            overrides: ({
                base07: "#e0def4",
                base0A: "#f6c177"
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

    // theme-switch's own record of the active theme, so the bar and the rest
    // of the desktop cannot disagree - including after `theme-switch` is run
    // from a terminal, which the watch below picks up.
    readonly property string path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/theme-switch/current`

    function select(id) {
        if (!root.available.some(t => t.id === id))
            return;
        // The bar switches now; the rest follows once the activation lands, a
        // second or two later.
        root.currentId = id;
        Quickshell.execDetached(["theme-switch", id]);
    }

    function _slot(name) {
        return root.entry.overrides[name] ?? root.entry.palette[name];
    }

    function _load() {
        const id = file.text().trim();
        if (id !== "" && root.available.some(t => t.id === id))
            root.currentId = id;
    }

    FileView {
        id: file

        path: root.path
        // A missing file just means the default theme was never changed.
        printErrors: false
        preload: true
        blockLoading: true
        watchChanges: true
        // Applied once the contents are actually in, not from Component.onCompleted:
        // at startup that can run before the file has been read, which left the
        // bar on the default theme whatever had been chosen.
        onLoaded: root._load()
        // theme-switch replaces the file (a rename), which a watch reports as
        // a change; reloading ends in onLoaded again.
        onFileChanged: file.reload()
    }
}

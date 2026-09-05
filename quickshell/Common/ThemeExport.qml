pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pushes the active palette out to the programs Quickshell does not draw itself.
//
// Stylix themes those at Nix build time, so their colours live read-only in the
// store and cannot follow a runtime switch. For each one we take ownership of a
// single writable file (or a live IPC call) and leave the rest to Stylix.
//
// Only programs that can genuinely reload are here. GTK apps, mako and hyprlock
// still need a nixos-rebuild to change colour - see docs in the repo README.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // ghostty.nix forces `theme = pathway`, so this file is the whole palette as
    // far as Ghostty is concerned. Stylix still owns the font.
    readonly property string ghosttyTheme: root.home + "/.config/ghostty/themes/pathway"

    // base16 -> ANSI 0-15, the standard mapping, matching what Stylix's own
    // ghostty target emits so nothing shifts when we take it over.
    function _ghosttyBody() {
        const p = [Themes.base00, Themes.base08, Themes.base0B, Themes.base0A, Themes.base0D, Themes.base0E, Themes.base0C, Themes.base05, Themes.base03, Themes.base08, Themes.base0B, Themes.base0A, Themes.base0D, Themes.base0E, Themes.base0C, Themes.base07];
        let out = "";
        for (let i = 0; i < p.length; ++i)
            out += `palette = ${i}=${p[i]}\n`;
        out += `background = ${Themes.base00}\n`;
        out += `foreground = ${Themes.base05}\n`;
        out += `cursor-color = ${Themes.base05}\n`;
        out += `selection-background = ${Themes.base02}\n`;
        out += `selection-foreground = ${Themes.base05}\n`;
        return out;
    }

    // `reload` is false on startup: the file is rewritten to match the restored
    // theme, but signalling every terminal on every shell restart would be rude.
    function apply(reload) {
        ghosttyFile.setText(root._ghosttyBody());

        // Borders are the one part of Hyprland that carries the palette. The Lua
        // config parser rejects `hyprctl keyword`, so this goes through eval.
        const border = `hl.config({ general = { ["col.active_border"] = "rgb(${root._hex(Themes.base0D)})", ["col.inactive_border"] = "rgb(${root._hex(Themes.base03)})" } })`;
        Quickshell.execDetached({
            command: ["hyprctl", "eval", border]
        });

        if (!reload)
            return;

        // Ghostty reloads its config on SIGUSR2 and repaints open windows.
        //
        // Deliberately not `pkill -x`: the Nix wrapper makes the process name
        // ".ghostty-wrappe", so an exact match finds nothing. Matching on comm
        // without -x hits the wrapper, and unlike `pkill -f` it cannot stray
        // onto some unrelated process that merely mentions ghostty in its args.
        Quickshell.execDetached({
            command: ["pkill", "-USR2", "ghostty"]
        });
    }

    // QML colors stringify as #rrggbb; hyprctl wants the bare hex.
    function _hex(color) {
        return String(color).replace("#", "");
    }

    FileView {
        id: ghosttyFile

        path: root.ghosttyTheme
        atomicWrites: true
        printErrors: false
    }
}

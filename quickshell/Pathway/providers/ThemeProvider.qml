pragma Singleton

import Quickshell
import qs.Common

// The theme list. Scope-only - reached by activating the "Theme" command, never
// registered in Search.providers, so individual themes do not clutter the main
// result list.
Singleton {
    id: root

    readonly property var items: root._build(Themes.available, Themes.currentId)

    function _build(available, currentId) {
        const out = [];
        for (let i = 0; i < available.length; ++i) {
            const theme = available[i];
            out.push({
                id: "theme:" + theme.id,
                name: theme.name,
                subtitle: theme.id === currentId ? "Current" : "",
                icon: "",
                keywords: [],
                kind: "theme",
                // The row preview: background, foreground, then the three slots
                // the semantic layer actually leans on, overrides applied so the
                // swatch matches what you will really get.
                swatch: ["base00", "base05", "base0E", "base0A", "base08"].map(slot => theme.overrides[slot] ?? theme.palette[slot]),
                // Picking a theme is idempotent and cheap; ranking themes by how
                // often they were picked would just pin whichever you set first.
                frecency: false,
                activate: () => Themes.select(theme.id)
            });
        }
        return out;
    }
}

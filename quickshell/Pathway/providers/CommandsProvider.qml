pragma Singleton

import Quickshell
import qs.Common
import qs.Pathway

// Shell commands, as opposed to launchable applications. Registered globally in
// Search.qml so these are reachable from the main search field.
Singleton {
    id: root

    readonly property var items: [
        {
            id: "command:theme",
            name: "Theme",
            subtitle: "Switch colour scheme",
            icon: "",
            keywords: ["theme", "colour", "color", "scheme", "appearance", "style"],
            // "module" is what keeps Pathway open on Enter and draws the chevron;
            // the scope then replaces the result list with the theme list.
            kind: "module",
            activate: () => Nav.pushScope(ThemeProvider, "Theme")
        },
        {
            id: "command:wallpaper",
            name: "Wallpaper",
            subtitle: "Pick a wallpaper for this theme",
            icon: "",
            keywords: ["wallpaper", "background", "desktop", "image", "appearance"],
            kind: "module",
            activate: () => {
                WallpaperProvider.refresh();
                Nav.pushScope(WallpaperProvider, "Wallpaper");
            }
        },
        {
            id: "command:dnd",
            name: "Do Not Disturb",
            subtitle: "Toggle notifications",
            icon: "",
            keywords: ["dnd", "do not disturb", "notifications", "mute", "silence", "focus"],
            kind: "command",
            activate: () => DoNotDisturb.toggle()
        }
    ]
}

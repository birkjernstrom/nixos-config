pragma Singleton

import Quickshell
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
        }
    ]
}

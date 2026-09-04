pragma Singleton

import Quickshell

// WAVE 0 STUB: two hardcoded entries so the skeleton can be verified end to end.
// Agent 5 replaces `items` with DesktopEntries.applications, filtering noDisplay
// and launching via Quickshell.execDetached({ command, workingDirectory }).
//
// The ResultItem contract this emits is fixed:
//   { id, name, subtitle, icon, keywords, kind, activate }
Singleton {
    id: root

    readonly property var items: [
        {
            id: "ghostty.desktop",
            name: "Ghostty",
            subtitle: "Terminal",
            icon: "utilities-terminal",
            keywords: ["terminal", "shell"],
            kind: "app",
            activate: () => Quickshell.execDetached({
                    command: ["ghostty"]
                })
        },
        {
            id: "firefox.desktop",
            name: "Firefox",
            subtitle: "Web Browser",
            icon: "firefox",
            keywords: ["web", "browser", "internet"],
            kind: "app",
            activate: () => Quickshell.execDetached({
                    command: ["firefox"]
                })
        }
    ]
}

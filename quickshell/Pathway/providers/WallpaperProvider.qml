pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

// The wallpapers for the current theme's polarity, from wallpapers/{dark,light}/.
// Scope-only, like ThemeProvider. Listing and remembering the choice are the
// `wallpaper` script's job (modules/nixos/themes), so the bar and a terminal
// agree on both.
Singleton {
    id: root

    readonly property string polarity: Themes.light ? "light" : "dark"

    property var images: []
    property string current: ""

    readonly property var items: root._build(root.images, root.current)

    function refresh() {
        listProc.running = true;
        currentProc.running = true;
    }

    function select(path) {
        root.current = path;
        Quickshell.execDetached(["wallpaper", "set", path]);
    }

    function _build(images, current) {
        return images.map(path => {
            const file = path.slice(path.lastIndexOf("/") + 1);
            return {
                id: "wallpaper:" + path,
                name: file.replace(/\.[^.]+$/, ""),
                subtitle: path === current ? "Current" : "",
                icon: "",
                keywords: [],
                kind: "wallpaper",
                preview: "file://" + path,
                frecency: false,
                activate: () => root.select(path)
            };
        });
    }

    onPolarityChanged: root.refresh()

    Process {
        id: listProc

        command: ["wallpaper", "--list", root.polarity]
        stdout: StdioCollector {
            id: listOut
        }
        onExited: root.images = listOut.text.split("\n").filter(line => line !== "")
    }

    Process {
        id: currentProc

        command: ["wallpaper", "--current", root.polarity]
        stdout: StdioCollector {
            id: currentOut
        }
        onExited: root.current = currentOut.text.trim()
    }
}

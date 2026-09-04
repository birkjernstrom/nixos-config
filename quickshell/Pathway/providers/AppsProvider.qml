pragma Singleton

import Quickshell
// ProcessContext is a structured value type from Quickshell.Io. Without this
// import the JS object passed to execDetached cannot be converted and the
// launch fails with a TypeError at runtime.
import Quickshell.Io

// The installed desktop entries, as ResultItems:
//   { id, name, subtitle, icon, keywords, kind, activate }
Singleton {
    id: root

    // Terminal=true entries bring no terminal of their own.
    readonly property var terminalCommand: ["ghostty", "-e"]

    readonly property var items: root._build(DesktopEntries.applications?.values)

    function _build(entries) {
        const list = root._toArray(entries);
        const items = [];
        for (let i = 0; i < list.length; ++i) {
            const entry = list[i];
            if (!entry || entry.noDisplay)
                continue;
            items.push({
                id: entry.id,
                name: entry.name ?? "",
                subtitle: entry.genericName || entry.comment || "",
                icon: entry.icon ?? "",
                keywords: root._toArray(entry.keywords).concat(root._toArray(entry.categories)),
                kind: "app",
                activate: () => root.launch(entry)
            });
        }
        return items;
    }

    function launch(entry) {
        // `command` is the parsed argv; execString still carries %U/%f field codes.
        const argv = root._toArray(entry.command);
        if (argv.length === 0) {
            console.warn("pathway: no executable command for", entry.id);
            return;
        }

        const options = {
            command: entry.runInTerminal ? root.terminalCommand.concat(argv) : argv
        };
        // An unset workingDirectory must stay unset - passing "" would try to
        // chdir there and the launch would fail.
        if (entry.workingDirectory)
            options.workingDirectory = entry.workingDirectory;

        // Detached, so the app outlives the shell process that started it.
        Quickshell.execDetached(options);
    }

    // QML sequence properties are array-like but not JS Arrays, so concat would
    // append them whole instead of flattening. Copy before treating them as such.
    function _toArray(seq) {
        return seq ? Array.prototype.slice.call(seq) : [];
    }
}

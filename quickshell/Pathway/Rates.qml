pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Daily exchange rates against USD from open.er-api.com, cached on disk so
// conversions work offline and never wait on the network.
Singleton {
    id: root

    readonly property string url: "https://open.er-api.com/v6/latest/USD"
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/pathway/rates.json`

    property var rates: ({})
    property real updated: 0
    property real nextUpdate: 0
    property real _lastAttempt: 0

    readonly property bool ready: Object.keys(root.rates).length > 0

    function refresh(): void {
        const now = Date.now() / 1000;
        if (fetch.running || now < root.nextUpdate || now - root._lastAttempt < 600)
            return;
        root._lastAttempt = now;
        fetch.running = true;
    }

    function convert(amount: real, from: string, to: string): real {
        return amount / root.rates[from] * root.rates[to];
    }

    function _parse(text: string): void {
        try {
            const data = JSON.parse(text);
            if (data.result !== "success" || !data.rates)
                return;
            root.rates = data.rates;
            root.updated = data.time_last_update_unix ?? 0;
            root.nextUpdate = data.time_next_update_unix ?? 0;
        } catch (e) {}
    }

    FileView {
        id: file

        path: root.cache
        watchChanges: true
        printErrors: false
        onFileChanged: file.reload()
        onLoaded: {
            root._parse(file.text());
            root.refresh();
        }
        onLoadFailed: root.refresh()
    }

    Process {
        id: fetch

        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && curl -sf --max-time 10 -o "$1.tmp" "$2" && mv "$1.tmp" "$1"', "pathway-rates", root.cache, root.url]
        onExited: code => {
            if (code === 0)
                file.reload();
        }
    }
}

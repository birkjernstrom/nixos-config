pragma Singleton

import QtQuick
import Quickshell
import qs.Pathway

// The screen recorder's camera prompt. `screenrecord` opens it over IPC with the
// cameras it found and a FIFO, then blocks reading that FIFO: "=DEVICE" picks a
// camera, an empty line cancels the recording. Leaving the scope any way other
// than picking (Escape, clicking away) counts as cancelling.
Singleton {
    id: root

    property var items: []
    property string reply: ""

    function ask(cameras, reply) {
        root._answer("");
        root.reply = reply;
        root.items = cameras.split("\n").filter(line => line !== "").map(line => {
            const [device, name, note] = line.split("\t");
            return {
                id: "webcam:" + device,
                name: name,
                subtitle: note ?? "",
                icon: "",
                keywords: [],
                kind: "webcam",
                frecency: false,
                activate: () => root._answer("=" + device)
            };
        });
    }

    function _answer(line) {
        if (root.reply === "")
            return;
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" > "$2"', "sh", line, root.reply]);
        root.reply = "";
    }

    Connections {
        function onScopeChanged() {
            if (Nav.scope === root || root.reply === "")
                return;
            root._answer("");
            Nav.close();
        }

        target: Nav
    }
}

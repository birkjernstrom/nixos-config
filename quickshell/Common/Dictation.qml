pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // idle | recording | transcribing | error
    property string status: "idle"
    property string message: ""
    property real since: 0
    property int elapsed: 0

    readonly property bool active: root.status !== "idle"

    function set(status: string): void {
        root.status = status;
        root.message = "";
        root.since = Date.now();
        root.elapsed = 0;
    }

    function fail(message: string): void {
        root.set("error");
        root.message = message;
    }

    function stop(): void {
        Quickshell.execDetached(["dictate", "stop"]);
    }

    function cancel(): void {
        Quickshell.execDetached(["dictate", "cancel"]);
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.status === "recording"
        onTriggered: root.elapsed = Math.floor((Date.now() - root.since) / 1000)
    }

    Timer {
        interval: 4000
        running: root.status === "error"
        onTriggered: root.set("idle")
    }
}

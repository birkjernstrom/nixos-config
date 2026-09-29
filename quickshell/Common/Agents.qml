pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live view of every coding-agent session on this machine, whatever terminal or
// tmux session it runs in. Replaces the herdr client that used to live here.
//
// The data is `agent-status list` (modules/nixos/agents/agent-status.sh): the
// agents' own hooks keep one JSON file per session, and listing them prunes the
// ones whose process has gone. Each hook also pokes `qs ipc call agents
// refresh`, so a change lands immediately; the poll is only a backstop for what
// no hook reports - a session that died, or was interrupted with Esc.
Singleton {
    id: root

    readonly property int pollInterval: 5000

    // Each { id, agent, state, since, cwd, prompt, tmux: { session, ... } },
    // most urgent first: waiting, then working, then idle.
    property var sessions: []

    readonly property int total: root.sessions.length
    readonly property int working: root._count("working")
    readonly property int waiting: root._count("waiting")
    readonly property int idle: root._count("idle")

    // The single state the bar shows: anything waiting on you outranks
    // anything working, which outranks all-idle. Empty when there are none.
    readonly property string overall: {
        if (root.waiting > 0)
            return "waiting";
        if (root.working > 0)
            return "working";
        return root.total > 0 ? "idle" : "";
    }

    // Set when a refresh arrives mid-read, so a burst of hook pokes collapses
    // into one extra read rather than being dropped.
    property bool _again: false

    function _count(state: string): int {
        let n = 0;
        for (const s of root.sessions) {
            if (s.state === state)
                n++;
        }
        return n;
    }

    function refresh(): void {
        if (listProc.running)
            root._again = true;
        else
            listProc.running = true;
    }

    // Focus the session's terminal window and bring up its tmux pane.
    function jump(id: string): void {
        Quickshell.execDetached(["agent-status", "jump", id]);
    }

    // "demo" for /home/birk/code/demo - what the session is about at a glance.
    function project(session): string {
        const cwd = session.cwd ?? "";
        const parts = cwd.split("/").filter(p => p !== "");
        return parts.length > 0 ? parts[parts.length - 1] : cwd;
    }

    // "12m", "3h" - how long the session has been in its current state.
    function age(session): string {
        const seconds = Math.max(0, Math.floor(Date.now() / 1000) - (session.since ?? 0));
        if (seconds < 60)
            return `${seconds}s`;
        if (seconds < 3600)
            return `${Math.floor(seconds / 60)}m`;
        if (seconds < 86400)
            return `${Math.floor(seconds / 3600)}h`;
        return `${Math.floor(seconds / 86400)}d`;
    }

    Process {
        id: listProc

        command: ["agent-status", "list"]
        stdout: StdioCollector {
            id: collector
        }
        onExited: {
            try {
                const parsed = JSON.parse(collector.text);
                if (Array.isArray(parsed))
                    root.sessions = parsed;
            } catch (e) {
                // A half-written read, or agent-status not installed: keep
                // what we had rather than flashing the module off.
            }
            if (root._again) {
                root._again = false;
                listProc.running = true;
            }
        }
    }

    Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}

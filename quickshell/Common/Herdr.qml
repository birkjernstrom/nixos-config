pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live view of the agents running under herdr (herdr.dev), the terminal
// workspace manager this machine runs its coding agents in.
//
// herdr's server speaks newline-delimited JSON over a unix socket, so the bar
// talks to it directly rather than spawning the CLI on a timer.
//
// TWO PROPERTIES OF THE SERVER SHAPE EVERYTHING BELOW
//
// It polls rather than subscribes. `events.subscribe` exists and pane events
// carry exactly these fields, but a new subscriber is replayed the server's
// entire event journal before it reaches live events - measured here at
// protocol 20, a fresh connection began at pane w4:p2 revision 14 while the
// live revision was 117, taking about 25 seconds to catch up and drifting
// further the longer the server has been up. A bar showing a quarter-minute of
// history after every reload, complete with panes that have since closed, is
// worse than one that is two seconds behind. Revisit if subscriptions gain a
// way to start at "now".
//
// And a connection carries exactly one request: the server closes it as soon as
// it has answered. So every poll is a fresh connect, and a disconnect is the
// normal end of an exchange rather than a fault - which is why losing the
// socket only clears the agent list after several attempts in a row have failed
// to produce an answer.
Singleton {
    id: root

    // Where the default session's server listens. A named session
    // (herdr --session foo) gets its own socket; the bar follows the default.
    readonly property string socketPath: `${Quickshell.env("HOME")}/.config/herdr/herdr.sock`

    // Fast enough that a blocked agent is noticed while you are still looking
    // at the screen, slow enough to be invisible on a power budget.
    readonly property int pollInterval: 2000
    // herdr not running is the ordinary state of a machine that is not doing
    // agent work, not an error, so unanswered polls back off instead of
    // hammering a socket that nothing is behind.
    readonly property int retryInterval: 10000
    // One dropped exchange is a server restart or a lost race, not an absence.
    readonly property int missesBeforeClear: 2

    // Agents currently known to herdr, each { status, agent, workspace, title,
    // paneId }. Empty when herdr is not running, which is what hides the bar
    // module.
    property var agents: []
    // Whether herdr answered recently. Distinct from the socket's own connected
    // state, which is false most of the time by design.
    property bool available: false

    readonly property int total: root.agents.length
    readonly property int working: root._count("working")
    // herdr's word for an agent waiting on you. It only sets it when the pane's
    // visible bottom buffer matches a known approval, question or permission
    // prompt, so it means a real decision is pending rather than a guess.
    readonly property int blocked: root._count("blocked")
    // Finished, and not yet looked at. Also wants you, less urgently.
    readonly property int done: root._count("done")

    // True between sending a request and concluding that exchange either way.
    property bool _pending: false
    property int _misses: 0

    function _count(status: string): int {
        let n = 0;
        for (const agent of root.agents) {
            if (agent.status === status)
                n++;
        }
        return n;
    }

    Socket {
        id: sock

        path: root.socketPath

        parser: SplitParser {
            // The wire format: one JSON value per line, in both directions.
            onRead: line => root._receive(line)
        }

        onConnectionStateChanged: {
            if (sock.connected)
                root._send();
            else if (root._pending)
                root._conclude(false);
        }

        // Nothing listening, or the server went away mid-exchange. Same
        // handling either way - the exchange produced no answer.
        onError: {
            if (root._pending)
                root._conclude(false);
        }
    }

    // One timer for both jobs: while herdr answers it paces the polling, and
    // while it does not it paces the retries. The two never overlap, so a
    // second timer would only be a second thing to keep in sync.
    Timer {
        interval: root.available ? root.pollInterval : root.retryInterval
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            // A tick arriving while an exchange is still open means the last
            // one never finished; count it and start clean.
            if (root._pending)
                root._conclude(false);
            root._pending = true;
            sock.connected = true;
        }
    }

    function _send(): void {
        sock.write('{"id":"qs:bar","method":"session.snapshot","params":{}}\n');
        sock.flush();
    }

    function _conclude(ok: bool): void {
        root._pending = false;
        // Close our end so the next poll starts from a known state rather than
        // inheriting a half-open socket.
        sock.connected = false;

        if (ok) {
            root._misses = 0;
            root.available = true;
            return;
        }
        root._misses++;
        if (root._misses >= root.missesBeforeClear) {
            root.available = false;
            root.agents = [];
        }
    }

    function _receive(line: string): void {
        let message;
        try {
            message = JSON.parse(line);
        } catch (e) {
            return;
        }
        const snapshot = message?.result?.snapshot;
        if (!snapshot || !snapshot.agents)
            return;

        // workspace_id -> the name herdr shows for it, so the tooltip can say
        // "polar" rather than "w5". Falls back to the id for a workspace with
        // no label yet.
        const labels = {};
        for (const workspace of snapshot.workspaces ?? []) {
            labels[workspace.workspace_id] = workspace.label ?? workspace.workspace_id;
        }

        const out = [];
        for (const agent of snapshot.agents) {
            out.push({
                status: agent.agent_status ?? "unknown",
                // display_agent is the presentable name where the agent's
                // manifest gives one; `agent` is the bare id ("claude").
                agent: agent.display_agent ?? agent.agent ?? "agent",
                workspace: labels[agent.workspace_id] ?? agent.workspace_id,
                // What the agent named the work. This copy of the title has
                // herdr's own status glyph stripped, leaving just the task.
                title: agent.terminal_title_stripped ?? "",
                paneId: agent.pane_id
            });
        }
        root.agents = out;
        root._conclude(true);
    }

    // Bring an agent's pane to the front in herdr, turning "something is
    // blocked" into "here it is". Runs on its own connection, since the polling
    // socket is closed between ticks.
    function focus(paneId: string): void {
        if (!paneId)
            return;
        focusSock.pending = paneId;
        // A click landing while the previous one's socket is still open would
        // otherwise queue a target that no state change ever arrives to send.
        if (focusSock.connected)
            focusSock.send();
        else
            focusSock.connected = true;
    }

    Socket {
        id: focusSock

        property string pending: ""

        path: root.socketPath

        onConnectionStateChanged: {
            if (focusSock.connected)
                focusSock.send();
        }

        function send(): void {
            if (focusSock.pending === "")
                return;
            focusSock.write(JSON.stringify({
                id: "qs:bar:focus",
                method: "agent.focus",
                // AgentTarget: a pane id or an agent name, under one key.
                params: { target: focusSock.pending }
            }) + "\n");
            focusSock.flush();
            focusSock.pending = "";
        }
    }
}

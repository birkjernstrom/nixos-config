pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// `@server message` chats. Each turn is one `pathway-mcp` run (modules/nixos/
// quickshell/pathway-mcp.nix), resumed by session id so follow-ups keep context.
Singleton {
    id: root

    readonly property var servers: ({
            linear: "Linear"
        })

    property string server: ""
    readonly property string title: root.servers[root.server] ?? root.server
    property string sessionId: ""
    // Each { role: "user" | "assistant" | "error", text }.
    property var messages: []
    property bool busy: false
    property string status: ""

    // Bumped per conversation, so a run that outlives its chat is ignored.
    property int _gen: 0
    property var _proc: null

    readonly property Component view: Component {
        McpChat {}
    }

    function mentions(raw) {
        const m = raw.match(/^@(\S*)\s*([\s\S]*)$/);
        if (!m)
            return [];
        const name = m[1].toLowerCase();
        const message = m[2].trim();
        return Object.keys(root.servers).filter(id => message ? id === name : id.startsWith(name)).map(id => ({
                    id: "mcp:" + id,
                    name: message ? `Ask ${root.servers[id]}` : root.servers[id],
                    subtitle: message || `@${id} <message>`,
                    icon: "",
                    keywords: [],
                    kind: "module",
                    frecency: false,
                    activate: () => root.start(id, message)
                }));
    }

    function start(server, message) {
        root._gen += 1;
        if (root._proc)
            root._proc.running = false;
        root.server = server;
        root.sessionId = "";
        root.messages = [];
        root.busy = false;
        root.status = "";
        Nav.pushModule(root.view, root.title, text => root.send(text));
        root.send(message);
    }

    function send(text) {
        const message = (text ?? "").trim();
        if (message === "" || root.busy)
            return;
        root._append("user", message);
        root.busy = true;
        root.status = "Thinking";
        root._proc = turn.createObject(root, {
            gen: root._gen,
            command: ["pathway-mcp", root.server, root.sessionId || "-", message],
            running: true
        });
    }

    function _append(role, text) {
        root.messages = root.messages.concat([
            {
                role: role,
                text: text
            }
        ]);
    }

    // Text blocks of one turn share a bubble, so narration around tool calls
    // reads as a single reply.
    function _say(text) {
        const last = root.messages[root.messages.length - 1];
        if (last?.role === "assistant") {
            const copy = root.messages.slice(0, -1);
            root.messages = copy.concat([
                {
                    role: "assistant",
                    text: `${last.text}\n\n${text}`
                }
            ]);
        } else {
            root._append("assistant", text);
        }
    }

    function _handle(line) {
        if (!line.startsWith("{"))
            return;
        let event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }

        if (event.session_id)
            root.sessionId = event.session_id;

        if (event.type === "assistant") {
            for (const block of event.message?.content ?? []) {
                if (block.type === "text" && block.text.trim() !== "")
                    root._say(block.text.trim());
                else if (block.type === "tool_use")
                    root.status = `Using ${block.name.replace(/^mcp__[^_]+__/, "").replace(/_/g, " ")}`;
            }
        } else if (event.type === "result") {
            if (event.is_error)
                root._append("error", event.result || "Request failed");
            else if (root.messages[root.messages.length - 1]?.role !== "assistant" && event.result)
                root._say(event.result);
            root.busy = false;
        }
    }

    Component {
        id: turn

        Process {
            id: proc

            property int gen

            stdout: SplitParser {
                onRead: line => {
                    if (proc.gen === root._gen)
                        root._handle(line);
                }
            }
            onExited: code => {
                if (proc.gen === root._gen) {
                    if (root.busy && code !== 0)
                        root._append("error", `pathway-mcp exited with ${code}`);
                    root.busy = false;
                    root._proc = null;
                }
                proc.destroy();
            }
        }
    }
}

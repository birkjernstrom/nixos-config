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

    // Shorthands for `@server`, e.g. `@l ...` for `@linear ...`.
    readonly property var aliases: ({
            l: "linear"
        })

    // Splits `@name rest` into the server it names and the rest, untrimmed so
    // Linear can tell `#gro` (still typing) from `#gro ` (done). `server` is
    // empty unless the name is a server or an alias of one.
    function _mention(text) {
        const m = text.match(/^@(\S*)([\s\S]*)$/);
        if (!m)
            return null;
        const name = m[1].toLowerCase();
        const id = root.aliases[name] ?? name;
        return {
            name: m[1],
            server: root.servers[id] ? id : "",
            rest: m[2]
        };
    }

    // The Linear team chip in the search field: the team `text` would act on,
    // or the open chat's.
    function teamTag(text) {
        if (Nav.moduleView === root.view)
            return root.server === "linear" ? Linear.team : "";
        const m = root._mention(text);
        if (m?.server !== "linear" || m.rest === "")
            return "";
        return Linear.parse(m.rest).team ?? "";
    }

    function mentions(text) {
        const m = root._mention(text);
        if (!m)
            return [];

        // `@`, `@li`: the servers that name could still become.
        if (m.rest.trim() === "") {
            const name = m.name.toLowerCase();
            return Object.keys(root.servers).filter(id => id.startsWith(name) || root.aliases[name] === id).map(id => root._askRow(id, "", root.servers[id], `@${id} <message>`));
        }
        if (m.server === "")
            return [];
        if (m.server !== "linear")
            return [root._askRow(m.server, m.rest.trim(), `Ask ${root.servers[m.server]}`, m.rest.trim())];

        const p = Linear.parse(m.rest);
        if (p.picking)
            return Linear.teamItems(p.token, m.name);
        if (p.team === null)
            return [];
        if (p.text === "")
            return [root._askRow("linear", "", "Linear", `${p.team} · type a task or question`, p.team)];
        return [
            {
                id: "linear-task",
                name: `Add task to ${p.team}`,
                subtitle: p.text,
                icon: "",
                keywords: [],
                kind: "linear-task",
                frecency: false,
                activate: () => Linear.create(p.team, p.text)
            },
            root._askRow("linear", p.text, "Ask Linear", p.text, p.team)
        ];
    }

    function _askRow(server, message, name, subtitle, team) {
        return {
            id: "mcp:" + server,
            name: name,
            subtitle: subtitle,
            icon: "",
            keywords: [],
            kind: "module",
            frecency: false,
            activate: () => root.start(server, message, team)
        };
    }

    function start(server, message, team) {
        root._gen += 1;
        if (root._proc)
            root._proc.running = false;
        root.server = server;
        if (team)
            Linear.team = team;
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
            command: ["pathway-mcp", root.server, root.sessionId || "-", message, root.server === "linear" ? Linear.context : ""],
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

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The Linear side of `@linear`: picking a team with `#`, quick-add through
// `pathway-linear` (modules/nixos/quickshell/pathway-linear.nix), and the team
// an open chat is told about.
//
//   @linear #grow Fix bug    team by key or name prefix
//   @linear #3 Fix bug       team by its number in the `#` list
Singleton {
    id: root

    readonly property string defaultTeam: "BIR"

    // The open chat's team.
    property string team: root.defaultTeam
    // Each { key, name }, sorted by key - the order the `#` numbers refer to.
    property var teams: []

    readonly property string context: `The user's selected Linear team is ${root.team}. Use it whenever a team is needed and they do not name another.`

    // On every Pathway open, so `#grow` resolves without waiting on a fetch.
    function reset() {
        root.team = root.defaultTeam;
        if (root.teams.length === 0 && !teamsProc.running)
            teamsProc.running = true;
    }

    function create(team, title) {
        Quickshell.execDetached(["pathway-linear", "create", team, title]);
    }

    function teamFor(token) {
        const q = token.toLowerCase();
        if (q === "")
            return null;
        if (/^\d+$/.test(q))
            return root.teams[Number(q) - 1] ?? null;
        return root.teams.find(t => t.key.toLowerCase() === q) ?? root.teams.find(t => t.key.toLowerCase().startsWith(q) || t.name.toLowerCase().startsWith(q)) ?? null;
    }

    // `rest` is whatever follows the mention. While the `#token` is still being
    // typed (nothing after it yet) this is a pick; afterwards the token is
    // resolved and stripped. `team` is null for a token that matches nothing.
    function parse(rest) {
        const s = rest.replace(/^\s+/, "");
        const m = s.match(/^#(\S*)(\s[\s\S]*)?$/);
        if (!m)
            return {
                picking: false,
                team: root.defaultTeam,
                text: s.trim()
            };
        const team = root.teamFor(m[1])?.key ?? null;
        return {
            picking: m[2] === undefined,
            token: m[1],
            team: m[2] === undefined ? (team ?? root.defaultTeam) : team,
            text: (m[2] ?? "").trim()
        };
    }

    // The numbered `#` list. Picking a team writes its key into the query, so
    // what you see in the field is what the task will use.
    function teamItems(token, mention) {
        const q = token.toLowerCase();
        const items = [];
        root.teams.forEach((t, i) => {
            const n = String(i + 1);
            if (q !== "" && n !== q && !t.key.toLowerCase().startsWith(q) && !t.name.toLowerCase().startsWith(q))
                return;
            items.push({
                id: "linear-team:" + t.key,
                name: `${n}   ${t.name}`,
                subtitle: t.key === root.defaultTeam ? `${t.key} · Default` : t.key,
                icon: "",
                keywords: [],
                kind: "module",
                frecency: false,
                activate: () => Nav.setQuery(`@${mention} #${t.key} `)
            });
        });
        return items;
    }

    Process {
        id: teamsProc

        command: ["pathway-linear", "teams"]
        stdout: StdioCollector {
            id: teamsOut
        }
        onExited: {
            try {
                root.teams = JSON.parse(teamsOut.text);
            } catch (e) {
                root.teams = [];
            }
        }
    }
}

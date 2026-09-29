pragma Singleton

import Quickshell
import qs.Common

// The SUPER+A agent picker: every live agent session as a row - project, state
// and how long it has been in it, the tmux session, and the last thing you
// asked it - with Enter jumping to its terminal and pane.
//
// Not registered in Search.qml's global list: agents are only reached through
// their own scope, so searching for an app never turns up a session.
Singleton {
    id: root

    readonly property var items: Agents.sessions.map(s => {
        const where = s.tmux?.session ? `tmux:${s.tmux.session}` : "";
        const detail = [`${s.state} ${Agents.age(s)}`, where, s.prompt ?? ""].filter(p => p !== "");
        return {
            id: `agent:${s.id}`,
            name: Agents.project(s),
            subtitle: detail.join(" · "),
            icon: "",
            keywords: [s.cwd ?? "", s.tmux?.session ?? "", s.prompt ?? "", s.state],
            kind: `agent-${s.state}`,
            // Sessions are ephemeral, so a frecency score would outlive them.
            frecency: false,
            activate: () => Agents.jump(s.id)
        };
    })
}

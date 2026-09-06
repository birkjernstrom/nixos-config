import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

// Centre slot: how the agent fleet is doing, as counts.
//
// The bar's two ends report the machine; the middle reports the work. It is
// deliberately a tally rather than a chip per agent - a chip row grows with the
// fleet and turns the centre of the screen into a list to read, where a count
// answers the only question being asked in passing: is anything waiting for me?
// Which agent, and in which workspace, is the tooltip's job.
//
// A counter for a state nobody is in is not shown, so the common case (one
// agent, working) is three characters wide, and the module disappears entirely
// when there is nothing to say.
BarItem {
    id: root

    // Idle agents are running but neither busy nor waiting - they are sitting
    // at a prompt you have already seen. They are listed in the tooltip and get
    // no counter, which is what lets the centre of the bar go quiet.
    readonly property bool anything: Herdr.working + Herdr.blocked + Herdr.done > 0

    // Where a click goes: the most urgent agent, by the same ordering the
    // counters are laid out in. Clicking a summary that says something is
    // blocked should land you on the thing that is blocked.
    readonly property var target: {
        for (const status of ["blocked", "done", "working"]) {
            for (const agent of Herdr.agents) {
                if (agent.status === status)
                    return agent;
            }
        }
        return null;
    }

    // The title herdr is configured to write, in dotfiles/herdr/config.toml.
    // Matching on it is how the herdr window is told apart from every other
    // ghostty on the machine - it has no class of its own, being just a
    // terminal someone typed `herdr` into.
    //
    // The trailing `.*` is not decoration: hyprland matches a window selector
    // against the whole title, so an unterminated prefix finds nothing. And the
    // marker is "herdr · " rather than "herdr" because a shell sitting on
    // `herdr status` would title its window that too.
    readonly property string windowMatch: "title:^herdr · .*"

    visible: root.anything
    interactive: root.target !== null

    // Getting to a blocked agent takes two moves, and neither is enough alone:
    // herdr has to select the pane inside its own session, and hyprland has to
    // put the window that session is drawn in on screen. Order matters only in
    // that herdr should already be showing the right pane by the time the
    // window is raised.
    onClicked: {
        if (!root.target)
            return;
        Herdr.focus(root.target.paneId);
        Hyprland.dispatch(`hl.dsp.focus({ window = "${root.windowMatch}" })`);
    }

    tooltip: {
        if (Herdr.agents.length === 0)
            return "";
        // Every agent, including the idle ones the counters leave out - the
        // tooltip is where "what is actually running" gets answered.
        //
        // One line each, and deliberately not the task title: Herdr.agents
        // carries it, but a second indented line per agent doubles the height
        // of a popup that exists to be read in passing.
        return Herdr.agents.map(agent => `${agent.workspace} — ${agent.agent} · ${agent.status}`).join("\n");
    }

    RowLayout {
        spacing: 10

        Repeater {
            // Ordered by how much each state wants you: what is waiting first,
            // what has finished next, what is still running last.
            model: [
                {
                    status: "blocked",
                    glyph: Icons.agentBlocked,
                    count: Herdr.blocked,
                    color: Theme.warning
                },
                {
                    status: "done",
                    glyph: Icons.agentDone,
                    count: Herdr.done,
                    color: Theme.accent
                },
                {
                    status: "working",
                    glyph: Icons.agentWorking,
                    count: Herdr.working,
                    color: Theme.fgDim
                }
            ]

            RowLayout {
                id: counter

                required property var modelData

                spacing: 4
                visible: counter.modelData.count > 0

                Icon {
                    Layout.alignment: Qt.AlignVCenter

                    glyph: counter.modelData.glyph
                    color: counter.modelData.color
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter

                    text: String(counter.modelData.count)
                    color: counter.modelData.color
                }
            }
        }
    }
}

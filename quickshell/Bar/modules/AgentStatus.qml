import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets

// Right slot: how many coding agents are open, in one glyph and a count. The
// glyph and colour carry the most urgent state across all of them - something
// waiting on you, else something working, else all idle - so a glance says
// whether to look. Clicking opens the SUPER+A picker.
BarItem {
    id: root

    // No agents is the ordinary state of a machine not doing agent work.
    visible: Agents.total > 0

    interactive: true

    readonly property color tint: {
        if (Agents.overall === "waiting")
            return Theme.agentWaiting;
        if (Agents.overall === "working")
            return Theme.agentWorking;
        return Theme.agentIdle;
    }

    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "pathway", "agents"])

    tooltip: {
        const parts = [];
        if (Agents.waiting > 0)
            parts.push(`${Agents.waiting} waiting`);
        if (Agents.working > 0)
            parts.push(`${Agents.working} working`);
        if (Agents.idle > 0)
            parts.push(`${Agents.idle} idle`);
        return parts.join(" · ");
    }

    RowLayout {
        spacing: 2

        Icon {
            Layout.alignment: Qt.AlignVCenter
            glyph: Icons.agent(Agents.overall)
            color: root.tint
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2
            text: Agents.total
            color: root.tint
        }
    }
}

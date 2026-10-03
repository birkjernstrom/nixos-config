pragma Singleton

import Quickshell

// The glyph vocabulary of the shell. Nothing outside this file names a
// codepoint, and nothing inside it knows how big a glyph will be drawn - that
// is Widgets/Icon.qml's job, from the measurements in IconMetrics.
//
// Two rules govern what may be added here:
//
//   1. A ramp's frames must be the same drawing at different fills. MDI's
//      battery-charging-* set is a different drawing at two thirds the scale of
//      battery-*, so plugging in the charger used to visibly resize the icon;
//      charging now rides alongside as its own bolt instead of forking the ramp.
//   2. Every new glyph needs a re-run of tools/gen-icon-metrics.sh. Icon.qml
//      falls back to treating an unmeasured glyph as filling its cell, which is
//      the mismatched behaviour this all exists to avoid.
Singleton {
    id: root

    // MDI's upright battery, empty outline through full in tenths. All eleven
    // frames share one ink box, so the icon holds perfectly still as the level
    // drops.
    readonly property var batteryRamp: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    // Shown beside the battery while it charges - see rule 1 above. Drawn small
    // by Battery.qml: it annotates the battery, it is not a peer of it.
    readonly property string batteryCharging: ""
    // UPower reports Unknown for a moment after every shell restart. The
    // question mark keeps it from being mistaken for a level.
    readonly property string batteryUnknown: "󰂑"

    readonly property var wifiRamp: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    readonly property string wifiDisconnected: "󰤮"
    readonly property string wifiDisabled: "󰤮"
    readonly property string ethernet: "󰀂"

    readonly property var volumeRamp: ["󰕿", "󰖀", "󰕾"]
    readonly property string volumeMuted: "󰝟"
    readonly property string headphone: "󰋋"
    readonly property string headset: "󰋎"

    readonly property string bluetooth: "󰂯"
    readonly property string bluetoothConnected: "󰂱"
    readonly property string bluetoothOff: "󰂲"

    // Tailscale, as one shield at three fills: off, on, and on-through-an-exit
    // node. Same reasoning as the agent set above - the silhouette is the
    // constant, so the interior is what gets read at a glance.
    readonly property string tailscale: "󰦝"
    readonly property string tailscaleExitNode: "󰰜"
    readonly property string tailscaleOff: "󰨛"

    // Agent states (Agents.qml). One silhouette, three interiors: the circle
    // is the constant, so a glance reads the interior as a status rather than
    // re-reading three unrelated shapes. All three measure 600x600, so the
    // count beside them sits on the same line whichever is showing.
    readonly property string agentWorking: "󰪡"
    readonly property string agentWaiting: "󰀨"
    readonly property string agentIdle: "󰗠"

    function agent(state) {
        if (state === "waiting")
            return root.agentWaiting;
        if (state === "working")
            return root.agentWorking;
        return root.agentIdle;
    }

    readonly property string search: "󰍉"
    readonly property string app: "󰣆"
    readonly property string clipboard: "󰆒"
    readonly property string image: "󰋩"
    readonly property string chevronRight: "󰅂"
    readonly property string theme: "󰏘"
    readonly property string chat: "󰍪"

    // percent: 0-100. The last frame means full.
    function battery(percent) {
        return root.batteryRamp[root._rampIndex(percent, root.batteryRamp.length)];
    }

    // percent: 0-100. Unlike the ramps above the last entry is not a special
    // "full" case - anything from two thirds up is the same loudspeaker glyph.
    function volume(percent) {
        return root.volumeRamp[root._rampIndex(percent, root.volumeRamp.length)];
    }

    // strength: 0-100 as reported by WifiNetwork.signalStrength.
    function wifi(strength) {
        return root.wifiRamp[root._rampIndex(strength, root.wifiRamp.length)];
    }

    function _rampIndex(percent, length) {
        if (!isFinite(percent))
            return 0;
        const i = Math.floor((Math.max(0, Math.min(100, percent)) / 100) * length);
        // 100% would land one past the end.
        return Math.min(i, length - 1);
    }
}

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

    // Font Awesome's horizontal battery rather than MDI's upright one. At bar
    // height an upright battery is a 17px column of ink that towers over every
    // other module; the horizontal one reads as a battery at a glance and sits
    // in the same visual band as the text beside it. All five frames share one
    // ink box, so the icon holds perfectly still as the level drops.
    readonly property var batteryRamp: ["", "", "", "", ""]
    // Shown beside the battery while it charges - see rule 1 above. Drawn small
    // by Battery.qml: it annotates the battery, it is not a peer of it.
    readonly property string batteryCharging: ""
    // UPower reports Unknown for a moment after every shell restart. MDI's
    // upright battery breaks the horizontal set, which is the point - it is not
    // a level, and it should not be mistaken for one.
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

    // herdr agent states. One silhouette, three interiors: the circle is the
    // constant, so a glance at the bar's centre reads the interiors as a status
    // rather than re-reading three unrelated shapes. All three measure 600x600,
    // so the counters sit on exactly the same line.
    readonly property string agentWorking: "󰪡"
    readonly property string agentBlocked: "󰀨"
    readonly property string agentDone: "󰗠"

    readonly property string search: "󰍉"
    readonly property string app: "󰣆"
    readonly property string clipboard: "󰆒"
    readonly property string image: "󰋩"
    readonly property string chevronRight: "󰅂"
    readonly property string theme: "󰏘"

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

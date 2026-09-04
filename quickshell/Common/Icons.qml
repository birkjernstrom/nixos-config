pragma Singleton

import Quickshell

// Nerd Font glyph ramps, ported verbatim from the format-icons arrays in
// modules/nixos/waybar.nix so the new bar reads identically to the old one.
// These only render in Theme.fontIcon (the patched Nerd Font family).
Singleton {
    id: root

    readonly property var batteryRamp: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property var batteryChargingRamp: ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    readonly property string batteryFull: "󰂅"
    readonly property string batteryUnknown: "󰂑"

    readonly property var wifiRamp: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    readonly property string wifiDisconnected: "󰤮"
    readonly property string wifiDisabled: "󰤮"
    readonly property string ethernet: "󰀂"

    readonly property string search: "󰍉"
    readonly property string app: "󰣆"
    readonly property string clipboard: "󰆒"
    readonly property string image: "󰋩"
    readonly property string chevronRight: "󰅂"

    // percent: 0-100. Picks from a ramp whose last entry means "full".
    function battery(percent, charging) {
        const ramp = charging ? root.batteryChargingRamp : root.batteryRamp;
        return ramp[root._rampIndex(percent, ramp.length)];
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

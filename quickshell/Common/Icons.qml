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

    readonly property var volumeRamp: ["󰕿", "󰖀", "󰕾"]
    readonly property string volumeMuted: "󰝟"
    readonly property string headphone: "󰋋"
    readonly property string headset: "󰋎"

    readonly property string bluetooth: "󰂯"
    readonly property string bluetoothConnected: "󰂱"
    readonly property string bluetoothOff: "󰂲"

    readonly property string search: "󰍉"
    readonly property string app: "󰣆"
    readonly property string clipboard: "󰆒"
    readonly property string image: "󰋩"
    readonly property string chevronRight: "󰅂"
    readonly property string theme: "󰏘"

    // percent: 0-100. Picks from a ramp whose last entry means "full".
    function battery(percent, charging) {
        const ramp = charging ? root.batteryChargingRamp : root.batteryRamp;
        return ramp[root._rampIndex(percent, ramp.length)];
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

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Common
import qs.Widgets

// Right slot: the icon carries the level on its own, and the percentage only
// appears once it is low enough to be worth acting on.
//
// Clicking opens a terminal on powerprofilesctl - not a TuiWindow pane like
// wifi/bluetooth's, since `list` alone would print once and flash shut; this
// drops into an interactive shell afterwards so the output stays readable and
// `pwr set ...` (see modules/shared/zsh.nix) is one command away.
BarItem {
    id: root

    interactive: true

    onClicked: powerTerm.toggle()

    Process {
        id: powerTerm

        command: ["ghostty", "--class=sh.pathway.tui.powerprofiles", "--title=powerprofilesctl", "--confirm-close-surface=false", "-e", "zsh", "-ic", "powerprofilesctl list; exec zsh"]

        function toggle(): void {
            running = !running;
        }
    }

    readonly property UPowerDevice device: UPower.displayDevice

    // A desktop still reports a display device, so isPresent alone is not enough
    // to tell one apart from a laptop.
    readonly property bool present: root.device !== null && root.device.isPresent && root.device.isLaptopBattery

    // Just after startup the device exists but has no reading yet; treating that
    // as 0% would flash a critical-red battery on every shell restart.
    readonly property bool known: root.present && root.device.state !== UPowerDeviceState.Unknown

    readonly property bool charging: root.known && (root.device.state === UPowerDeviceState.Charging || root.device.state === UPowerDeviceState.FullyCharged || root.device.state === UPowerDeviceState.PendingCharge)
    // UPower reports percentage as a 0-1 fraction here, not 0-100 (verified:
    // 0.79 while upower-cli said 79%). Icons.battery and the label both want 0-100.
    readonly property real percent: root.present ? root.device.percentage * 100 : 0
    readonly property bool low: root.known && !root.charging && root.percent < 20

    readonly property color tint: {
        if (root.charging)
            return Theme.batteryCharging;
        if (!root.low)
            return Theme.fgDim;
        return root.percent < 10 ? Theme.critical : Theme.warning;
    }

    visible: root.present

    // "power-saver" -> "Power saver", to match the profile names
    // `powerprofilesctl` itself prints.
    readonly property string profileLabel: {
        if (!PowerProfiles.available)
            return "";
        const words = PowerProfiles.profile.split("-");
        return words.map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
    }

    tooltip: {
        if (!root.known)
            return "";
        const rate = `${Math.round(Math.abs(root.device.changeRate))}W${root.charging ? "↑" : "↓"} ${Math.round(root.percent)}%`;
        const left = root.formatDuration(root.charging ? root.device.timeToFull : root.device.timeToEmpty);
        const base = left === "" ? rate : `${rate} · ${left}`;
        return root.profileLabel === "" ? base : `${base} · ${root.profileLabel}`;
    }

    RowLayout {
        spacing: 2

        Icon {
            Layout.alignment: Qt.AlignVCenter

            glyph: root.known ? Icons.battery(root.percent) : Icons.batteryUnknown
            color: root.tint
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2

            visible: root.known && root.percent < 20
            text: `${Math.round(root.percent)}%`
            color: root.tint
        }
    }

    // seconds -> "2h 15m". Empty when UPower has no estimate yet.
    function formatDuration(seconds: real): string {
        if (!isFinite(seconds) || seconds <= 0)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
    }
}

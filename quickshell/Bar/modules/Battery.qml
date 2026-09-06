import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.Common
import qs.Widgets

// Right slot: the icon carries the level on its own, and the percentage only
// appears once it is low enough to be worth acting on.
BarItem {
    id: root

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

    // waybar excluded the charging state from both colour rules
    // (:not(.charging)) - a draining-looking level on the cable is not a warning.
    readonly property color tint: {
        if (!root.low)
            return Theme.fgDim;
        return root.percent < 10 ? Theme.critical : Theme.warning;
    }

    visible: root.present

    tooltip: {
        if (!root.known)
            return "";
        const rate = `${Math.round(Math.abs(root.device.changeRate))}W${root.charging ? "↑" : "↓"} ${Math.round(root.percent)}%`;
        const left = root.formatDuration(root.charging ? root.device.timeToFull : root.device.timeToEmpty);
        return left === "" ? rate : `${rate} · ${left}`;
    }

    RowLayout {
        spacing: 2

        // Charging is its own mark rather than a second ramp, so the battery
        // itself never changes drawing - only what is beside it. Drawn at two
        // thirds because it annotates the battery: at full size a bolt is a
        // taller, heavier shape than the battery it is meant to qualify.
        Icon {
            Layout.alignment: Qt.AlignVCenter

            visible: root.charging
            glyph: Icons.batteryCharging
            size: Math.round(Theme.iconSize * 0.66)
            color: root.tint
        }

        Icon {
            Layout.alignment: Qt.AlignVCenter

            glyph: root.known ? Icons.battery(root.percent) : Icons.batteryUnknown
            color: root.tint
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2

            // Shown on the level, not on the warning: a charging battery below
            // 20% is not tinted, but the number is still what you want to see.
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

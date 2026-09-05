import QtQuick
import Quickshell.Bluetooth
import qs.Common
import qs.Widgets

// Right slot: adapter state as a single glyph, with the connected devices in
// the tooltip - the same three-state icon waybar showed (off, on, connected).
BarItem {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: root.adapter?.enabled ?? false

    // Walked on every evaluation rather than cached from a signal handler:
    // reading `connected` inside the binding is what subscribes us to it, so a
    // device pairing or dropping repaints on its own.
    readonly property var connectedDevices: {
        const out = [];
        const devices = Bluetooth.devices ? Bluetooth.devices.values : null;
        if (!devices)
            return out;
        for (const device of devices) {
            if (device && device.connected)
                out.push(device);
        }
        return out;
    }

    // A machine with no bluetooth radio reports no adapter at all; nothing to
    // show rather than a permanently struck-through icon.
    visible: root.adapter !== null

    tooltip: {
        if (!root.adapter)
            return "";
        if (!root.enabled)
            return `${root.adapter.name} — off`;
        if (root.connectedDevices.length === 0)
            return `${root.adapter.name} — on`;
        // battery is a 0-1 fraction, and is only meaningful once the device has
        // actually reported one.
        const names = root.connectedDevices.map(device => {
            const label = device.name === "" ? device.address : device.name;
            return device.batteryAvailable ? `${label} ${Math.round(device.battery * 100)}%` : label;
        });
        return `${root.adapter.name}\n${names.join("\n")}`;
    }

    StyledText {
        icon: true
        text: {
            if (!root.enabled)
                return Icons.bluetoothOff;
            return root.connectedDevices.length > 0 ? Icons.bluetoothConnected : Icons.bluetooth;
        }
        color: Theme.fgDim
        // waybar: #bluetooth.off, #bluetooth.disabled { opacity: 0.5 }
        opacity: root.enabled ? 1.0 : 0.5
    }
}

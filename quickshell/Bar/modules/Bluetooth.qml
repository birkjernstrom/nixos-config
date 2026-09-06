import QtQuick
import Quickshell.Bluetooth
import qs.Common
import qs.Widgets

// Right slot: adapter state as a single glyph, with the connected devices in
// the tooltip - the same three-state icon waybar showed (off, on, connected).
//
// Clicking opens bluetui, which is to bluez what impala (on the wifi module) is
// to iwd: same author, same shape of TUI, so the two panes the bar can open
// behave the same way.
BarItem {
    id: root

    interactive: true

    onClicked: bluetui.toggle()

    TuiWindow {
        id: bluetui

        program: "bluetui"
        appId: "sh.pathway.tui.bluetui"
    }

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

    Icon {
        glyph: {
            if (!root.enabled)
                return Icons.bluetoothOff;
            return root.connectedDevices.length > 0 ? Icons.bluetoothConnected : Icons.bluetooth;
        }
        // waybar: #bluetooth.off, #bluetooth.disabled { opacity: 0.5 }
        opacity: root.enabled ? 1.0 : 0.5
    }
}

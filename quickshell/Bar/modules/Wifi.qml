import QtQuick
import Quickshell.Networking
import qs.Common
import qs.Widgets

// Right slot: connectivity as a single glyph. The SSID stays in the tooltip -
// a text label here would change width on every roam and pull the eye.
BarItem {
    id: root

    tooltip: {
        if (net.wiredDevice)
            return net.wiredDevice.name;
        if (net.wifiNetwork)
            return net.wifiNetwork.name + " — " + net.strength + "%";
        return "Disconnected";
    }

    QtObject {
        id: net

        // Walked on every evaluation rather than cached from a signal handler:
        // touching the nested properties inside the binding is what subscribes
        // us to them, so signalStrength changes repaint on their own.
        readonly property var wiredDevice: {
            const devices = Networking.devices ? Networking.devices.values : null;
            if (!devices)
                return null;
            for (const device of devices) {
                if (device && device.type === DeviceType.Wired && device.connected)
                    return device;
            }
            return null;
        }

        readonly property var wifiNetwork: {
            const devices = Networking.devices ? Networking.devices.values : null;
            if (!devices)
                return null;
            for (const device of devices) {
                // networks is null while a device is still initialising.
                if (!device || device.type !== DeviceType.Wifi || !device.networks)
                    continue;
                for (const network of device.networks.values) {
                    if (network && network.connected)
                        return network;
                }
            }
            return null;
        }

        // signalStrength is a 0-1 fraction (verified: 0.69 while nmcli said 69),
        // but Icons.wifi() ramps over 0-100.
        readonly property int strength: net.wifiNetwork ? Math.round(net.wifiNetwork.signalStrength * 100) : 0
        readonly property bool connected: net.wiredDevice !== null || net.wifiNetwork !== null

        readonly property string glyph: {
            if (net.wiredDevice)
                return Icons.ethernet;
            if (net.wifiNetwork)
                return Icons.wifi(net.strength);
            return Networking.wifiEnabled ? Icons.wifiDisconnected : Icons.wifiDisabled;
        }
    }

    StyledText {
        icon: true
        text: net.glyph
        color: Theme.fgDim
        // waybar: #network.disconnected { opacity: 0.5 }
        opacity: net.connected ? 1.0 : 0.5
    }
}

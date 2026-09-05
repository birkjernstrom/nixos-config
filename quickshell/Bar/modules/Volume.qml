import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Common
import qs.Widgets

// Right slot: the default sink's level. Unlike battery and wifi the glyph ramp
// is only three steps wide, so the number stays on the bar - scrolling to set a
// level needs feedback finer than "somewhere above two thirds".
//
// waybar reached pavucontrol on click; here the wheel and a mute toggle cover
// what that dialog was actually opened for.
BarItem {
    id: root

    // One wheel notch. 5% keeps a full sweep at a reasonable number of scrolls
    // while still landing on round numbers.
    readonly property real step: 0.05

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNodeAudio audio: root.sink?.audio ?? null

    readonly property bool muted: root.audio?.muted ?? false
    // volume is a 0-1 fraction averaged over the channels.
    readonly property int percent: root.audio ? Math.round(root.audio.volume * 100) : 0

    // Ported from waybar's format-icons, which named a headphone and a headset
    // case separately. PipeWire does not label those directly - the sink node
    // carries the freedesktop icon name its device was probed as.
    readonly property string iconName: root.sink?.properties?.["device.icon-name"] ?? ""

    interactive: true
    visible: root.audio !== null

    tooltip: {
        if (!root.sink)
            return "";
        const level = root.muted ? "muted" : `${root.percent}%`;
        return `${root.sink.description} — ${level}`;
    }

    // Nodes are only kept alive - and their audio properties populated - while
    // something holds them bound. Without this the level never updates.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    onClicked: {
        if (root.audio)
            root.audio.muted = !root.audio.muted;
    }

    onWheel: delta => {
        if (!root.audio)
            return;
        // Scrolling an audible level is meant to adjust it, not to unmute
        // something that was deliberately silenced.
        if (root.muted)
            return;
        const next = root.audio.volume + (delta > 0 ? root.step : -root.step);
        root.audio.volume = Math.max(0, Math.min(1, next));
    }

    RowLayout {
        spacing: 4

        StyledText {
            Layout.alignment: Qt.AlignVCenter

            icon: true
            text: {
                if (root.muted)
                    return Icons.volumeMuted;
                if (root.iconName.includes("headset"))
                    return Icons.headset;
                if (root.iconName.includes("headphone"))
                    return Icons.headphone;
                return Icons.volume(root.percent);
            }
            color: Theme.fgDim
            // waybar: #pulseaudio.muted { opacity: 0.5 }
            opacity: root.muted ? 0.5 : 1.0
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter

            text: `${root.percent}%`
            color: Theme.fgDim
            opacity: root.muted ? 0.5 : 1.0
        }
    }
}

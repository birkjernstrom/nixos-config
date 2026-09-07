import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Common
import qs.Widgets

// Right slot: the default sink's level, as a glyph and nothing else.
//
// The number used to live on the bar so that scrolling had feedback finer than
// "somewhere above two thirds", but it was on screen permanently to serve the
// few seconds a week anyone spends adjusting it - and the exact percentage of
// the system volume is not a thing worth a permanent slot. The tooltip carries
// it instead, and since setting the level means hovering the module anyway, it
// is on screen at the one moment it is wanted.
//
// waybar reached pavucontrol on click; here the wheel and a mute toggle cover
// what that dialog was actually opened for.
//
// Above 100% the glyph alone stops being honest. MDI gives three loudspeakers
// and no more, so every level from two thirds up already draws the same frame -
// and PipeWire will happily amplify past unity, where the same frame then also
// means "this is being boosted in software and may clip". That case borrows the
// battery module's treatment: tint the icon and put the number beside it, so
// the one range the ramp cannot describe is the one range that is spelled out.
BarItem {
    id: root

    // One wheel notch. 5% keeps a full sweep at a reasonable number of scrolls
    // while still landing on round numbers.
    readonly property real step: 0.05
    // The wheel used to stop at unity while the XF86AudioRaiseVolume binding
    // (wpctl set-volume, which takes no limit) went past it, so the bar could
    // not reach - or undo - a level the keyboard could set. Both now share this
    // ceiling. 150% is where PipeWire's own tooling tends to cap.
    readonly property real maxVolume: 1.5

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNodeAudio audio: root.sink?.audio ?? null

    readonly property bool muted: root.audio?.muted ?? false
    // volume is a fraction averaged over the channels. It is only 0-1 by
    // convention: anything above unity is software gain.
    readonly property int percent: root.audio ? Math.round(root.audio.volume * 100) : 0
    readonly property bool amplified: !root.muted && root.percent > 100

    // Same three states the battery uses, for the same reason: the tint is the
    // warning, so the glyph underneath never has to change drawing to carry one.
    readonly property color tint: root.amplified ? Theme.warning : Theme.fgDim

    // Ported from waybar's format-icons, which named a headphone and a headset
    // case separately. PipeWire does not label those directly - the sink node
    // carries the freedesktop icon name its device was probed as.
    readonly property string iconName: root.sink?.properties?.["device.icon-name"] ?? ""

    interactive: true
    visible: root.audio !== null

    tooltip: {
        if (!root.sink)
            return "";
        const level = root.muted ? "muted" : `${root.percent}%${root.amplified ? " — amplified" : ""}`;
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
        root.audio.volume = Math.max(0, Math.min(root.maxVolume, next));
    }

    RowLayout {
        spacing: 2

        Icon {
            Layout.alignment: Qt.AlignVCenter

            glyph: {
                if (root.muted)
                    return Icons.volumeMuted;
                if (root.iconName.includes("headset"))
                    return Icons.headset;
                if (root.iconName.includes("headphone"))
                    return Icons.headphone;
                return Icons.volume(root.percent);
            }
            color: root.tint
            // waybar: #pulseaudio.muted { opacity: 0.5 }
            opacity: root.muted ? 0.5 : 1.0
        }

        // Only while boosted. The permanent percentage was removed from this
        // module deliberately - see above - and this does not bring it back:
        // it appears for the range the glyph cannot distinguish, and goes away
        // again the moment the level returns to something the ramp can draw.
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2

            visible: root.amplified
            text: `${root.percent}%`
            color: root.tint
        }
    }
}

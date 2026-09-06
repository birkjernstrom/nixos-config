import QtQuick
import qs.Common

// One Nerd Font glyph, drawn to a common box.
//
// The bar's glyphs come from icon sets that were never drawn to a shared grid.
// The Mono patch of a Nerd Font caps every glyph at one cell width but lets tall
// ones overflow vertically, so at a single font size MDI's bluetooth rune is 944
// font units tall next to a 476-unit wifi fan and a 334-unit battery. Setting a
// font size and hoping is what made the bar look assembled from spare parts.
//
// So: scale each glyph so its longest side is exactly `size`, and put the centre
// of its ink on the centre of the box. Nothing towers, nothing rides high or
// low, and a wide glyph stays wide rather than being stretched to match a tall
// one's height. Measurements come from IconMetrics, which tools/gen-icon-metrics.sh
// extracts from the font itself - there are no hand-tuned numbers here.
//
// The box is square and fixed, which also stops a module changing width as its
// glyph changes. The volume ramp is the reason that matters: MDI draws its three
// frames at wildly different scales, so the module used to twitch on every
// scroll notch.
Item {
    id: root

    required property string glyph
    property color color: Theme.fgDim
    property int size: Theme.iconSize

    readonly property var ink: IconMetrics.ink[root.glyph] ?? IconMetrics.fallback

    implicitWidth: root.size
    implicitHeight: root.size

    Text {
        id: label

        // Ink units are per 1000 em, so this is the font size at which the
        // glyph's longest side measures exactly `size` pixels.
        readonly property int px: Math.round(root.size * 1000 / Math.max(root.ink.w, root.ink.h))

        text: root.glyph
        color: root.color
        font.family: Theme.fontIcon
        font.pixelSize: label.px
        renderType: Text.NativeRendering

        // The ink centre sits `cx` right of and `cy` above the pen origin, which
        // is this Text's left edge and its baseline. baselineOffset gives where
        // that baseline falls from the top, so both lines below read "put the
        // ink centre where the box centre is".
        x: Math.round(root.width / 2 - label.px * root.ink.cx / 1000)
        y: Math.round(root.height / 2 - (label.baselineOffset - label.px * root.ink.cy / 1000))
    }
}

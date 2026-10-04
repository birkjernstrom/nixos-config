pragma Singleton

import QtQuick
import Quickshell

// Semantic design tokens. Everything else in the shell reads from here, so no
// other file ever mentions a raw base16 slot.
//
// Slots come from Themes, which resolves them against whichever palette is
// selected - so switching a theme re-evaluates every binding below and restyles
// the shell live. Fonts come from Typography and are theme-independent.
Singleton {
    id: root

    readonly property color bg: Themes.base00        // bar background
    readonly property color bgAlt: Themes.base01      // pathway card
    readonly property color bgHover: Themes.base02
    readonly property color border: Themes.base02

    readonly property color fg: Themes.base05
    readonly property color fgDim: Themes.base03      // waybar's idle module colour
    readonly property color fgSubtle: Themes.base04

    readonly property color accent: Themes.base0E     // selection, tooltip border
    readonly property color onAccent: Themes.base00
    readonly property color warning: Themes.base0A    // battery < 20%
    readonly property color critical: Themes.base08    // battery < 10%, urgent workspace

    // The outline/label tint for a workspace shown active on the *other*
    // screen (Workspaces.qml's `elsewhere` case) - base0B is the darkest of
    // the base16 accent slots that isn't already spoken for (base08 is
    // critical).
    readonly property color workspaceActive: Themes.base0B

    // Flat white rather than a palette slot, by request - the label color for
    // the active workspace pill on its own screen, which otherwise carries no
    // background of its own. White vanishes on a light bar, so light themes
    // use their text colour, the darkest they have.
    readonly property color workspaceActiveFg: Themes.light ? root.fg : "white"

    // Agent states (Agents.qml), for the bar module and the picker rows.
    // Waiting shares the warning slot on purpose: it is the one that wants you.
    readonly property color agentWorking: Themes.base0D
    readonly property color agentWaiting: Themes.base0A
    readonly property color agentIdle: Themes.base03   // same as fgDim

    // The first of the cool accents that stays legible on the card, else text.
    readonly property color chatLink: {
        for (const c of [Themes.base0D, Themes.base0C, Themes.base0E]) {
            if (root.contrast(c, root.bgAlt) >= 4.5)
                return c;
        }
        return root.fg;
    }

    function luminance(c: color): real {
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
    }

    function contrast(a: color, b: color): real {
        const la = root.luminance(a);
        const lb = root.luminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    readonly property int barHeight: 33
    readonly property int radius: 8
    readonly property int radiusLarge: 12
    readonly property int paddingH: 6         // waybar had 10px; tightened per-item padding
    readonly property int marginV: 4          // waybar: margin 4px 2px
    readonly property int marginH: 1          // waybar had 2px; tightened gap between items
    readonly property int edgeMargin: 8       // waybar: #workspaces margin-left / #battery margin-right

    readonly property string fontFamily: Typography.fontUi
    readonly property string fontMono: Typography.fontMono
    readonly property string fontIcon: Typography.fontIcon
    readonly property int fontSize: Typography.fontSize
    readonly property int fontSizeIcon: Typography.fontSize + 3

    // The box every bar glyph is scaled into - see Widgets/Icon.qml. A size, not
    // a font size: what a glyph's font size has to be to fill this depends on
    // the glyph, and only Icon.qml knows that.
    readonly property int iconSize: 15

    // Pathway card
    readonly property int pathwayWidth: 640
    readonly property int pathwayHeight: 400
    readonly property int pathwayRowHeight: 44
    readonly property int pathwayChatWidth: 780
    readonly property int pathwayChatHeight: 580
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.35)

    readonly property int animFast: 120
    readonly property int animNormal: 200
}

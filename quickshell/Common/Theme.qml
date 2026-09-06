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

    readonly property color accent: Themes.base0E     // active workspace pill
    readonly property color onAccent: Themes.base00
    readonly property color warning: Themes.base0A    // battery < 20%
    readonly property color critical: Themes.base08    // battery < 10%, urgent workspace

    // Geometry. barHeight matches the waybar it replaces so nothing reflows.
    readonly property int barHeight: 29
    readonly property int radius: 8
    readonly property int radiusLarge: 12
    readonly property int paddingH: 10        // waybar: padding 0 10px
    readonly property int marginV: 4          // waybar: margin 4px 2px
    readonly property int marginH: 2
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
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.35)

    readonly property int animFast: 120
    readonly property int animNormal: 200
}

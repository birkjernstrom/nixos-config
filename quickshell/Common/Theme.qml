pragma Singleton

import Quickshell

// Semantic design tokens. Everything else in the shell reads from here, so no
// other file ever mentions a raw base16 slot - reskinning is this file plus a
// regenerated Palette.qml.json.
//
// Palette is the singleton Quickshell synthesizes from Palette.qml.json. Its
// #rrggbb strings arrive already typed as `color`, so no conversion is needed.
Singleton {
    id: root

    readonly property color bg: Palette.colors.base00        // bar background
    readonly property color bgAlt: Palette.colors.base01      // pathway card
    readonly property color bgHover: Palette.colors.base02
    readonly property color border: Palette.colors.base02

    readonly property color fg: Palette.colors.base05
    readonly property color fgDim: Palette.colors.base03      // waybar's idle module colour
    readonly property color fgSubtle: Palette.colors.base04

    readonly property color accent: Palette.colors.base0E     // active workspace pill
    readonly property color onAccent: Palette.colors.base00
    readonly property color warning: Palette.colors.base0A    // battery < 20%
    readonly property color critical: Palette.colors.base08    // battery < 10%, urgent workspace

    // Geometry. barHeight matches the waybar it replaces so nothing reflows.
    readonly property int barHeight: 29
    readonly property int radius: 8
    readonly property int radiusLarge: 12
    readonly property int paddingH: 10        // waybar: padding 0 10px
    readonly property int marginV: 4          // waybar: margin 4px 2px
    readonly property int marginH: 2
    readonly property int edgeMargin: 8       // waybar: #workspaces margin-left / #battery margin-right

    readonly property string fontFamily: Palette.font.ui
    readonly property string fontMono: Palette.font.mono
    readonly property string fontIcon: Palette.font.icon
    readonly property int fontSize: Palette.font.size
    readonly property int fontSizeIcon: Palette.font.size + 3

    // Pathway card
    readonly property int pathwayWidth: 640
    readonly property int pathwayHeight: 400
    readonly property int pathwayRowHeight: 44
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.35)

    readonly property int animFast: 120
    readonly property int animNormal: 200
}

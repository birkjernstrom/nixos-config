import QtQuick
import qs.Common

// Text with the theme's UI font applied. Set `icon: true` for Nerd Font glyphs -
// they only render in the patched family, not in Inter.
Text {
    property bool icon: false

    color: Theme.fgDim
    font.family: icon ? Theme.fontIcon : Theme.fontFamily
    font.pointSize: icon ? Theme.fontSizeIcon : Theme.fontSize
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
}

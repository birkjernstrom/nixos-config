import QtQuick
import qs.Common
import qs.Widgets

BarItem {
    interactive: true

    onClicked: Caffeine.toggle()

    tooltip: Caffeine.active ? "Caffeinated — won't suspend when idle\nClick to allow suspend" : "Click to keep awake"

    Icon {
        // The saucer stretches the ink box downwards, leaving the cup itself riding high.
        offsetY: 1
        glyph: Caffeine.active ? Icons.caffeinated : Icons.decaffeinated
        color: Caffeine.active ? Theme.accent : Theme.fgDim
        opacity: Caffeine.active ? 1.0 : 0.5
    }
}

import QtQuick
import qs.Common
import qs.Widgets

BarItem {
    interactive: true

    onClicked: DoNotDisturb.toggle()

    tooltip: DoNotDisturb.active ? "Do not disturb — notifications hidden\nClick to show them" : "Click to hide notifications"

    Icon {
        glyph: DoNotDisturb.active ? Icons.bellOff : Icons.bell
        color: DoNotDisturb.active ? Theme.accent : Theme.fgDim
        opacity: DoNotDisturb.active ? 1.0 : 0.5
    }
}

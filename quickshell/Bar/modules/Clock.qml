import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

// Centre slot: just the time, with the full date on hover - waybar's format-alt
// without the click to get at it.
BarItem {
    id: root

    tooltip: Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy")

    // Minute precision: at Seconds this would wake once a second only to redraw
    // the same string 59 times out of 60.
    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    StyledText {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.fgDim
        font.bold: true
    }
}

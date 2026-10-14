import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets

// Far right: date then time, so the time sits at the very edge of the screen.
// The full date stays on hover - waybar's format-alt without the click to get
// at it.
BarItem {
    id: root

    tooltip: Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy")

    // Minute precision: at Seconds this would wake once a second only to redraw
    // the same string 59 times out of 60.
    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // The minute timer runs on the monotonic clock, which stops during suspend.
    Process {
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("PrepareForSleep (false")) {
                    clock.enabled = false;
                    clock.enabled = true;
                }
            }
        }
    }

    RowLayout {
        spacing: 6

        StyledText {
            Layout.alignment: Qt.AlignVCenter

            // "5 Sep" - no leading zero, month abbreviated.
            text: Qt.formatDateTime(clock.date, "d MMM")
            color: Theme.fgDim
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter

            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.fgDim
            // The only bold text on the bar: the time is what the eye goes to.
            font.bold: true
        }
    }
}

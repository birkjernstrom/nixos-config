import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

BarItem {
    id: root

    visible: Dictation.active
    interactive: Dictation.status === "recording"

    readonly property color tint: {
        if (Dictation.status === "recording" || Dictation.status === "error")
            return Theme.critical;
        return Theme.accent;
    }

    onClicked: Dictation.stop()
    onRightClicked: Dictation.cancel()

    tooltip: {
        if (Dictation.status === "recording")
            return "Dictating — click or SUPER+D to finish\nRight-click or SUPER+SHIFT+D to cancel";
        if (Dictation.status === "transcribing")
            return "Transcribing…";
        if (Dictation.status === "error")
            return Dictation.message;
        return "";
    }

    RowLayout {
        spacing: 2

        Icon {
            id: icon

            Layout.alignment: Qt.AlignVCenter
            glyph: Dictation.status === "error" ? Icons.microphoneOff : Icons.microphone
            color: root.tint

            SequentialAnimation on opacity {
                running: Dictation.status === "recording" || Dictation.status === "transcribing"
                loops: Animation.Infinite
                alwaysRunToEnd: true

                NumberAnimation {
                    to: 0.35
                    duration: Dictation.status === "transcribing" ? 400 : 800
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1.0
                    duration: Dictation.status === "transcribing" ? 400 : 800
                    easing.type: Easing.InOutSine
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2
            visible: Dictation.status === "recording"
            text: `${Math.floor(Dictation.elapsed / 60)}:${String(Dictation.elapsed % 60).padStart(2, "0")}`
            color: root.tint
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2
            visible: Dictation.status === "transcribing"
            text: "…"
            color: root.tint
        }
    }
}

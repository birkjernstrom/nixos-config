import QtQuick
import qs.Common
import qs.Widgets

// The conversation pane of an `@server` chat. Replies are typed into Pathway's
// own search field - see Nav.moduleSubmit.
Item {
    id: root

    ListView {
        id: list

        anchors.fill: parent
        anchors.margins: 16
        clip: true
        spacing: 14
        model: Mcp.messages
        boundsBehavior: Flickable.StopAtBounds

        onCountChanged: Qt.callLater(list.positionViewAtEnd)
        onContentHeightChanged: Qt.callLater(list.positionViewAtEnd)

        delegate: Item {
            id: message

            required property var modelData
            readonly property bool user: modelData.role === "user"

            width: list.width
            implicitHeight: message.user ? bubble.height : body.implicitHeight

            Rectangle {
                id: bubble

                anchors.right: parent.right
                width: Math.min(prompt.implicitWidth + 24, parent.width * 0.8)
                height: prompt.implicitHeight + 14
                radius: Theme.radius
                color: Theme.bgHover
                visible: message.user

                StyledText {
                    id: prompt

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    text: message.modelData.text
                    color: Theme.fg
                    wrapMode: Text.Wrap
                }
            }

            StyledText {
                id: body

                width: parent.width
                visible: !message.user
                text: message.modelData.text
                textFormat: message.modelData.role === "assistant" ? Text.MarkdownText : Text.PlainText
                color: message.modelData.role === "error" ? Theme.critical : Theme.fg
                linkColor: Theme.accent
                wrapMode: Text.Wrap
                onLinkActivated: link => Qt.openUrlExternally(link)

                HoverHandler {
                    cursorShape: body.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }

        footer: Item {
            width: list.width
            height: Mcp.busy ? 34 : 0

            StyledText {
                id: status

                anchors.left: parent.left
                anchors.bottom: parent.bottom
                visible: Mcp.busy
                text: `${Mcp.status}...`
                color: Theme.fgDim

                SequentialAnimation on opacity {
                    running: Mcp.busy
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.4
                        duration: 600
                    }
                    NumberAnimation {
                        to: 1
                        duration: 600
                    }
                }
            }
        }
    }

    StyledText {
        anchors.centerIn: parent
        text: `Ask ${Mcp.title} anything`
        color: Theme.fgDim
        visible: Mcp.messages.length === 0 && !Mcp.busy
    }
}

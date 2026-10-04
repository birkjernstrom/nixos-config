import QtQuick
import qs.Common
import qs.Widgets
import "markdown.js" as Markdown

// The conversation pane of an `@server` chat. Replies are typed into Pathway's
// own search field - see Nav.moduleSubmit.
Item {
    id: root

    readonly property real fontSize: Theme.fontSize + 1.5

    readonly property var palette: ({
            fg: Theme.fg.toString(),
            dim: Theme.fgSubtle.toString(),
            strong: Theme.fg.toString(),
            link: Theme.chatLink.toString(),
            code: Theme.fg.toString(),
            codeBg: Theme.bgHover.toString(),
            rule: Theme.border.toString(),
            mono: Theme.fontMono
        })

    ListView {
        id: list

        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        clip: true
        spacing: 22
        model: Mcp.messages
        boundsBehavior: Flickable.StopAtBounds
        header: Item {
            width: list.width
            height: 22
        }

        onCountChanged: Qt.callLater(list.positionViewAtEnd)
        onContentHeightChanged: Qt.callLater(list.positionViewAtEnd)

        delegate: Item {
            id: message

            required property var modelData
            readonly property bool user: modelData.role === "user"
            readonly property bool error: modelData.role === "error"

            width: list.width
            implicitHeight: message.user ? bubble.height : reply.implicitHeight

            Rectangle {
                id: bubble

                anchors.right: parent.right
                width: Math.min(prompt.implicitWidth + 32, parent.width * 0.78)
                height: prompt.implicitHeight + 20
                radius: Theme.radiusLarge
                color: Qt.alpha(Theme.accent, 0.16)
                border.color: Qt.alpha(Theme.accent, 0.28)
                border.width: 1
                visible: message.user

                StyledText {
                    id: prompt

                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    text: message.modelData.text
                    color: Theme.fg
                    font.pointSize: root.fontSize
                    lineHeight: 1.3
                    wrapMode: Text.Wrap
                }
            }

            Row {
                id: reply

                width: parent.width
                spacing: 12
                visible: !message.user

                Rectangle {
                    width: 3
                    height: body.implicitHeight - 12
                    radius: 1.5
                    color: Theme.critical
                    visible: message.error
                }

                StyledText {
                    id: body

                    width: reply.width - (message.error ? 15 : 0)
                    text: message.error ? message.modelData.text : Markdown.toHtml(message.modelData.text, root.palette)
                    textFormat: message.error ? Text.PlainText : Text.RichText
                    color: message.error ? Theme.critical : Theme.fg
                    font.pointSize: root.fontSize
                    lineHeight: message.error ? 1.3 : 1.0
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignTop
                    onLinkActivated: link => Qt.openUrlExternally(link)

                    HoverHandler {
                        cursorShape: body.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }
            }
        }

        footer: Item {
            width: list.width
            height: Mcp.busy ? 48 : 22

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                visible: Mcp.busy

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Repeater {
                        model: 3

                        Rectangle {
                            id: dot

                            required property int index

                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.accent
                            opacity: 0.25

                            SequentialAnimation on opacity {
                                running: Mcp.busy
                                loops: Animation.Infinite

                                PauseAnimation {
                                    duration: dot.index * 160
                                }
                                NumberAnimation {
                                    to: 1
                                    duration: 320
                                    easing.type: Easing.OutSine
                                }
                                NumberAnimation {
                                    to: 0.25
                                    duration: 320
                                    easing.type: Easing.InSine
                                }
                                PauseAnimation {
                                    duration: (2 - dot.index) * 160
                                }
                            }
                        }
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Mcp.status
                    color: Theme.fgSubtle
                    font.pointSize: root.fontSize - 0.5
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 6
        visible: Mcp.messages.length === 0 && !Mcp.busy

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `Ask ${Mcp.title} anything`
            color: Theme.fg
            font.pointSize: root.fontSize + 2
            font.weight: Font.DemiBold
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Type below and press Enter"
            color: Theme.fgSubtle
            font.pointSize: root.fontSize - 0.5
        }
    }
}

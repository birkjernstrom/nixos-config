import QtQuick
import qs.Common
import qs.Widgets

// Renders whatever Search returns for the current query and owns keyboard
// selection. Knows nothing about where results come from.
Item {
    id: root

    property string query: ""
    property int selectedIndex: 0
    readonly property var results: Search.query(root.query, Nav.scope)
    readonly property var selectedItem: root.results[root.selectedIndex] ?? null

    signal activated

    // Any change to the result set puts the cursor back on the best match.
    onResultsChanged: root.selectedIndex = 0

    function moveSelection(delta) {
        const n = root.results.length;
        if (n === 0)
            return;
        // Wrap in both directions - Raycast behaviour.
        root.selectedIndex = ((root.selectedIndex + delta) % n + n) % n;
        list.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function activateSelected() {
        const item = root.selectedItem;
        if (!item)
            return;
        // Providers whose ids are not stable across time opt out (see
        // ClipboardProvider - cliphist recycles its ids).
        if (item.frecency !== false)
            Frecency.bump(item.id);
        item.activate();
        // Modules replace the pane and must keep the window open; apps are done.
        if (item.kind !== "module")
            root.activated();
    }

    ListView {
        id: list

        anchors.fill: parent
        anchors.margins: 8
        clip: true
        spacing: 2
        model: root.results
        boundsBehavior: Flickable.StopAtBounds

        delegate: ResultRow {
            required property int index
            required property var modelData

            width: list.width
            item: modelData
            selected: index === root.selectedIndex

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                // Real pointer movement only. onEntered would also fire when the
                // window simply appears under a stationary cursor, moving the
                // selection off the top result before the user has touched anything.
                onPositionChanged: root.selectedIndex = parent.index
                onClicked: {
                    root.selectedIndex = parent.index;
                    root.activateSelected();
                }
            }
        }
    }

    StyledText {
        anchors.centerIn: parent
        text: "No results"
        color: Theme.fgDim
        visible: root.results.length === 0
    }
}

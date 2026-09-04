import QtQuick
import qs.Common

// Swaps the result list for a module's own view. With no module pushed the
// default content (the result list) is shown as-is.
Item {
    id: root

    default property alias content: container.data
    property Component source: null

    Item {
        id: container

        anchors.fill: parent
        visible: root.source === null
        enabled: visible
    }

    Loader {
        anchors.fill: parent
        active: root.source !== null
        sourceComponent: root.source
    }
}

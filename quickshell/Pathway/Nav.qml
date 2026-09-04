pragma Singleton

import Quickshell

// Decouples providers from the Pathway window. A `kind: "module"` ResultItem
// calls Nav.pushModule(someComponent) in its activate() without needing a
// reference to the window, and Pathway.qml binds its view to this.
Singleton {
    id: root

    property Component moduleView: null
    property string moduleTitle: ""

    signal closeRequested

    function pushModule(component, title) {
        root.moduleView = component;
        root.moduleTitle = title ?? "";
    }

    function popModule() {
        root.moduleView = null;
        root.moduleTitle = "";
    }

    function close() {
        root.closeRequested();
    }
}

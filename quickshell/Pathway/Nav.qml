pragma Singleton

import QtQuick
import Quickshell

// Decouples providers from the Pathway window. A `kind: "module"` ResultItem
// calls Nav.pushModule(someComponent) in its activate() without needing a
// reference to the window, and Pathway.qml binds its view to this.
Singleton {
    id: root

    property Component moduleView: null
    property string moduleTitle: ""
    // Set by modules that take typed input, e.g. an MCP chat: Enter in the
    // search field goes here instead of to the result list.
    property var moduleSubmit: null

    // A scope narrows the result list to one provider while reusing ResultList
    // wholesale. Modules that are "a filtered list" (clipboard, and most of what
    // comes next) need nothing more than this; moduleView stays for the ones
    // that genuinely need their own UI.
    property var scope: null
    property string scopeTitle: ""

    signal closeRequested

    function pushModule(component, title, submit) {
        root.moduleView = component;
        root.moduleTitle = title ?? "";
        root.moduleSubmit = submit ?? null;
    }

    function popModule() {
        root.moduleView = null;
        root.moduleTitle = "";
        root.moduleSubmit = null;
    }

    function pushScope(provider, title) {
        root.scope = provider;
        root.scopeTitle = title ?? "";
    }

    function popScope() {
        root.scope = null;
        root.scopeTitle = "";
    }

    function close() {
        root.closeRequested();
    }
}

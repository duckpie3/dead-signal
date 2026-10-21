pragma Singleton

import Quickshell
import QtQuick

// Open / closed state of the launcher, shared by the bar and the IPC handler.
Singleton {
    id: root

    property bool open: false
    property string initialQuery: ""       // prefix to start with: "", "> ", "= ", "@ "

    function toggle() { open ? hide() : show(""); }

    // name: "", "cmd", "calc" or "win"
    function show(name) {
        const pre = { cmd: "> ", calc: "= ", win: "@ " };
        root.initialQuery = pre[name] || "";
        root.open = true;
    }

    function hide() { root.open = false; }
}

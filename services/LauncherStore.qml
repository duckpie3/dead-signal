pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// What the shell remembers between sessions (launcher and focus timer): pinned clipboard entries, when clipboard entries
// were first seen, recently used emoji and the skin tone. One JSON file in the state directory.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/deadsignal"

    property var pins: []              // [{ text, ts }]
    property var seen: ({})            // cliphist id -> unix seconds (0 = before we started watching)
    property var recent: []            // emoji, most recent first
    property int tone: 0               // 0 = default, 1..5 = light … dark
    // Focus timer settings and today's count, edited in the focus popup.
    property var focus: ({ focus: 25, short: 5, long: 15, rounds: 4, auto: true, done: 0, day: "" })
    property bool loaded: false

    function save() { saveTimer.restart() }

    function setPins(p) { root.pins = p; save() }
    function setFocus(patch) { root.focus = Object.assign({}, root.focus, patch); save() }
    function setTone(t) { root.tone = t; save() }
    function pushRecent(ch) {
        const r = [ch].concat(root.recent.filter(x => x !== ch)).slice(0, 24);
        root.recent = r;
        save();
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.dir]
        onExited: file.path = root.dir + "/launcher.json"
    }

    FileView {
        id: file
        onLoaded: {
            try {
                const o = JSON.parse(file.text());
                root.pins = o.pins || [];
                root.seen = o.seen || {};
                root.recent = o.recent || [];
                root.tone = o.tone || 0;
                root.focus = Object.assign({}, root.focus, o.focus || {});
            } catch (e) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: file.setText(JSON.stringify({ pins: root.pins, seen: root.seen, recent: root.recent, tone: root.tone, focus: root.focus }))
    }
}

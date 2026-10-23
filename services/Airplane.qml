pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Airplane mode = Wi-Fi and Bluetooth soft-blocked, read from `rfkill -J`.
// Only polled while the network popup is open (it sets `watch`).
Singleton {
    id: root

    property bool on: false
    property bool watch: false

    function refresh() { if (!reader.running) reader.running = true; }

    function toggle() {
        Quickshell.execDetached(["rfkill", root.on ? "unblock" : "block", "wifi", "bluetooth"]);
        root.on = !root.on;
        settle.restart();
    }

    function parse(text) {
        try {
            const j = JSON.parse(text);
            const list = j.rfkilldevices || Object.values(j)[0] || [];
            const radios = list.filter(d => d.type === "wlan" || d.type === "bluetooth");
            root.on = radios.length > 0 && radios.every(d => d.soft === "blocked" || d.hard === "blocked");
        } catch (e) {}
    }

    Timer { id: settle; interval: 700; onTriggered: root.refresh() }

    Process {
        id: reader
        command: ["rfkill", "-J"]
        stdout: StdioCollector { onStreamFinished: root.parse(this.text) }
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.watch
        onTriggered: root.refresh()
    }
}

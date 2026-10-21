pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.theme

// Hyprland details that are not in Quickshell.Hyprland: keyboard layout and tiling layout.
Singleton {
    id: root

    property string kbCode: Config.keyboardLayouts.length > 0 ? Config.keyboardLayouts[0].code : "EN"
    property string tiling: "dwindle"

    function codeFor(name) {
        const n = (name || "").toLowerCase();
        for (let i = 0; i < Config.keyboardLayouts.length; i++) {
            if (n.indexOf(Config.keyboardLayouts[i].match) >= 0) return Config.keyboardLayouts[i].code;
        }
        return n.slice(0, 2).toUpperCase();
    }

    function nextLayout() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
    }

    function parseDevices(t) {
        try {
            const d = JSON.parse(t);
            const kbs = d.keyboards || [];
            const main = kbs.find(k => k.main) || kbs[0];
            if (main && main.active_keymap) kbCode = codeFor(main.active_keymap);
        } catch (e) {}
    }

    function parseLayout(t) {
        try {
            const o = JSON.parse(t);
            if (o.str) tiling = o.str;
        } catch (e) {}
    }

    Process {
        id: devices
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseDevices(this.text) }
    }

    Process {
        id: layout
        command: ["hyprctl", "getoption", "general:layout", "-j"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseLayout(this.text) }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activelayout") {
                // data: "<keyboard name>,<layout name>"
                const i = event.data.indexOf(",");
                root.kbCode = root.codeFor(event.data.slice(i + 1));
            } else if (event.name === "configreloaded") {
                layout.running = true;
                devices.running = true;
            }
        }
    }
}

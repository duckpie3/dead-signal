pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Backlight via brightnessctl. The cell hides itself when no backlight exists.
Singleton {
    id: root

    property real percent: 0
    property bool available: false

    function parse(t) {
        // brightnessctl -m  →  device,class,current,percent%,max
        const f = t.trim().split(",");
        if (f.length >= 5) {
            percent = parseInt(f[3]) || 0;
            available = true;
        }
    }

    function step(delta) {
        if (!available) return;
        setter.exec(["brightnessctl", "set", Math.abs(delta) + "%" + (delta > 0 ? "+" : "-")]);
    }

    Process {
        id: reader
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Process {
        id: setter
        onExited: reader.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!reader.running) reader.running = true
    }
}

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Backlight via brightnessctl. The cell hides itself when no backlight exists.
Singleton {
    id: root

    property real percent: 0
    property bool available: false
    property string device: ""
    property int pending: -1

    function parse(t) {
        // brightnessctl -m  →  device,class,current,percent%,max
        const f = t.trim().split(",");
        if (f.length >= 5) {
            device = f[0];
            percent = parseInt(f[3]) || 0;
            available = true;
        }
    }

    function step(delta) {
        if (!available) return;
        setter.exec(["brightnessctl", "set", Math.abs(delta) + "%" + (delta > 0 ? "+" : "-")]);
    }

    // Set an absolute value (the popup slider). Commands are throttled while dragging.
    function setPercent(p) {
        if (!available) return;
        const v = Math.max(1, Math.min(100, Math.round(p)));
        percent = v;
        pending = v;
        if (!throttle.running) throttle.start();
    }

    Timer {
        id: throttle
        interval: 60
        onTriggered: {
            if (root.pending < 0) return;
            setter.exec(["brightnessctl", "set", root.pending + "%"]);
            root.pending = -1;
        }
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

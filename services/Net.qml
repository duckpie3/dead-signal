pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

// Connection details from NetworkManager (nmcli) and latency from ping.
Singleton {
    id: root

    property bool connected: false
    property string type: ""          // "wifi" | "ethernet"
    property string iface: ""
    property string name: ""
    property string ip: ""
    property int strength: 0            // 0..100
    property string security: ""
    property string band: ""
    property int failures: 0
    property real pingMs: -1
    property var pingHistory: []      // ms, newest last; 999 = lost

    // "ok" | "offline" | "nolink"
    readonly property string link: !connected ? "offline" : (failures >= 3 ? "nolink" : "ok")

    readonly property real peakMs: {
        const ok = pingHistory.filter(v => v < 999);
        return ok.length > 0 ? Math.max.apply(null, ok) : 0;
    }

    // Lit bars out of 4.
    readonly property int bars: !connected ? 0 : (type === "ethernet" ? 4 : Math.max(1, Math.min(4, Math.ceil(strength / 25))))

    function parseInfo(t) {
        const m = {};
        t.split("\n").forEach(line => {
            const i = line.indexOf("=");
            if (i > 0) m[line.slice(0, i)] = line.slice(i + 1);
        });
        const was = connected;
        connected = m.state === "connected";
        type = m.type || "";
        iface = m.iface || "";
        name = m.name || "";
        ip = m.ip || "";
        security = m.security || "";
        strength = type === "ethernet" ? 100 : (parseInt(m.signal) || 0);
        const f = parseInt(m.freq) || 0;
        band = f === 0 ? "" : (f < 3000 ? "2.4 GHz" : (f < 5900 ? "5 GHz" : "6 GHz"));
        if (!connected) {
            pingMs = -1;
            failures = 0;
        } else if (!was) {
            failures = 0;
        }
    }

    function parsePing(t) {
        const v = parseFloat(t);
        let h;
        if (isNaN(v)) {
            failures = failures + 1;
            pingMs = -1;
            h = 999;
        } else {
            failures = 0;
            pingMs = v;
            h = v;
        }
        pingHistory = pingHistory.concat([h]).slice(-40);
    }

    function disconnect() {
        if (iface !== "") Quickshell.execDetached(["nmcli", "device", "disconnect", iface]);
    }

    Process {
        id: info
        command: ["sh", Quickshell.shellPath("scripts/netinfo.sh")]
        stdout: StdioCollector {
            onStreamFinished: root.parseInfo(this.text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!info.running) info.running = true
    }

    Process {
        id: ping
        command: ["sh", Quickshell.shellPath("scripts/ping.sh"), Config.pingHost]
        stdout: StdioCollector {
            onStreamFinished: root.parsePing(this.text)
        }
    }

    Timer {
        interval: 1500
        running: root.connected
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!ping.running) ping.running = true
    }
}

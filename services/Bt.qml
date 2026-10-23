pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Bluetooth through BlueZ. Devices are grouped the way the popup shows them.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool present: adapter !== null && adapter !== undefined
    readonly property bool on: present && adapter.enabled
    readonly property bool scanning: present && adapter.discovering

    readonly property var all: present ? adapter.devices.values : []
    readonly property var connected: all.filter(d => d.connected)
    readonly property var paired: all.filter(d => !d.connected && d.paired)
    readonly property var nearby: all.filter(d => !d.connected && !d.paired)
    readonly property int count: connected.length
    readonly property bool low: connected.some(d => { const p = root.percent(d); return p >= 0 && p <= 20; })

    property var pendingPair: null

    // Battery 0..100, or -1 when the device does not report one.
    function percent(d) {
        if (!d.batteryAvailable) return -1;
        const b = d.battery;
        return Math.round(b > 1 ? b : b * 100);
    }

    function nameOf(d) { return d.name || d.deviceName || d.address; }

    function kind(d) {
        const i = (d.icon || "").toLowerCase();
        if (i.includes("headset") || i.includes("headphone")) return "Headphones";
        if (i.includes("mouse")) return "Mouse";
        if (i.includes("keyboard")) return "Keyboard";
        if (i.includes("phone")) return "Phone";
        if (i.includes("gaming") || i.includes("joystick")) return "Controller";
        if (i.includes("speaker") || i.includes("audio")) return "Speaker";
        if (i.includes("computer") || i.includes("laptop")) return "Computer";
        return "Device";
    }

    function setOn(v) { if (present) adapter.enabled = v; }
    function setScan(v) { if (present && adapter.enabled) adapter.discovering = v; }

    // Connected -> disconnect. Paired -> connect. Unknown -> pair, then connect once it is paired.
    function activate(d) {
        if (d.connected) {
            d.disconnect();
        } else if (d.paired) {
            d.connect();
        } else {
            d.trusted = true;
            root.pendingPair = d;
            d.pair();
        }
    }

    Connections {
        target: root.pendingPair
        function onPairedChanged() {
            const d = root.pendingPair;
            if (d && d.paired) {
                root.pendingPair = null;
                d.connect();
            }
        }
    }
}

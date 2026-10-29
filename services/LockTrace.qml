pragma Singleton

import Quickshell
import QtQuick

// The lock screen's oscilloscope. One buffer of 102 samples scrolls left every 30 ms. A key press
// starts a damped burst, so the trace is a picture of the typing. It lives here, not in the
// lock scene, because the lock surface and the unlock overlay both draw it and must agree.
Singleton {
    id: root

    readonly property int size: 102
    property var wave: new Array(102).fill(0)   // rows above (+) or below (-) the baseline
    property int rev: 0                        // bumped whenever the picture changes

    property real en: 0                        // burst energy, in rows
    property real ph: 0
    property real sg: 1
    property real fr: 1.15
    property var pending: null
    property string last: "idle"

    function reset() {
        root.wave = new Array(102).fill(0);
        root.en = 0;
        root.pending = null;
        root.rev++;
    }

    // The height, direction and speed of the burst depend on the key, so it does not look repeated.
    function key(code) {
        root.pending = { amp: 4.8 + (code * 7 % 5) * 0.93, sg: code % 2 ? 1 : -1, fr: 0.71 + (code % 4) * 0.09 };
    }
    function backspace() { root.pending = { amp: 6, sg: -1, fr: 1.12 } }

    function step() {
        const p = LockState.phase;
        const live = p === "typing" || p === "checking" || p === "denied" || p === "granted" || p === "opening";
        if (!live) {
            if (root.en !== 0 || root.wave.some(v => v !== 0)) {
                root.wave = new Array(102).fill(0);
                root.en = 0;
                root.rev++;
            }
            root.last = p;
            return;
        }
        if (p !== root.last) {
            if (p === "denied") { root.en = 8.4; root.fr = 1.43; root.sg = 1; root.ph = Math.PI / 2; }
            if (p === "granted") { root.en = 8.4; root.fr = 0.45; root.sg = 1; root.ph = 0; }
            root.last = p;
        }
        let s = 0;
        if (p === "checking") {
            root.ph += 0.71;
            s = 3.5 * Math.sin(root.ph) + 1.6 * Math.sin(root.ph * 2.3);
        } else {
            if (root.pending) {
                root.en = Math.min(8.4, Math.max(root.en, 0) + root.pending.amp);
                root.sg = root.pending.sg;
                root.fr = root.pending.fr;
                root.ph = 0;
                root.pending = null;
            }
            s = root.sg * root.en * Math.sin(root.ph);
            root.ph += root.fr;
            root.en *= 0.846;
            if (root.en < 0.33) root.en = 0;
        }
        const v = Math.round(s);
        const moving = v !== 0 || p === "checking" || root.wave.some(x => x !== 0);
        const w = root.wave;
        w.push(v);
        w.shift();
        if (moving) root.rev++;
    }

    Timer {
        interval: 30
        repeat: true
        running: LockState.locked || LockState.curtain
        onTriggered: root.step()
    }
}

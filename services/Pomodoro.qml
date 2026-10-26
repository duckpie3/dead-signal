pragma Singleton

import Quickshell
import QtQuick
import qs.theme

// Focus timer: focus → short break, and a long break after the last round.
// Idle (never started, or reset) hides the bar cell. Durations, rounds, auto-start and today's
// count are kept in LauncherStore.
Singleton {
    id: root

    property string phase: "focus"        // "focus" | "short" | "long"
    property bool active: false           // started and not reset: the bar cell is shown
    property bool running: false
    property bool ended: false            // a phase ran out and the next one waits for the user
    property int round: 1
    property int rem: 0                   // seconds left; only meaningful while active
    property double endAt: 0
    property int tickNo: 0                // bumped every second so the "ends at" text refreshes

    readonly property var cfg: LauncherStore.focus
    readonly property int rounds: cfg.rounds
    readonly property bool auto: cfg.auto

    function dur(ph) { return cfg[ph] * 60 }
    function today() { return Qt.formatDate(new Date(), "yyyy-MM-dd") }
    readonly property int doneToday: (root.tickNo, cfg.day === root.today() ? cfg.done : 0)

    readonly property int secsLeft: active ? rem : dur(phase)
    readonly property real progress: ended ? 1 : (dur(phase) > 0 ? 1 - secsLeft / dur(phase) : 0)
    readonly property string stateText: ended ? "Ready" : running ? "Running" : active ? "Paused" : "Idle"
    readonly property string endsAt: running ? (root.tickNo, Qt.formatTime(new Date(endAt), "HH:mm")) : "--:--"
    readonly property string nextPhase: phase === "focus" ? (round >= rounds ? "long" : "short") : "focus"
    readonly property string shortLabel: phase === "focus" ? "FOC" : "BRK"
    readonly property color tint: phase === "focus" ? Theme.teal : Theme.brass
    readonly property color ink: ended ? Theme.copper : running ? tint : Theme.ash

    function fmt(s) {
        s = Math.max(0, s);
        return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
    }

    function phaseName(ph) { return ph === "focus" ? "focus" : ph === "short" ? "short break" : "long break" }

    function run() {
        root.endAt = Date.now() + root.rem * 1000;
        root.running = true;
        root.ended = false;
    }

    // Start the timer from idle, or carry on from paused / ready.
    function start() {
        if (!root.active) {
            root.rem = root.dur(root.phase);
            root.active = true;
        }
        root.run();
    }

    function pause() {
        if (!root.running) return;
        root.rem = Math.max(0, Math.ceil((root.endAt - Date.now()) / 1000));
        root.running = false;
    }

    function toggle() { root.running ? root.pause() : root.start() }

    function skip() { root.finish(true) }

    // Back to an untouched phase and hide the cell. The round counter stays.
    function reset() {
        root.running = false;
        root.ended = false;
        root.active = false;
        root.rem = root.dur(root.phase);
    }

    function pick(ph) {
        root.phase = ph;
        root.rem = root.dur(ph);
        root.running = false;
        root.ended = false;
    }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Focus timer", "-i", "alarm-symbolic", title, body]);
    }

    // Move on to the next phase. `manual` = the skip button: keeps the running state, no notification.
    function finish(manual) {
        const was = root.phase;
        const next = root.nextPhase;
        if (was === "focus" && root.active) {
            const day = root.today();
            LauncherStore.setFocus({ done: (cfg.day === day ? cfg.done : 0) + 1, day: day });
        }
        if (was === "long") root.round = 1;
        else if (was !== "focus") root.round += 1;

        root.phase = next;
        root.rem = root.dur(next);
        const go = manual ? root.running : root.auto;
        root.running = go;
        root.ended = !manual && !go;
        if (go) root.endAt = Date.now() + root.rem * 1000;

        if (!manual) {
            const n = root.phaseName(next);
            root.notify(was === "focus" ? "Focus done" : "Break over",
                (go ? "Now: " : "Next: ") + n + ", " + cfg[next] + " min" + (go ? "" : ". Start it from the bar."));
        }
    }

    // key: "focus" | "short" | "long" | "rounds"
    function setDur(key, v) {
        const old = cfg[key];
        const p = {};
        p[key] = v;
        LauncherStore.setFocus(p);
        if (key === root.phase && !root.running && root.rem === old * 60) root.rem = v * 60;
    }

    function setAuto(v) { LauncherStore.setFocus({ auto: v }) }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: {
            root.tickNo++;
            if (!root.running) return;
            root.rem = Math.max(0, Math.ceil((root.endAt - Date.now()) / 1000));
            if (root.rem <= 0) root.finish(false);
        }
    }
}

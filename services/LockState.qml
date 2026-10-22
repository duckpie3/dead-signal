pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick

// Lock screen state machine and PAM check.
//   idle -> typing -> checking -> granted -> opening -> (unlocked)
//                              \-> denied -> typing
// The session is only released after the "opening" animation has played.
Singleton {
    id: root

    property bool locked: false
    property string phase: "idle"
    property string pw: ""
    property int fails: 0
    property bool caps: false
    property bool fade: false              // segments are fading back after a denied attempt
    property bool curtain: false           // the overlay window (shutters over the live desktop) is mapped
    property bool retract: false           // ...and its shutters are opening

    readonly property string user: Quickshell.env("USER") || "user"
    property string host: ""
    readonly property bool typing: phase === "idle" || phase === "typing"

    property bool scanDone: false
    property int verdict: 0                // 0 waiting, 1 accepted, -1 refused

    function lock() {
        console.log("[lock] requested, already locked:", root.locked);
        if (root.locked) return;
        try {
            root.reset();
        } catch (e) {
            console.warn("[lock] reset failed:", e);
        }
        root.fails = 0;
        root.locked = true;
        console.log("[lock] locked = true");
    }

    function reset() {
        scanTimer.stop(); grantTimer.stop(); openTimer.stop(); denyTimer.stop(); retractTimer.stop(); doneTimer.stop();
        root.curtain = false;
        root.retract = false;
        if (pam.active) pam.abort();
        root.phase = "idle";
        root.pw = "";
        root.fade = false;
        root.verdict = 0;
    }

    function wake() { if (root.phase === "idle") root.phase = "typing"; }

    function type(ch) {
        if (!root.typing) return;
        const next = (root.pw + ch).slice(0, 64);
        root.fade = false;
        root.pw = next;
        root.phase = "typing";
    }

    function backspace() {
        if (!root.typing) return;
        root.fade = false;
        root.pw = root.pw.slice(0, -1);
        root.phase = "typing";
    }

    function clear() {
        if (!root.typing) return;
        root.pw = "";
        root.phase = "idle";
    }

    function submit() {
        if (!root.typing || root.pw.length === 0) return;
        root.scanDone = false;
        root.verdict = 0;
        root.phase = "checking";
        scanTimer.restart();
        if (pam.active) pam.abort();
        if (!pam.start()) {
            root.verdict = -1;
            root.settle();
        }
    }

    // Runs once the scan animation has finished AND PAM has answered.
    function settle() {
        if (root.phase !== "checking" || !root.scanDone || root.verdict === 0) return;
        if (root.verdict > 0) {
            root.curtain = true;                 // mapped now, hidden under the lock until it is released
            root.phase = "granted";
            grantTimer.restart();
        } else {
            root.fails += 1;
            root.phase = "denied";
            denyTimer.restart();
        }
    }

    Timer { id: scanTimer; interval: 460; onTriggered: { root.scanDone = true; root.settle(); } }
    // Granted -> the lock layer fades out -> the session is released while the overlay (same dim shutters)
    // is already in place -> the greeting holds a moment -> the shutters open over the live desktop.
    Timer {
        id: grantTimer
        interval: 1000
        onTriggered: {
            root.phase = "opening";
            openTimer.restart();
        }
    }
    Timer {
        id: openTimer
        interval: 350
        onTriggered: {
            root.locked = false;
            retractTimer.restart();
        }
    }
    Timer { id: retractTimer; interval: 350; onTriggered: { root.retract = true; doneTimer.restart(); } }
    Timer { id: doneTimer; interval: 1000; onTriggered: root.reset() }
    Timer {
        id: denyTimer
        interval: 800
        onTriggered: {
            root.fade = true;
            root.pw = "";
            root.phase = "typing";
        }
    }

    // PAM-BEGIN
    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"

        onPamMessage: {
            if (responseRequired) respond(root.pw);
        }
        onCompleted: result => {
            root.verdict = result === PamResult.Success ? 1 : -1;
            root.settle();
        }
        onError: error => {
            root.verdict = -1;
            root.settle();
        }
    }
    // PAM-END

    // IO-BEGIN
    FileView {
        path: "/etc/hostname"
        onLoaded: root.host = text().trim()
    }

    // Caps Lock has no key event, so read the keyboard LED while the lock screen is waiting for input.
    Process {
        id: capsProbe
        command: ["sh", "-c", "cat /sys/class/leds/*capslock/brightness 2>/dev/null | grep -q 1 && echo 1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: root.caps = text.trim() === "1"
        }
    }
    Timer {
        interval: 400
        repeat: true
        running: root.locked && root.typing
        triggeredOnStart: true
        onTriggered: capsProbe.running = true
    }
    // IO-END
}

pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.theme

// Screenshots and the colour picker.
//
// 1. grim takes one frozen frame of the focused monitor.
// 2. The overlay (capture/CaptureWindow.qml) shows that frame; you select, or point at a pixel.
// 3. The cropped PNG is saved and copied (or the colour is copied) and a result toast appears.
//
// Needs grim and wl-clipboard. Window mode also uses hyprctl.
Singleton {
    id: root

    // ── Overlay state ─────────────────────────────────────
    property bool open: false
    property bool busy: false
    property string kind: "shot"           // "shot" | "pick"
    property string mode: "region"         // "region" | "screen" | "window"
    property string frame: ""              // frozen frame, a file path
    property string monitorName: ""
    property var windows: []               // [{ x, y, w, h, title }] relative to the monitor, top-most first

    // ── Result toast ──────────────────────────────────────
    // { kind: "shot", title, file, name, w, h } | { kind: "color", hex, rgb, hsl } | { kind: "error", title, text }
    property var toast: null
    property real toastLeft: 0
    property real toastTotal: 1
    property bool toastPaused: false

    readonly property string dir: Quickshell.env("HOME") ? expand(Config.screenshotDir) : "/tmp"
    readonly property string workDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/deadsignal-shot"

    function expand(p) { return p.startsWith("~/") ? Quickshell.env("HOME") + p.slice(1) : p }

    function two(n) { return String(n).padStart(2, "0") }

    function nextPath() {
        const d = new Date();
        return root.dir + "/" + d.getFullYear() + "-" + two(d.getMonth() + 1) + "-" + two(d.getDate())
            + "_" + two(d.getHours()) + "-" + two(d.getMinutes()) + "-" + two(d.getSeconds()) + ".png";
    }

    // ── Entry points ──────────────────────────────────────
    // what: "region" | "screen" | "window"
    function screenshot(what) { root.begin("shot", what) }
    function pick() { root.begin("pick", "region") }

    function begin(kind, mode) {
        if (root.open || root.busy) return;
        if (kind === "pick" && Config.pickerBackend === "hyprpicker") {
            root.busy = true;
            LauncherState.hide();
            hyprpickerDelay.restart();
            return;
        }
        root.busy = true;
        root.kind = kind;
        root.mode = mode;
        root.closeToast();
        LauncherState.hide();
        // Give the launcher a moment to leave the screen before the frame is grabbed.
        grabDelay.restart();
    }

    function cancel() {
        root.open = false;
        root.busy = false;
    }

    // ── Results ───────────────────────────────────────────
    function showToast(t) {
        root.toast = t;
        root.toastTotal = Config.captureToastSeconds * 1000;
        root.toastLeft = root.toastTotal;
        root.toastPaused = false;
    }

    function closeToast() { root.toast = null }

    function shotSaved(path, w, h, label) {
        root.open = false;
        root.busy = false;
        const name = path.slice(path.lastIndexOf("/") + 1);
        // Copy the file to the clipboard; cliphist picks it up from there.
        copier.command = ["sh", "-c", 'f="$1"; shift; exec "$@" < "$f"', "sh", path]
            .concat(Config.copyCommand).concat(["--type", "image/png"]);
        copier.running = true;
        root.showToast({ kind: "shot", title: label + " captured", file: path, name: name, w: w, h: h });
    }

    function failed(title, text) {
        root.open = false;
        root.busy = false;
        root.showToast({ kind: "error", title: title, text: text });
    }

    function rgbOf(hex) {
        const h = hex.replace("#", "");
        const f = h.length === 3 ? h.split("").map(c => c + c).join("") : h;
        return [parseInt(f.slice(0, 2), 16), parseInt(f.slice(2, 4), 16), parseInt(f.slice(4, 6), 16)];
    }

    function hslOf(r, g, b) {
        r /= 255; g /= 255; b /= 255;
        const mx = Math.max(r, g, b), mn = Math.min(r, g, b);
        const l = (mx + mn) / 2;
        let h = 0, s = 0;
        if (mx !== mn) {
            const d = mx - mn;
            s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
            h = mx === r ? (g - b) / d + (g < b ? 6 : 0) : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
            h *= 60;
        }
        return "hsl(" + Math.round(h) + ", " + Math.round(s * 100) + "%, " + Math.round(l * 100) + "%)";
    }

    function hex2(n) { return n.toString(16).padStart(2, "0") }

    // The picker found a colour (r g b 0-255): copy the hex and say so.
    function picked(r, g, b) {
        root.open = false;
        root.busy = false;
        const hex = ("#" + hex2(r) + hex2(g) + hex2(b)).toUpperCase();
        root.copyText(hex);
        root.showToast({
            kind: "color", hex: hex,
            rgb: "rgb(" + r + ", " + g + ", " + b + ")",
            hsl: hslOf(r, g, b), r: r, g: g, b: b
        });
    }

    function copyText(t) { Quickshell.execDetached(Config.copyCommand.concat([t])) }
    function openFile(f) { Quickshell.execDetached(["xdg-open", f]) }
    function openFolder() { Quickshell.execDetached(["xdg-open", root.dir]) }
    function deleteFile(f) { Quickshell.execDetached(["rm", "-f", f]) }

    // ── Plumbing ──────────────────────────────────────────
    Timer {
        id: grabDelay
        interval: 220
        onTriggered: {
            const mon = Hyprland.focusedMonitor;
            root.monitorName = mon ? mon.name : "";
            root.frame = root.workDir + "/freeze-" + Date.now() + ".png";
            grabber.command = ["sh", "-c",
                'w="$1"; o="$2"; shift 2; mkdir -p "$w" "$o" && rm -f "$w"/freeze-*.png && exec grim "$@"',
                "sh", root.workDir, root.dir]
                .concat(root.monitorName !== "" ? ["-o", root.monitorName] : []).concat([root.frame]);
            grabber.running = true;
        }
    }

    Process {
        id: grabber
        onExited: code => {
            if (code !== 0) {
                root.failed("Capture failed", "grim could not capture the screen");
                return;
            }
            if (root.kind === "shot") {
                lister.running = true;
            } else {
                root.windows = [];
                root.open = true;
            }
        }
    }

    // Visible windows of the focused monitor, front-most first, for window mode.
    Process {
        id: lister
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = [];
                try {
                    const mon = Hyprland.focusedMonitor;
                    const ws = mon && mon.activeWorkspace ? mon.activeWorkspace.id : undefined;
                    const all = JSON.parse(text);
                    out = all.filter(c => c.mapped && !c.hidden && c.size[0] > 0
                            && (!mon || c.monitor === mon.id)
                            && (ws === undefined || c.workspace.id === ws))
                        .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                        .map(c => ({
                            x: c.at[0] - (mon ? mon.x : 0), y: c.at[1] - (mon ? mon.y : 0),
                            w: c.size[0], h: c.size[1], title: c.title || c.class
                        }));
                } catch (e) {}
                root.windows = out;
                root.open = true;
            }
        }
        onExited: code => { if (code !== 0) { root.windows = []; root.open = true; } }
    }

    Process { id: copier }

    // hyprpicker: its own overlay; prints the colour when you click.
    Timer {
        id: hyprpickerDelay
        interval: 220
        onTriggered: { hyprpicker.running = true }
    }
    Process {
        id: hyprpicker
        command: ["hyprpicker", "-a"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/#([0-9a-fA-F]{6})/);
                if (m) {
                    const c = root.rgbOf(m[0]);
                    root.picked(c[0], c[1], c[2]);
                } else root.busy = false;
            }
        }
        onExited: code => { if (code !== 0) root.busy = false; }
    }

    Timer {
        interval: 100
        repeat: true
        running: root.toast !== null
        onTriggered: {
            if (root.toastPaused) return;
            root.toastLeft -= 100;
            if (root.toastLeft <= 0) root.closeToast();
        }
    }
}

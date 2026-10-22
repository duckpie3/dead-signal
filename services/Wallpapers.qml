pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

// Wallpaper list, the picker's open state, and applying a wallpaper.
// The applied wallpaper is remembered in ~/.local/state/deadsignal/wallpaper.json
// and set again when the shell starts (Config.wallpaperRestore).
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/deadsignal"

    property bool open: false
    property bool scanning: false
    property var items: []                 // { path, name, bytes, res }
    property string current: ""            // path of the wallpaper that is set
    property string fit: "fill"            // fill | fit | tile

    property bool applyRandomWhenScanned: false

    function toggle() { open ? hide() : show(); }
    function show() { root.open = true; root.scan(); }
    function hide() { root.open = false; }

    function scan() {
        scanner.running = false;
        root.scanning = true;
        scanner.running = true;
    }

    // Set a random wallpaper without opening the picker.
    function applyRandom() {
        root.applyRandomWhenScanned = true;
        root.scan();
    }

    // "/home/me/a b#.png" -> a file:// URL that survives spaces and '#'.
    function url(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function sizeText(bytes) {
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB";
        return Math.max(1, Math.round(bytes / 1024)) + " KB";
    }

    function parse(text) {
        const out = [];
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] === "") continue;
            const p = lines[i].split("\t");
            const dim = (p[2] || "").trim().split(" ");
            out.push({
                path: p[0],
                name: p[0].split("/").pop(),
                bytes: Number(p[1]) || 0,
                res: dim.length === 2 ? dim[0] + "×" + dim[1] : ""
            });
        }
        root.items = out;
        root.scanning = false;
        if (root.applyRandomWhenScanned) {
            root.applyRandomWhenScanned = false;
            if (out.length > 0)
                root.apply(out[Math.floor(Math.random() * out.length)].path, root.fit);
        }
    }

    // Runs Config.wallpaperCommand with {file} and {fit} filled in. The command may also be a list of
    // commands (for hyprpaper before 0.8: preload, then wallpaper); they run one after another.
    // Output and errors from the command are written to the Quickshell log.
    property var queue: []

    function run(path, fit) {
        const fitName = Config.wallpaperFitNames[fit] || fit;
        const fill = a => a.split("{file}").join(path).split("{fit}").join(fitName);
        const c = Config.wallpaperCommand;
        const cmds = Array.isArray(c[0]) ? c : [c];
        root.queue = cmds.map(cmd => cmd.map(fill));
        root.next();
    }

    function next() {
        if (runner.running || root.queue.length === 0) return;
        const q = root.queue.slice();
        const cmd = q.shift();
        root.queue = q;
        console.log("wallpaper: " + cmd.join(" "));
        runner.command = cmd;
        runner.running = true;
    }

    function apply(path, fit) {
        root.current = path;
        root.fit = fit;
        root.run(path, fit);
        mkdir.running = true;
    }

    Process {
        id: runner
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") console.log("wallpaper: " + text.trim()) }
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") console.warn("wallpaper: " + text.trim()) }
        onExited: (code, status) => {
            if (code !== 0) console.warn("wallpaper: command exited with code " + code);
            root.next();
        }
    }

    Process {
        id: scanner
        command: ["sh", Quickshell.shellPath("scripts/wallpapers.sh"), Config.wallpaperDir]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    FileView {
        id: file
        path: root.stateDir + "/wallpaper.json"
        onLoaded: {
            try {
                const s = JSON.parse(file.text());
                if (typeof s.file === "string" && s.file !== "") {
                    root.current = s.file;
                    root.fit = s.fit || "fill";
                    if (Config.wallpaperRestore)
                        restore.start();
                }
            } catch (e) {}
        }
    }

    // Give swww-daemon / hyprpaper a moment to come up after login.
    Timer {
        id: restore
        interval: 1500
        onTriggered: root.run(root.current, root.fit)
    }

    Process {
        id: mkdir
        command: ["mkdir", "-p", root.stateDir]
        onExited: file.setText(JSON.stringify({ file: root.current, fit: root.fit }))
    }
}

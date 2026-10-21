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

    // Runs Config.wallpaperCommand with {file} and {fit} filled in.
    function run(path, fit) {
        const fitName = Config.wallpaperFitNames[fit] || fit;
        const cmd = Config.wallpaperCommand.map(a => a.split("{file}").join(path).split("{fit}").join(fitName));
        Quickshell.execDetached(cmd);
    }

    function apply(path, fit) {
        root.current = path;
        root.fit = fit;
        root.run(path, fit);
        mkdir.running = true;
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

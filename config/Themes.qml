pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The colour themes. Each theme is one file in the `themes` folder (dark.json, light.json, …).
// To add yours, copy one of them, give it a new name and change the colours: it shows up in the
// launcher's theme selector. Switch with the launcher (`>` then "Theme selector"), or
//   qs -c deadsignal ipc call theme next        (bind it to Super T)
//   qs -c deadsignal ipc call theme set light
// The choice is remembered in ~/.local/state/deadsignal/theme.json.
Singleton {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/deadsignal"
    readonly property string dir: Quickshell.shellPath("themes")

    // Every colour a theme sets. `ivory` is the primary text colour, `stage` the backdrop behind
    // the lock screen, the wallpaper picker and the screenshot overlay.
    readonly property var keys: ["stage", "bg", "panel", "steel", "ivory", "ash", "dust",
                                 "copper", "teal", "brass", "sage", "rust"]

    // dark.json is read straight away, so the shell has colours from its first frame and stays
    // usable if the folder cannot be scanned. It is also what a theme falls back on for any colour it leaves out.
    FileView {
        id: darkFile
        path: root.dir + "/dark.json"
        blockLoading: true
    }

    function readJson(text) {
        try { return JSON.parse(text); } catch (e) { return null; }
    }

    readonly property var fallback: {
        const raw = root.readJson(darkFile.text());
        const t = { id: "dark", label: "Dead Signal · dark", order: 1 };
        for (let i = 0; i < root.keys.length; i++) {
            const k = root.keys[i];
            t[k] = raw && /^#[0-9a-fA-F]{6}$/.test(raw[k] || "") ? raw[k] : "#888888";
        }
        if (raw && raw.label) t.label = raw.label;
        return t;
    }

    // Raw theme files found by the last scan: [{ id, data }].
    property var found: []

    // Ordered by the `order` number in the file (default 100), then by name.
    // `base` (a theme id) names the theme that fills in any colour the file leaves out; default dark.
    readonly property var list: {
        const files = root.found;
        const byId = {};
        files.forEach(f => { byId[f.id] = f.data; });
        const out = [];
        files.forEach(f => {
            const d = f.data;
            const base = byId[d.base] || byId.dark || root.fallback;
            const t = { id: f.id, label: typeof d.label === "string" && d.label !== "" ? d.label : f.id,
                        order: typeof d.order === "number" ? d.order : 100 };
            for (let i = 0; i < root.keys.length; i++) {
                const k = root.keys[i];
                t[k] = /^#[0-9a-fA-F]{6}$/.test(d[k] || "") ? d[k] : (/^#[0-9a-fA-F]{6}$/.test(base[k] || "") ? base[k] : root.fallback[k]);
            }
            out.push(t);
        });
        out.sort((a, b) => a.order - b.order || a.label.localeCompare(b.label));
        return out.length > 0 ? out : [root.fallback];
    }

    property string current: "dark"
    readonly property var palette: list.find(t => t.id === current) || list.find(t => t.id === "dark") || list[0]

    function set(id) {
        if (!list.some(t => t.id === id)) return;
        current = id;
        save.running = true;
    }

    function next() {
        const at = list.findIndex(t => t.id === palette.id);
        set(list[(at + 1) % list.length].id);
    }

    // Look at the folder again (the selector does this when it opens, so a new file shows up at once).
    function rescan() { scan.running = true; }

    function parse(text) {
        const out = [];
        text.split("\n").forEach(line => {
            const tab = line.indexOf("\t");
            if (tab < 0) return;
            const d = root.readJson(line.slice(tab + 1));
            if (d && typeof d === "object") out.push({ id: line.slice(0, tab), data: d });
        });
        root.found = out;
    }

    Component.onCompleted: scan.running = true

    Process {
        id: scan
        command: ["sh", Quickshell.shellPath("scripts/themes.sh"), root.dir]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    FileView {
        id: file
        path: root.stateDir + "/theme.json"
        onLoaded: {
            const s = root.readJson(file.text());
            if (s && typeof s.id === "string") root.current = s.id;
        }
    }

    Process {
        id: save
        command: ["mkdir", "-p", root.stateDir]
        onExited: file.setText(JSON.stringify({ id: root.current }))
    }
}

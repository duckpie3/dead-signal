pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

// Clipboard history through cliphist. Entries are listed with `cliphist list`, copied back with
// `cliphist decode | wl-copy`. cliphist keeps no timestamps or source app, so the age comes from
// when this shell first saw an entry. Pins are our own copies of the text (cliphist ids change
// whenever an entry is copied again).
Singleton {
    id: root

    property bool available: false
    property var entries: []               // newest first
    property bool initial: true            // entries found at start have no known age

    readonly property string thumbDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/deadsignal-clip"
    property var thumbs: ({})              // cliphist id -> file path
    property var thumbQueue: []
    property string thumbBusy: ""

    property string full: ""               // start of the selected entry's text
    property string fullFor: ""
    property int fullBytes: 0
    property string wantId: ""

    // ── Classification ────────────────────────────────────
    function collapse(t) { return t.replace(/\s+/g, " ").trim().slice(0, 100) }

    function classify(preview) {
        const img = preview.match(/^\[\[ binary data (.+?) (\w+) (\d+)x(\d+) \]\]$/);
        if (img) return { kind: "IMG", size: img[1], fmt: img[2].toUpperCase(), w: parseInt(img[3]), h: parseInt(img[4]) };
        if (/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(preview)) return { kind: "COLOR" };
        if (/^(https?|ftp):\/\/\S+$/.test(preview)) return { kind: "LINK" };
        if (/^(sudo|git|ssh|scp|cd|ls|cat|grep|rg|npm|pip|cargo|make|curl|wget|docker|systemctl|pacman|yay|paru|nvim|vim|rsync|tar|chmod|chown|journalctl)\s/.test(preview)
            || /[{};]|=>|\bdef \w+\(|\bfunction\b|\bimport \w+|#include|::|\$\(|^\s*(if|for|while) .*:\s/.test(preview))
            return { kind: "CODE" };
        return { kind: "TEXT" };
    }

    function makeEntry(id, line, preview, ts) {
        const c = root.classify(preview);
        return { id: id, line: line, preview: preview, kind: c.kind, size: c.size || "", fmt: c.fmt || "", w: c.w || 0, h: c.h || 0, ts: ts, pinned: false, text: "" };
    }

    function pinEntries() {
        return LauncherStore.pins.map((p, i) => {
            const prev = root.collapse(p.text);
            const e = root.makeEntry("pin:" + i, "", prev, p.ts || 0);
            e.pinned = true;
            e.text = p.text;
            return e;
        });
    }

    // ── Listing ───────────────────────────────────────────
    function refresh() {
        if (!root.available || !LauncherStore.loaded) return;
        if (!lister.running) lister.running = true;
    }

    function parse(text) {
        const lines = text.split("\n");
        const out = [];
        const seen = LauncherStore.seen;
        const now = Math.floor(Date.now() / 1000);
        const keep = {};
        let dirty = false;
        for (let i = 0; i < lines.length && out.length < 300; i++) {
            const ln = lines[i];
            const t = ln.indexOf("\t");
            if (t < 1) continue;
            const id = ln.slice(0, t);
            keep[id] = true;
            if (seen[id] === undefined) { seen[id] = root.initial ? 0 : now; dirty = true; }
            out.push(root.makeEntry(id, ln, ln.slice(t + 1).trim(), seen[id]));
        }
        for (const k in seen) if (!keep[k] && out.length < 300) { delete seen[k]; dirty = true; }
        if (dirty) LauncherStore.save();
        root.initial = false;
        root.entries = out;
    }

    function search(q) {
        const pins = root.pinEntries();
        const pinned = {};
        pins.forEach(p => { pinned[p.preview] = true; });
        const rest = root.entries.filter(e => !pinned[e.preview]);
        const all = pins.concat(rest);
        q = (q || "").toLowerCase();
        if (q === "") return all;
        const kinds = { image: "IMG", img: "IMG", link: "LINK", url: "LINK", code: "CODE", colour: "COLOR", color: "COLOR", text: "TEXT" };
        return all.filter(e => e.preview.toLowerCase().indexOf(q) >= 0
            || (e.pinned && e.text.toLowerCase().indexOf(q) >= 0)
            || kinds[q] === e.kind);
    }

    function age(ts) {
        if (!ts) return "--";
        const s = Math.max(0, Math.floor(Date.now() / 1000) - ts);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }

    // ── Actions ───────────────────────────────────────────
    // copyOnly: put it on the clipboard and stop; otherwise also send the paste keys.
    function paste(e, copyOnly) {
        if (!e) return;
        const src = e.pinned ? 'printf %s "$1" | wl-copy' : 'cliphist decode "$1" | wl-copy';
        const cmd = src + '; shift; [ $# -gt 0 ] && sleep 0.15 && exec "$@"';
        const args = ["sh", "-c", cmd, "_", e.pinned ? e.text : e.id];
        Quickshell.execDetached(copyOnly ? args : args.concat(Config.clipPasteCommand));
    }

    function remove(e) {
        if (!e) return;
        if (e.pinned) {
            const i = parseInt(e.id.slice(4));
            LauncherStore.setPins(LauncherStore.pins.filter((_, k) => k !== i));
            return;
        }
        deleter.command = ["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "_", e.line];
        deleter.running = true;
    }

    // Returns false when the entry cannot be pinned (images).
    function togglePin(e) {
        if (!e) return false;
        if (e.pinned) { root.remove(e); return true; }
        if (e.kind === "IMG") return false;
        const text = root.fullFor === e.id && root.full !== "" ? root.full : e.preview;
        LauncherStore.setPins(LauncherStore.pins.concat([{ text: text, ts: Math.floor(Date.now() / 1000) }]));
        return true;
    }

    // ── Previews ──────────────────────────────────────────
    function want(e) {
        if (!e || e.pinned || e.kind === "IMG") { root.wantId = ""; return; }
        if (root.fullFor === e.id) return;
        root.wantId = e.id;
        wantTimer.restart();
    }

    function thumb(id) {
        if (root.thumbs[id] !== undefined || root.thumbQueue.indexOf(id) >= 0 || root.thumbBusy === id) return;
        root.thumbQueue = root.thumbQueue.concat([id]);
        root.nextThumb();
    }

    function nextThumb() {
        if (thumber.running || root.thumbQueue.length === 0) return;
        root.thumbBusy = root.thumbQueue[0];
        root.thumbQueue = root.thumbQueue.slice(1);
        thumber.command = ["sh", "-c", 'f="$2/$1"; [ -s "$f" ] || cliphist decode "$1" > "$f"', "_", root.thumbBusy, root.thumbDir];
        thumber.running = true;
    }

    // ── Processes ─────────────────────────────────────────
    Process {
        running: true
        command: ["sh", "-c", "command -v cliphist && command -v wl-copy && command -v wl-paste"]
        onExited: code => {
            root.available = code === 0;
            if (root.available) cleaner.running = true;
        }
    }

    Process {
        id: cleaner
        command: ["sh", "-c", 'rm -rf "$1"; mkdir -p "$1"', "_", root.thumbDir]
    }

    Connections {
        target: LauncherStore
        function onLoadedChanged() { root.refresh() }
    }
    onAvailableChanged: refresh()

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Process { id: deleter; onExited: root.refresh() }

    Process {
        id: thumber
        onExited: {
            const t = Object.assign({}, root.thumbs);
            t[root.thumbBusy] = root.thumbDir + "/" + root.thumbBusy;
            root.thumbs = t;
            root.thumbBusy = "";
            root.nextThumb();
        }
    }

    // Keep the history filling while the shell runs. Each store prints a line, which triggers a refresh.
    Process {
        running: root.available && Config.clipWatch
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", "cliphist store && echo 1"]
        stdout: SplitParser { onRead: root.refresh() }
    }
    Process {
        running: root.available && Config.clipWatch
        command: ["wl-paste", "--type", "image", "--watch", "sh", "-c", "cliphist store && echo 1"]
        stdout: SplitParser { onRead: root.refresh() }
    }

    Timer {
        id: wantTimer
        interval: 120
        onTriggered: {
            if (root.wantId === "") return;
            if (decoder.running) return;           // the exit handler asks again
            decoder.target = root.wantId;
            decoder.command = ["sh", "-c", 'echo $(cliphist decode "$1" | wc -c); cliphist decode "$1" | head -c 4096', "_", root.wantId];
            decoder.running = true;
        }
    }

    Process {
        id: decoder
        property string target: ""
        onExited: if (root.wantId !== "" && root.fullFor !== root.wantId) wantTimer.restart()
        stdout: StdioCollector {
            onStreamFinished: {
                const i = text.indexOf("\n");
                if (decoder.target !== root.wantId) return;
                root.fullBytes = parseInt(text.slice(0, i)) || 0;
                root.full = text.slice(i + 1);
                root.fullFor = decoder.target;
            }
        }
    }
}

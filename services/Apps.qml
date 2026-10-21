pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

// Desktop entries plus launch history. History lives in ~/.local/state/deadsignal/usage.json.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/deadsignal"

    // { "<desktop id>": { count: n, last: ms since epoch } }
    property var usage: ({})

    readonly property var entries: {
        const out = [];
        const all = DesktopEntries.applications.values;
        for (let i = 0; i < all.length; i++)
            if (!all[i].noDisplay)
                out.push(all[i]);
        return out;
    }

    function count(entry) { return (root.usage[entry.id] || { count: 0 }).count; }
    function last(entry) { return (root.usage[entry.id] || { last: 0 }).last; }

    // Most recently launched first.
    function recent(n) {
        return root.entries
            .filter(e => root.count(e) > 0)
            .sort((a, b) => root.last(b) - root.last(a))
            .slice(0, n);
    }

    // Pinned apps from Config.pinned, otherwise the most used ones.
    function pinned(n) {
        const cfg = Config.pinned;
        if (cfg.length > 0) {
            const out = [];
            for (let i = 0; i < cfg.length && out.length < n; i++) {
                const want = cfg[i].toLowerCase();
                const hit = root.entries.find(e => e.name.toLowerCase() === want || e.id.toLowerCase() === want);
                if (hit)
                    out.push(hit);
            }
            return out;
        }
        return root.entries
            .filter(e => root.count(e) > 0)
            .sort((a, b) => root.count(b) - root.count(a) || a.name.localeCompare(b.name))
            .slice(0, n);
    }

    function launch(entry) {
        entry.execute();
        const u = Object.assign({}, root.usage);
        const prev = u[entry.id] || { count: 0, last: 0 };
        u[entry.id] = { count: prev.count + 1, last: Date.now() };
        root.usage = u;
        mkdir.running = true;
    }

    FileView {
        id: file
        path: root.stateDir + "/usage.json"
        onLoaded: {
            try {
                root.usage = JSON.parse(file.text());
            } catch (e) {
                root.usage = {};
            }
        }
    }

    // Make sure the state directory exists, then write the file.
    Process {
        id: mkdir
        command: ["mkdir", "-p", root.stateDir]
        onExited: file.setText(JSON.stringify(root.usage))
    }
}

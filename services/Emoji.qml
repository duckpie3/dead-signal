pragma Singleton

import Quickshell
import QtQuick
import qs.theme
import qs.components
import "../launcher/Emoji.js" as Data

// Emoji picker data: categories, search, skin tones, and what to do with the choice.
Singleton {
    id: root

    // groups are emojibase groups: 0 smileys, 1 people, 3 nature, 4 food, 5 travel, 6 activities, 7 objects, 8 symbols, 9 flags
    readonly property var categories: [
        { id: "recent",  name: "Recent",  groups: [],     icon: "M3 12 a9 9 0 1 0 18 0 a9 9 0 1 0 -18 0 M12 7 v5 l3 2" },
        { id: "smileys", name: "Smileys", groups: [0],    icon: "M3 12 a9 9 0 1 0 18 0 a9 9 0 1 0 -18 0 M8 14 s1.5 2 4 2 4 -2 4 -2 M9 9 h.01 M15 9 h.01" },
        { id: "people",  name: "People",  groups: [1],    icon: "M18 11 V6 a2 2 0 0 0 -4 0 v5 M14 10 V4 a2 2 0 0 0 -4 0 v6 M10 10.5 V6 a2 2 0 0 0 -4 0 v8 M18 8 a2 2 0 1 1 4 0 v6 a8 8 0 0 1 -8 8 h-2 c-2.8 0 -4.5 -.86 -5.99 -2.34 l-3.6 -3.6 a2 2 0 0 1 2.83 -2.82 L7 15" },
        { id: "nature",  name: "Nature",  groups: [3],    icon: "M11 20 A7 7 0 0 1 9.8 6.1 C15.5 5 17 4.48 19 2 c1 2 2 4.18 2 8 0 5.5 -4.78 10 -10 10 Z M2 21 c0 -3 1.85 -5.36 5.08 -6 C9.5 14.52 12 13 13 12" },
        { id: "food",    name: "Food",    groups: [4],    icon: "M10 2 v2 M14 2 v2 M6 2 v2 M16 8 a1 1 0 0 1 1 1 v8 a4 4 0 0 1 -4 4 H7 a4 4 0 0 1 -4 -4 V9 a1 1 0 0 1 1 -1 h14 a4 4 0 1 1 0 8 h-1" },
        { id: "travel",  name: "Travel",  groups: [5],    icon: Icons.plane },
        { id: "objects", name: "Objects", groups: [6, 7], icon: "M15 14 c.2 -1 .7 -1.7 1.5 -2.5 1 -.9 1.5 -2.2 1.5 -3.5 A6 6 0 0 0 6 8 c0 1 .2 2.2 1.5 3.5 .7 .7 1.3 1.5 1.5 2.5 M9 18 h6 M10 22 h4" },
        { id: "symbols", name: "Symbols", groups: [8],    icon: "M4 9 h16 M4 15 h16 M10 3 L8 21 M16 3 L14 21" },
        { id: "flags",   name: "Flags",   groups: [9],    icon: "M4 15 s1 -1 4 -1 5 2 8 2 4 -1 4 -1 V3 s-1 1 -4 1 -5 -2 -8 -2 -4 1 -4 1 z M4 22 v-7" }
    ]

    readonly property int tone: LauncherStore.tone
    function setTone(t) { LauncherStore.setTone(t) }

    readonly property var all: Data.DATA.map(r => ({ ch: r[0], name: r[1], tags: r[2], group: r[3], skin: r[4] === 1, code: r[5] }))

    readonly property var byChar: {
        const m = {};
        root.all.forEach(e => { m[e.ch] = e; });
        return m;
    }

    // Emoji for a category, or the search results when `q` is not empty.
    function list(cat, q) {
        q = (q || "").toLowerCase();
        if (q !== "") {
            const out = [];
            for (let i = 0; i < root.all.length; i++) {
                const e = root.all[i];
                let score = 0;
                if (e.name.indexOf(q) === 0 || e.code === q) score = 4;
                else if (e.name.split(" ").some(w => w.indexOf(q) === 0)) score = 3;
                else if (e.name.indexOf(q) >= 0) score = 2;
                else if (e.tags.split(" ").some(w => w.indexOf(q) === 0)) score = 1;
                if (score > 0) out.push({ e: e, score: score });
            }
            out.sort((a, b) => b.score - a.score);
            return out.map(x => x.e);
        }
        if (cat === "recent")
            return LauncherStore.recent.slice(0, 12).map(c => root.byChar[c]).filter(e => e !== undefined);
        const c = root.categories.find(x => x.id === cat);
        return c ? root.all.filter(e => c.groups.indexOf(e.group) >= 0) : [];
    }

    // The emoji with the chosen skin tone applied, where it has tones.
    function glyph(e) {
        if (!e) return "";
        if (!e.skin || root.tone === 0) return e.ch;
        return e.ch.replace(/️/g, "") + String.fromCodePoint(0x1F3FA + root.tone);
    }

    function codepoints(s) {
        s = s.replace(/\uFE0F/g, "");
        const out = [];
        for (let i = 0; i < s.length; i++) {
            const c = s.codePointAt(i);
            out.push("U+" + c.toString(16).toUpperCase());
            if (c > 0xFFFF) i++;                 // skip the low surrogate
        }
        return out.join(" ");
    }

    // Copy it, and type it into the window that had focus. The launcher closes first.
    function insert(e) {
        if (!e) return;
        const g = root.glyph(e);
        LauncherStore.pushRecent(e.ch);
        Quickshell.execDetached(Config.copyCommand.concat([g]));
        Quickshell.execDetached(["sh", "-c", 'sleep 0.12; exec "$@"', "_"].concat(Config.typeCommand).concat([g]));
    }
}

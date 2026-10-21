.pragma library

// Returns { score, idx } or null. idx lists the matched character positions in `name`.
//   substring at the start of the name > at a word start > elsewhere > scattered letters.
// Shorter names win ties.
function match(name, query) {
    const n = name.toLowerCase();
    const q = query.toLowerCase();
    if (q.length === 0)
        return { score: 0, idx: [] };

    const s = n.indexOf(q);
    if (s >= 0) {
        const idx = [];
        for (let i = 0; i < q.length; i++)
            idx.push(s + i);
        const lead = s === 0 ? 100 : (/[\s\-_.]/.test(n[s - 1]) ? 80 : 60);
        return { score: lead - n.length * 0.2, idx: idx };
    }

    const idx = [];
    let from = 0;
    for (let i = 0; i < q.length; i++) {
        const p = n.indexOf(q[i], from);
        if (p < 0)
            return null;
        idx.push(p);
        from = p + 1;
    }
    return { score: 30 - (idx[idx.length - 1] - idx[0]) - n.length * 0.2, idx: idx };
}

function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// Name as StyledText with matched letters in bold + underline.
function highlight(name, idx) {
    if (!idx || idx.length === 0)
        return escapeHtml(name);
    const hit = {};
    idx.forEach(i => { hit[i] = true; });
    let out = "";
    let open = false;
    for (let i = 0; i < name.length; i++) {
        const c = escapeHtml(name[i]);
        if (hit[i] && !open) { out += "<b><u>"; open = true; }
        if (!hit[i] && open) { out += "</u></b>"; open = false; }
        out += c;
    }
    if (open)
        out += "</u></b>";
    return out;
}

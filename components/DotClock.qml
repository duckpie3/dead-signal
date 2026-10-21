import QtQuick
import qs.theme

// 3x5 dot-matrix "HH:MM" display with faint unlit pixels.
Item {
    id: root

    property string text: "00:00"
    property int pixel: 2
    property int gap: 1
    property color lit: Theme.brass
    property color unlit: Theme.steel

    readonly property int step: pixel + gap
    implicitWidth: 17 * step - gap
    implicitHeight: 5 * step - gap

    readonly property var glyphs: ({
        "0": ["111", "101", "101", "101", "111"],
        "1": ["010", "110", "010", "010", "111"],
        "2": ["111", "001", "111", "100", "111"],
        "3": ["111", "001", "111", "001", "111"],
        "4": ["101", "101", "111", "001", "001"],
        "5": ["111", "100", "111", "001", "111"],
        "6": ["111", "100", "111", "101", "111"],
        "7": ["111", "001", "001", "001", "001"],
        "8": ["111", "101", "111", "101", "111"],
        "9": ["111", "101", "111", "001", "111"]
    })

    // Column offsets of the five characters: d d : d d
    readonly property var offsets: [0, 4, 8, 10, 14]

    readonly property var pixels: {
        const out = [];
        const t = (root.text + "00:00").slice(0, 5);
        for (let i = 0; i < 5; i++) {
            const ch = t[i];
            const o = root.offsets[i];
            if (ch === ":") {
                out.push({ c: o, r: 1, on: true });
                out.push({ c: o, r: 3, on: true });
            } else {
                const g = root.glyphs[ch] || root.glyphs["0"];
                for (let r = 0; r < 5; r++)
                    for (let c = 0; c < 3; c++)
                        out.push({ c: o + c, r: r, on: g[r][c] === "1" });
            }
        }
        return out;
    }

    Repeater {
        model: root.pixels
        Rectangle {
            required property var modelData
            x: modelData.c * root.step
            y: modelData.r * root.step
            width: root.pixel
            height: root.pixel
            color: modelData.on ? root.lit : root.unlit
        }
    }
}

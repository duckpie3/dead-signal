import QtQuick
import qs.theme

// Pixel-art weather glyph. kind: clear | partly | cloudy | rain | snow | storm.
Item {
    id: root

    property string kind: "clear"
    property bool night: false
    property int pixel: 4                  // distance between pixel centres
    property int gap: 1                    // empty space between pixels, like the dot-matrix clock
    property int boxW: 56
    property int boxH: 36

    implicitWidth: boxW
    implicitHeight: boxH

    readonly property var sun: ["....#....", ".#..#..#.", "...###...", "..#####..", "#.#####.#", "..#####..", "...###...", ".#..#..#.", "....#...."]
    readonly property var moon: ["..####..", ".##.....", "##......", "##......", "##......", "##......", ".##.....", "..####.."]
    readonly property var cloud: ["....###....", "..#######..", ".#########.", "###########", "###########", ".#########."]
    readonly property var drops: ["..#..#..#..", ".#..#..#..."]
    readonly property var flakes: ["..#..#..#..", "....#..#..."]
    readonly property var bolt: ["..#.", ".##.", "####", "..#.", ".#.."]

    readonly property var layers: {
        const body = night ? moon : sun;
        switch (kind) {
        case "clear":  return [{ m: body, x: 0, y: 0, c: Theme.brass }];
        case "partly": return [{ m: body, x: 0, y: 0, c: Theme.brass }, { m: cloud, x: 3, y: night ? 3 : 4, c: Theme.ash }];
        case "cloudy": return [{ m: cloud, x: 0, y: 0, c: Theme.ash }];
        case "rain":   return [{ m: cloud, x: 0, y: 0, c: Theme.ash }, { m: drops, x: 0, y: 6, c: Theme.teal }];
        case "snow":   return [{ m: cloud, x: 0, y: 0, c: Theme.ash }, { m: flakes, x: 0, y: 6, c: Theme.ivory }];
        case "storm":  return [{ m: cloud, x: 0, y: 0, c: Theme.ash }, { m: bolt, x: 4, y: 3, c: Theme.brass }];
        }
        return [];
    }

    readonly property var pixels: {
        const cells = {};
        let w = 0;
        let h = 0;
        layers.forEach(l => {
            l.m.forEach((row, y) => {
                for (let x = 0; x < row.length; x++)
                    if (row[x] === "#") cells[(x + l.x) + "," + (y + l.y)] = l.c;
            });
            w = Math.max(w, l.x + l.m[0].length);
            h = Math.max(h, l.y + l.m.length);
        });
        const dx = Math.floor((boxW - w * pixel) / 2);
        const dy = Math.floor((boxH - h * pixel) / 2);
        return Object.keys(cells).map(k => {
            const p = k.split(",");
            return { x: Number(p[0]) * pixel + dx, y: Number(p[1]) * pixel + dy, c: cells[k] };
        });
    }

    Repeater {
        model: root.pixels
        Rectangle {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: root.pixel - root.gap
            height: root.pixel - root.gap
            color: modelData.c
        }
    }
}

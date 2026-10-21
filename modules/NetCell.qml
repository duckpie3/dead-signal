import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Network: signal bars, name, latency history, ping.
Cell {
    id: root

    signal toggle()

    interactive: true
    onClicked: m => root.toggle()

    readonly property bool ok: Net.link === "ok"

    function spark() {
        const h = Net.pingHistory.slice(-16).map(v => Math.min(v / 150, 1));
        return new Array(Math.max(0, 16 - h.length)).fill(0).concat(h);
    }

    SignalBars {
        bars: Net.bars
        failed: Net.link === "nolink"
    }

    Txt {
        visible: root.ok
        text: Net.name
        color: Theme.ash
    }

    Mono {
        visible: !root.ok
        text: Net.link === "offline" ? "OFFLINE" : "NO LINK"
        color: Net.link === "offline" ? Theme.dust : Theme.rust
    }

    Spark {
        visible: root.ok
        values: root.spark()
        barW: 2
        minH: 2
        maxH: 11
        colorFn: v => v > 0.66 ? Theme.copper : Theme.teal       // > 100 ms
    }

    Mono {
        visible: root.ok
        Layout.preferredWidth: 34
        horizontalAlignment: Text.AlignRight
        text: Net.pingMs >= 0 ? Math.round(Net.pingMs) + "ms" : "--"
        color: Theme.ash
    }
}

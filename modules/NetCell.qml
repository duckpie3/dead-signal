import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Network: signal bars and ping. The name and latency history are in the popup.
Cell {
    id: root

    signal toggle()

    interactive: true
    onClicked: m => root.toggle()

    readonly property bool ok: Net.link === "ok"

    SignalBars {
        bars: Net.bars
        failed: Net.link === "nolink"
    }

    Mono {
        visible: !root.ok
        text: Net.link === "offline" ? "OFFLINE" : "NO LINK"
        color: Net.link === "offline" ? Theme.dust : Theme.rust
    }

    Mono {
        visible: root.ok
        text: Net.pingMs >= 0 ? Math.round(Net.pingMs) + "ms" : "--"
        color: Theme.ash
    }
}

import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Bluetooth: icon, and the number of connected devices. A copper pixel when one is nearly flat.
// Hidden on machines without an adapter.
Cell {
    id: root

    signal toggle()

    visible: Bt.present
    interactive: true
    spacing: 7
    onClicked: m => root.toggle()

    Glyph {
        path: Icons.bluetooth
        color: !Bt.on ? Theme.dust : Bt.count > 0 ? Theme.teal : Theme.ash
    }

    Mono {
        visible: Bt.on && Bt.count > 0
        text: String(Bt.count).padStart(2, "0")
    }

    Rectangle {
        visible: Bt.on && Bt.low
        parent: root
        x: 6
        y: 5
        width: 2
        height: 2
        color: Theme.copper
    }
}

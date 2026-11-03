import QtQuick
import qs.config
import qs.components

Cell {
    id: root

    signal toggle()

    interactive: true
    hPad: 6
    onClicked: m => root.toggle()

    Glyph {
        path: Icons.power
        color: Theme.ash
    }
}

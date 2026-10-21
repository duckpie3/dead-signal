import QtQuick
import qs.theme
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

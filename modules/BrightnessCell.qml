import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Backlight (icon and percent; the meter lives in the popup). Click opens the display popup; scroll: ±5 %. A moon and a brass pixel while night light is on.
// Hidden when there is no backlight device.
Cell {
    id: root

    signal toggle()

    visible: Brightness.available
    interactive: true

    onClicked: m => root.toggle()
    onWheeled: w => Brightness.step(w.angleDelta.y > 0 ? 5 : -5)

    Glyph {
        path: NightLight.on ? Icons.moon : Icons.sun
        color: NightLight.on ? Theme.brass : Theme.ash
    }

    Mono {
        text: Brightness.percent + "%"
    }

    Rectangle {
        visible: NightLight.on
        parent: root
        x: 6
        y: 5
        width: 2
        height: 2
        color: Theme.brass
    }
}

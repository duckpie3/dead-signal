import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Backlight. Click opens the display popup; scroll: ±5 %. A moon and a brass pixel while night light is on.
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

    SegMeter {
        count: 10
        onColor: Theme.brass
        filled: Math.ceil(Brightness.percent / 10)
    }

    Mono {
        Layout.preferredWidth: 32
        horizontalAlignment: Text.AlignRight
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

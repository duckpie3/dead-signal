import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Backlight. Scroll: ±5 %. Hidden when there is no backlight device.
Cell {
    id: root

    visible: Brightness.available
    interactive: true

    onWheeled: w => Brightness.step(w.angleDelta.y > 0 ? 5 : -5)

    Glyph { path: Icons.sun; color: Theme.ash }

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
}

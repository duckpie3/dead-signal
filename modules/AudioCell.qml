import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Volume. Left click: popup. Middle/right click: mute. Scroll: ±5 %.
Cell {
    id: root

    signal toggle()

    interactive: true

    readonly property bool over: Audio.hasSink && !Audio.muted && Audio.volume > 1.0
    readonly property bool dim: !Audio.hasSink || Audio.muted
    readonly property color tint: dim ? Theme.dust : (over ? Theme.copper : Theme.teal)

    onClicked: m => {
        if (m.button === Qt.LeftButton) root.toggle();
        else Audio.toggleMute();
    }
    onWheeled: w => Audio.step(w.angleDelta.y > 0 ? 0.05 : -0.05)

    Glyph {
        path: Audio.muted ? Icons.volumeOff : Icons.volume
        color: root.tint
    }

    SegMeter {
        count: 12
        warnFrom: 8                       // past 100 %
        onColor: Theme.teal
        filled: root.dim ? 0 : Math.ceil(Audio.volume / Audio.maxVolume * 12)
    }

    Mono {
        Layout.preferredWidth: 32
        horizontalAlignment: Text.AlignRight
        text: !Audio.hasSink ? "--" : (Audio.muted ? "MUTE" : Math.round(Audio.volume * 100) + "%")
        color: root.dim ? Theme.dust : (root.over ? Theme.copper : Theme.ivory)
    }
}

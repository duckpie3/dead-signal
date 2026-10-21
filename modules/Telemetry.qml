import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// CPU and memory: label, 8-segment meter, value. Copper only past 85 %.
Cell {
    id: root

    signal toggle()

    interactive: true
    onClicked: m => root.toggle()

    spacing: 10

    component Reading: RowLayout {
        id: r
        property string label: ""
        property real value: 0
        spacing: 6

        Lb { text: r.label }
        SegMeter {
            count: 8
            segW: 2
            segH: 8
            spacing: 1
            filled: Math.ceil(r.value * 8)
            onColor: r.value > 0.85 ? Theme.copper : Theme.ash
        }
        Mono {
            Layout.preferredWidth: 22
            horizontalAlignment: Text.AlignRight
            text: Math.round(r.value * 100)
            color: r.value > 0.85 ? Theme.copper : Theme.ivory
        }
    }

    Reading { label: "CPU"; value: Stats.cpu }
    Reading { label: "MEM"; value: Stats.mem }
}

import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// Battery: five segments, percentage, state tag. Hidden on machines without a battery.
Cell {
    id: root

    signal toggle()

    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0
    readonly property bool charging: !!dev && (dev.state === UPowerDeviceState.Charging
                                              || dev.state === UPowerDeviceState.PendingCharge)
    readonly property color tint: charging ? Theme.sage
                                : pct <= 10 ? Theme.rust
                                : pct <= 25 ? Theme.copper
                                : Theme.brass

    visible: !!dev && (dev.isLaptopBattery || dev.energyCapacity > 0)
    interactive: true
    onClicked: m => root.toggle()

    RowLayout {
        spacing: 2

        SegMeter {
            count: 5
            segW: 4
            segH: 10
            filled: Math.ceil(root.pct / 20)
            onColor: root.tint
        }
        Rectangle {                      // terminal
            implicitWidth: 2
            implicitHeight: 4
            color: Theme.steel
        }
    }

    Mono {
        Layout.preferredWidth: 32
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.pct) + "%"
    }

    Lb {
        visible: root.charging
        text: "CHG"
        color: Theme.sage
    }

    Lb {
        visible: !root.charging && root.pct <= 10
        text: "CRIT"
        color: Theme.rust
    }
}

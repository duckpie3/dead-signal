import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// Brightness, Bluetooth and network in one cell, with a thin divider between them.
// Each part still opens its own popup. Parts without hardware hide themselves.
Item {
    id: root

    property alias brightItem: bright
    property alias btItem: bt
    property alias netItem: net

    signal toggleDisplay()
    signal toggleBluetooth()
    signal toggleNet()

    readonly property var shown: [bright, bt, net].filter(c => c.visible)

    implicitHeight: Theme.cellHeight
    implicitWidth: row.implicitWidth
    visible: shown.length > 0

    Chamfer { anchors.fill: parent; cut: Theme.cut; fillColor: Theme.panel }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0

        BrightnessCell {
            id: bright
            grouped: true
            hPad: 9
            groupFirst: root.shown[0] === bright
            groupLast: root.shown[root.shown.length - 1] === bright
            onToggle: root.toggleDisplay()
        }

        BluetoothCell {
            id: bt
            grouped: true
            hPad: 9
            groupFirst: root.shown[0] === bt
            groupLast: root.shown[root.shown.length - 1] === bt
            onToggle: root.toggleBluetooth()
        }

        NetCell {
            id: net
            grouped: true
            hPad: 9
            groupFirst: root.shown[0] === net
            groupLast: root.shown[root.shown.length - 1] === net
            onToggle: root.toggleNet()
        }
    }
}

import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// One Bluetooth device: state marker, name and kind, battery or an action word. Click connects,
// disconnects or pairs.
Item {
    id: root

    required property var dev

    readonly property bool busy: !!dev.pairing || dev.state === BluetoothDeviceState.Connecting
    readonly property int pct: Bt.percent(dev)

    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    implicitHeight: 40
    activeFocusOnTab: true

    Keys.onReturnPressed: Bt.activate(root.dev)
    Keys.onEnterPressed: Bt.activate(root.dev)
    Keys.onSpacePressed: Bt.activate(root.dev)
    Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()
    Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        color: mouse.containsMouse ? Theme.steel : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animMs } }
    }
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.ivory
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Rectangle {
            implicitWidth: 6
            implicitHeight: 6
            color: root.dev.connected ? Theme.teal : root.busy ? Theme.brass : "transparent"
            border.width: root.dev.connected || root.busy ? 0 : 1
            border.color: Theme.dust
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Txt {
                Layout.fillWidth: true
                text: Bt.nameOf(root.dev)
                color: root.dev.connected ? Theme.ivory : Theme.ash
                elide: Text.ElideRight
            }
            Lb { text: Bt.kind(root.dev) }
        }

        RowLayout {
            visible: root.dev.connected && root.pct >= 0
            spacing: 8
            SegMeter {
                count: 5
                segW: 4
                segH: 9
                filled: Math.ceil(root.pct / 20)
                onColor: root.pct <= 20 ? Theme.copper : Theme.sage
            }
            Mono {
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
                text: root.pct + "%"
                font.pixelSize: 10
                color: root.pct <= 20 ? Theme.copper : Theme.ash
            }
        }

        Lb {
            visible: !(root.dev.connected && root.pct >= 0)
            text: root.dev.connected ? "Connected"
                : root.busy ? (root.dev.paired ? "Connecting" : "Pairing")
                : root.dev.paired ? "Connect" : "Pair"
            color: root.busy ? Theme.brass : root.dev.connected ? Theme.teal : Theme.dust
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Bt.activate(root.dev)
    }
}

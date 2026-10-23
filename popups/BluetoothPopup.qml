import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

Popup {
    id: root

    panelWidth: 340

    // Look for devices only while this popup is open.
    onOpenChanged: Bt.setScan(root.open)

    component Head: RowLayout {
        property string title: ""
        property string note: ""
        property color noteColor: Theme.dust
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 6
        Layout.bottomMargin: 2
        Lb { text: parent.title; Layout.fillWidth: true }
        Lb { text: parent.note; color: parent.noteColor; visible: text !== "" }
    }

    PopupHeader {
        title: "Bluetooth"
        tint: Theme.teal
        status: !Bt.on ? "Off" : Bt.count > 0 ? Bt.count + " connected" : "On"
        statusColor: !Bt.on ? Theme.dust : Bt.count > 0 ? Theme.teal : Theme.ash
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Txt { text: "Adapter"; font.pixelSize: 13; Layout.fillWidth: true }
            Lb { text: !Bt.on ? "Powered off" : Bt.scanning ? "Visible · scanning" : "Visible"; Layout.fillWidth: true }
        }

        Toggle {
            checked: Bt.on
            onColor: Theme.teal
            onToggled: Bt.setOn(!Bt.on)
        }
    }

    Divider {}

    Item {
        visible: !Bt.on
        Layout.fillWidth: true
        implicitHeight: 66
        Lb { anchors.centerIn: parent; text: "Bluetooth is off" }
    }

    ColumnLayout {
        visible: Bt.on
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 0

        // Connected
        ColumnLayout {
            visible: Bt.connected.length > 0
            Layout.fillWidth: true
            spacing: 0
            Head { title: "Connected"; note: String(Bt.count).padStart(2, "0"); noteColor: Theme.teal }
            Repeater {
                model: Bt.connected
                BtRow { required property var modelData; dev: modelData }
            }
        }

        // Paired
        ColumnLayout {
            visible: Bt.paired.length > 0
            Layout.fillWidth: true
            spacing: 0
            Head { title: "Paired" }
            Repeater {
                model: Bt.paired.slice(0, 8)
                BtRow { required property var modelData; dev: modelData }
            }
        }

        // Nearby, while scanning
        ColumnLayout {
            visible: Bt.scanning && Bt.nearby.length > 0
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 6
                Layout.bottomMargin: 2
                Lb { text: "Available"; Layout.fillWidth: true }

                // Scan indicator: one square sweeping along a short rail.
                Item {
                    implicitWidth: 30
                    implicitHeight: 6
                    Rectangle { anchors.fill: parent; color: Theme.steel }
                    Rectangle {
                        id: sweeper
                        width: 6
                        height: 6
                        color: Theme.ivory
                        SequentialAnimation on x {
                            running: Bt.scanning && root.open && !Theme.reduceMotion
                            loops: Animation.Infinite
                            NumberAnimation { from: 0; to: 24; duration: 700 }
                            NumberAnimation { from: 24; to: 0; duration: 700 }
                        }
                    }
                }
            }

            Repeater {
                model: Bt.nearby.slice(0, 6)
                BtRow { required property var modelData; dev: modelData }
            }
        }

        Divider { Layout.topMargin: 6 }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 10
            Layout.bottomMargin: 12

            Lb { text: Bt.scanning ? "Scanning for devices" : "Not scanning"; Layout.fillWidth: true }
            ModeTab {
                Layout.preferredWidth: 84
                label: Bt.scanning ? "Stop" : "Scan"
                onClicked: Bt.setScan(!Bt.scanning)
            }
        }
    }
}

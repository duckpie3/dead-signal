import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

Popup {
    id: root

    panelWidth: 304

    readonly property bool over: !Audio.muted && Audio.volume > 1.0

    PopupHeader {
        title: "Audio"
        tint: Theme.teal
        status: "PipeWire"
    }

    // ── Output ─────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Lb { text: "Output"; Layout.fillWidth: true }
            Mono {
                text: Audio.muted ? "MUTE" : Math.round(Audio.volume * 100)
                font.pixelSize: 28
                color: Audio.muted ? Theme.dust : (root.over ? Theme.copper : Theme.ivory)
            }
            Mono {
                visible: !Audio.muted
                text: "%"
                font.pixelSize: 13
                color: Theme.dust
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 3
            }
        }

        SegSlider {
            Layout.fillWidth: true
            from: 0
            to: Audio.maxVolume
            value: Audio.volume
            warnFrom: 1.0
            onMoved: v => Audio.setVolume(v)
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 12

            Mono { x: 0; text: "0"; font.pixelSize: 9; color: Theme.dust }
            Mono {
                x: parent.width / Audio.maxVolume - width / 2
                text: "100"
                font.pixelSize: 9
                color: Theme.dust
            }
            Mono {
                anchors.right: parent.right
                text: "150"
                font.pixelSize: 9
                color: Theme.copper
            }
        }
    }

    Divider {}

    // ── Output device ──────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        Layout.bottomMargin: 4
        spacing: 0

        Lb {
            text: "Output device"
            Layout.leftMargin: 16
            Layout.bottomMargin: 4
        }

        Repeater {
            model: Audio.sinks

            MenuRow {
                required property var modelData
                marker: true
                selected: modelData === Audio.sink
                label: Audio.label(modelData)
                hint: Audio.kind(modelData)
                textColor: selected ? Theme.ivory : Theme.ash
                onTriggered: Audio.select(modelData)
            }
        }
    }

    Divider {}

    // ── Input ──────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 10
        Layout.bottomMargin: 12
        spacing: 6
        visible: Audio.hasSource

        RowLayout {
            Layout.fillWidth: true
            Lb { text: "Input"; Layout.fillWidth: true }
            Mono {
                text: Math.round(Audio.micVolume * 100) + "%"
                color: Audio.micMuted ? Theme.dust : Theme.ivory
            }
        }

        SegSlider {
            Layout.fillWidth: true
            from: 0
            to: 1
            value: Audio.micVolume
            color: Audio.micMuted ? Theme.dust : Theme.teal
            onMoved: v => Audio.setMic(v)
        }

        RowLayout {
            Layout.fillWidth: true

            Txt {
                Layout.fillWidth: true
                text: Audio.label(Audio.source)
                color: Theme.dust
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            // LIVE / MUTED toggle
            Rectangle {
                id: micTag
                implicitWidth: micLabel.implicitWidth + 12
                implicitHeight: 18
                color: micMouse.containsMouse ? Theme.steel : "transparent"
                border.width: 1
                border.color: micTag.activeFocus ? Theme.ivory : Theme.steel
                activeFocusOnTab: true
                Keys.onReturnPressed: Audio.toggleMic()
                Keys.onSpacePressed: Audio.toggleMic()

                Lb {
                    id: micLabel
                    anchors.centerIn: parent
                    text: Audio.micMuted ? "Muted" : "Live"
                    color: Audio.micMuted ? Theme.dust : Theme.sage
                }

                MouseArea {
                    id: micMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Audio.toggleMic()
                }
            }
        }
    }
}

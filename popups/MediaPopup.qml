import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.components
import qs.services

Popup {
    id: root

    panelWidth: 340

    // Nothing left to control: close.
    Connections {
        target: Media
        function onPresentChanged() { if (!Media.present) root.dismissed() }
    }

    component PlayerTab: Item {
        id: tab
        property var player
        readonly property bool active: Media.current === player

        Layout.fillWidth: true
        implicitHeight: 24

        Rectangle { anchors.fill: parent; color: tab.active || tabMouse.containsMouse ? Theme.steel : "transparent"; opacity: tab.active ? 1 : 0.6 }
        Rectangle { visible: tab.active; width: parent.width; height: 2; color: Theme.copper }

        Row {
            anchors.centerIn: parent
            spacing: 7
            Rectangle {
                width: 4; height: 4
                anchors.verticalCenter: parent.verticalCenter
                color: tab.player && tab.player.isPlaying ? Theme.teal : Theme.steel
            }
            Lb { text: tab.player ? tab.player.identity : ""; color: tab.active ? Theme.ivory : Theme.dust }
        }

        MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Media.pick(tab.player)
        }
    }

    PopupHeader {
        title: "Media"
        tint: Theme.teal
        status: Media.playing ? "Playing" : "Paused"
        statusColor: Media.playing ? Theme.teal : Theme.dust
    }

    // ── Players (only when there are several) ──────────────
    RowLayout {
        visible: Media.players.length > 1
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 12
        spacing: 1

        Repeater {
            model: Media.players
            PlayerTab { required property var modelData; player: modelData }
        }
    }

    // ── Track ──────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 14
        spacing: 14

        // Cover art, shown at 2x for a sharp picture.
        Item {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 96
            implicitHeight: 96

            Chamfer { anchors.fill: parent; cut: 9; fillColor: Theme.steel }
            Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 8; fillColor: Theme.bg }

            Image {
                id: art
                x: 1; y: 1
                width: 94; height: 94
                visible: false
                source: Media.art
                sourceSize: Qt.size(192, 192)
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                asynchronous: true
            }
            Item {
                id: artMask
                x: 1; y: 1
                width: 94; height: 94
                visible: false
                layer.enabled: true
                Chamfer { anchors.fill: parent; cut: 8; fillColor: "white" }
            }
            MultiEffect {
                x: 1; y: 1
                width: 94; height: 94
                visible: art.status === Image.Ready
                source: art
                autoPaddingEnabled: false
                maskEnabled: true
                maskSource: artMask
            }
            Glyph {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                path: Icons.play
                size: 28
                color: Theme.steel
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 4

            Txt {
                Layout.fillWidth: true
                text: Media.title
                font.pixelSize: 15
                font.weight: Font.Medium
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Txt {
                visible: Media.artist !== ""
                Layout.fillWidth: true
                text: Media.artist
                font.pixelSize: 13
                color: Theme.ash
                elide: Text.ElideRight
            }
            Lb {
                visible: Media.album !== ""
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: Media.album
                elide: Text.ElideRight
            }
        }
    }

    // ── Progress ───────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        spacing: 2

        SegSlider {
            Layout.fillWidth: true
            enabled: Media.canSeek
            opacity: Media.len > 0 ? 1 : 0.4
            from: 0
            to: Math.max(1, Media.len)
            step: 5
            value: Media.pos
            color: Theme.teal
            onMoved: v => Media.seek(v)
        }

        RowLayout {
            Layout.fillWidth: true
            Mono { text: Media.fmt(Media.pos); font.pixelSize: 10; color: Theme.ash; Layout.fillWidth: true }
            Mono { text: Media.len > 0 ? "-" + Media.fmt(Media.len - Media.pos) : "--:--"; font.pixelSize: 10; color: Theme.dust }
        }
    }

    // ── Transport ──────────────────────────────────────────
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 12
        Layout.bottomMargin: 16
        spacing: 10

        ChamferButton {
            path: Icons.shuffle
            enabled: Media.shuffleSupported
            color: Media.shuffle ? Theme.teal : Theme.ash
            mark: Media.shuffle ? Theme.copper : "transparent"
            onClicked: Media.toggleShuffle()
        }
        ChamferButton {
            path: Icons.prev
            enabled: Media.canPrev
            onClicked: Media.prev()
        }
        ChamferButton {
            big: true
            path: Media.playing ? Icons.pause : Icons.play
            enabled: Media.canToggle
            bar: Media.playing ? Theme.teal : Theme.copper
            onClicked: Media.toggle()
        }
        ChamferButton {
            path: Icons.next
            enabled: Media.canNext
            onClicked: Media.next()
        }
        ChamferButton {
            path: Icons.repeat
            enabled: Media.repeatSupported
            color: Media.repeat !== "off" ? Theme.teal : Theme.ash
            mark: Media.repeat !== "off" ? Theme.copper : "transparent"
            badge: Media.repeat === "one" ? "1" : ""
            onClicked: Media.cycleRepeat()
        }
    }

    Divider { visible: Media.canRaise }

    MenuRow {
        visible: Media.canRaise
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        glyph: Icons.external
        label: "Open " + Media.player
        hint: "Raise"
        onTriggered: { Media.raise(); root.dismissed() }
    }
}

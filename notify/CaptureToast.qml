import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Result of a screenshot or colour pick, styled like a notification toast.
Item {
    id: root

    readonly property var t: Capture.toast
    readonly property string kind: t ? t.kind : ""

    visible: t !== null
    width: 360
    implicitWidth: 360
    implicitHeight: visible ? body.implicitHeight + 2 : 0

    Chamfer { anchors.fill: parent; cut: 8; fillColor: Theme.steel }
    Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 7; fillColor: Theme.panel }

    HoverHandler { onHoveredChanged: Capture.toastPaused = hovered }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Capture.closeToast()
    }

    ColumnLayout {
        id: body
        x: 1
        y: 1
        width: parent.width - 2
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 8
            Layout.topMargin: 10
            spacing: 8

            Rectangle { implicitWidth: 6; implicitHeight: 6; color: root.kind === "error" ? Theme.rust : Theme.sage }
            Lb {
                Layout.fillWidth: true
                text: root.kind === "color" ? "Colour picker" : root.kind === "error" ? "Capture" : "Screenshot"
            }
            IconButton { path: Icons.close; onClicked: Capture.closeToast() }
        }

        // ── Screenshot ────────────────────────────────────
        Txt {
            visible: root.kind === "shot" || root.kind === "error"
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 2
            text: root.t && root.t.title ? root.t.title : ""
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        RowLayout {
            visible: root.kind === "shot"
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 8
            spacing: 12

            // Small, hard-edged preview.
            Item {
                implicitWidth: 76
                implicitHeight: 48
                Rectangle { anchors.fill: parent; color: Theme.bg; border.width: 1; border.color: Theme.steel }
                Image {
                    x: 1
                    y: 1
                    width: parent.width - 2
                    height: parent.height - 2
                    source: root.kind === "shot" ? "file://" + root.t.file : ""
                    sourceSize.width: 76
                    sourceSize.height: 48
                    fillMode: Image.PreserveAspectCrop
                    smooth: false
                    cache: false
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Mono { Layout.fillWidth: true; text: root.t && root.t.name ? root.t.name : ""; elide: Text.ElideMiddle }
                Mono {
                    text: root.kind === "shot" ? root.t.w + " × " + root.t.h + " · copied" : ""
                    color: Theme.ash
                    font.pixelSize: 10
                }
            }
        }

        RowLayout {
            visible: root.kind === "shot"
            Layout.leftMargin: 14
            Layout.topMargin: 10
            spacing: 6
            ActionButton { label: "Open"; primary: true; onClicked: { Capture.openFile(root.t.file); Capture.closeToast(); } }
            ActionButton { label: "Folder"; onClicked: { Capture.openFolder(); Capture.closeToast(); } }
            ActionButton { label: "Delete"; onClicked: { Capture.deleteFile(root.t.file); Capture.closeToast(); } }
        }

        // ── Colour ────────────────────────────────────────
        RowLayout {
            visible: root.kind === "color"
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 6
            spacing: 14

            Item {
                implicitWidth: 56
                implicitHeight: 56
                Chamfer { anchors.fill: parent; cut: 6; fillColor: Theme.steel }
                Chamfer {
                    anchors.fill: parent
                    anchors.margins: 1
                    cut: 5
                    fillColor: root.kind === "color" ? Qt.rgba(root.t.r / 255, root.t.g / 255, root.t.b / 255, 1) : "transparent"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Txt {
                    text: root.kind === "color" ? "Copied " + root.t.hex : ""
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
                Mono { text: root.kind === "color" ? root.t.rgb : ""; color: Theme.ash; font.pixelSize: 10 }
                Mono { text: root.kind === "color" ? root.t.hsl : ""; color: Theme.ash; font.pixelSize: 10 }
            }
        }

        RowLayout {
            visible: root.kind === "color"
            Layout.leftMargin: 14
            Layout.topMargin: 10
            spacing: 6
            ActionButton { label: "Copy RGB"; primary: true; onClicked: { Capture.copyText(root.t.rgb); Capture.closeToast(); } }
            ActionButton { label: "Copy HSL"; onClicked: { Capture.copyText(root.t.hsl); Capture.closeToast(); } }
        }

        // ── Error ─────────────────────────────────────────
        Txt {
            visible: root.kind === "error"
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 3
            text: root.t && root.t.text ? root.t.text : ""
            color: Theme.ash
            wrapMode: Text.Wrap
        }

        // ── Countdown: 30 segments, drained from the right ─
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 10
            Layout.bottomMargin: 11
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: 30
                    Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 2
                        color: index < Math.ceil(Capture.toastLeft / Capture.toastTotal * 30) ? Theme.ash : Theme.steel
                    }
                }
            }

            Lb {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: Math.ceil(Capture.toastLeft / 1000) + "s"
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.components
import qs.services

// One clipboard entry: type chip (thumbnail or swatch for images and colours), a one-line preview
// with the match underlined, a detail line, type label and age.
Item {
    id: root

    required property var entry            // see Clip.makeEntry
    property bool selected: false
    property string query: ""

    signal hovered()
    signal activated()

    readonly property var kindColors: ({ TEXT: Theme.ash, LINK: Theme.teal, CODE: Theme.brass, IMG: Theme.sage, COLOR: Theme.ivory })
    readonly property var kindNames: ({ TEXT: "TEXT", LINK: "LINK", CODE: "CODE", IMG: "IMAGE", COLOR: "COLOUR" })
    readonly property bool mono: entry.kind === "CODE" || entry.kind === "LINK" || entry.kind === "COLOR"
    readonly property string thumb: entry.kind === "IMG" && Clip.thumbs[entry.id] !== undefined ? Clip.thumbs[entry.id] : ""

    Layout.fillWidth: true
    implicitHeight: 40

    Component.onCompleted: if (entry.kind === "IMG") Clip.thumb(entry.id)
    onEntryChanged: if (entry.kind === "IMG") Clip.thumb(entry.id)

    function rgb(hex) {
        let h = hex.slice(1);
        if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
        const n = parseInt(h, 16);
        return [n >> 16, (n >> 8) & 255, n & 255];
    }

    readonly property string meta: {
        const e = entry;
        if (e.kind === "IMG") return "Image · " + e.w + "×" + e.h + " · " + e.size;
        if (e.kind === "COLOR") return "Colour · rgb(" + root.rgb(e.preview).join(", ") + ")";
        if (e.kind === "LINK") return "Link · " + e.preview.replace(/^\w+:\/\//, "").split("/")[0];
        if (e.kind === "CODE") return "Code";
        return "Text · " + (e.text !== "" ? e.text.length : e.preview.length) + (e.preview.length >= 100 ? "+" : "") + " chars";
    }

    // Underline the match inside the first 110 characters.
    readonly property string shown: entry.kind === "IMG" ? entry.preview.replace(/^\[\[ | \]\]$/g, "") : entry.preview.slice(0, 110)
    readonly property int at: query !== "" ? shown.toLowerCase().indexOf(query.toLowerCase()) : -1

    function esc(t) { return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;") }
    readonly property string rich: {
        if (at < 0) return esc(shown);
        const end = at + query.length;
        return esc(shown.slice(0, at)) + "<u><font color=\"" + Theme.ivory + "\">" + esc(shown.slice(at, end)) + "</font></u>" + esc(shown.slice(end));
    }

    Rectangle {
        anchors.fill: parent
        color: root.selected || mouse.containsMouse ? Theme.steel : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animMs } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 16
        spacing: 12

        Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            color: root.selected ? Theme.copper : "transparent"
        }

        // Chip
        Item {
            implicitWidth: 28
            implicitHeight: 28

            Chamfer {
                anchors.fill: parent
                cut: 4
                fillColor: root.entry.kind === "COLOR" ? root.entry.preview : Theme.bg
            }

            Image {
                id: img
                anchors.fill: parent
                visible: false
                source: root.thumb !== "" ? "file://" + root.thumb : ""
                sourceSize: Qt.size(12, 8)
                fillMode: Image.PreserveAspectCrop
                smooth: false
                asynchronous: true
            }
            Item {
                id: mask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Chamfer { anchors.fill: parent; cut: 4; fillColor: "white" }
            }
            MultiEffect {
                anchors.fill: parent
                visible: img.status === Image.Ready
                source: img
                autoPaddingEnabled: false
                maskEnabled: true
                maskSource: mask
            }

            Text {
                anchors.centerIn: parent
                visible: root.entry.kind !== "COLOR" && !(root.entry.kind === "IMG" && img.status === Image.Ready)
                text: root.entry.kind === "LINK" ? "↗" : root.entry.kind === "CODE" ? "{}" : root.entry.kind === "IMG" ? "▦" : "T"
                color: Theme.ash
                font.family: Theme.mono
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            // Pinned: a brass pixel.
            Rectangle {
                visible: root.entry.pinned
                x: parent.width - 5
                y: 3
                width: 2
                height: 2
                color: Theme.brass
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: root.rich
                color: root.selected ? Theme.ivory : Theme.ash
                font.family: root.mono ? Theme.mono : Theme.sans
                font.pixelSize: root.mono ? 12 : 13
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: root.meta
                color: Theme.dust
                font.family: Theme.sans
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.preferredWidth: 62
            spacing: 6

            Rectangle {
                implicitWidth: 4
                implicitHeight: 4
                color: root.kindColors[root.entry.kind] || Theme.ash
            }
            Lb { text: root.kindNames[root.entry.kind] }
        }

        Mono {
            Layout.preferredWidth: 26
            horizontalAlignment: Text.AlignRight
            text: Clip.age(root.entry.ts)
            font.pixelSize: 11
            color: Theme.dust
        }

        Glyph {
            path: Icons.enter
            color: Theme.ash
            opacity: root.selected ? 1 : 0
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.hovered()
        onClicked: root.activated()
    }
}

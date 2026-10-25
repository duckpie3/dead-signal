import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.components
import qs.services

// The selected clipboard entry in full: its text (first four lines), or the picture / swatch,
// with type, size and age on the right.
Item {
    id: root

    required property var entry

    Layout.fillWidth: true
    Layout.leftMargin: 14
    Layout.rightMargin: 14
    Layout.bottomMargin: 8
    implicitHeight: Math.max(76, content.implicitHeight + 24)

    readonly property bool isImg: entry.kind === "IMG"
    readonly property bool isColor: entry.kind === "COLOR"
    readonly property bool loaded: Clip.fullFor === entry.id
    readonly property string body: entry.pinned ? entry.text : (loaded ? Clip.full : entry.preview)
    readonly property string thumb: isImg && Clip.thumbs[entry.id] !== undefined ? Clip.thumbs[entry.id] : ""

    function rgb(hex) {
        let h = hex.slice(1);
        if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
        const n = parseInt(h, 16);
        return [n >> 16, (n >> 8) & 255, n & 255];
    }

    function bytes(n) { return n < 1024 ? n + " B" : (n / 1024).toFixed(1) + " KB" }

    readonly property string sizeText: {
        if (isImg) return entry.size;
        if (entry.pinned) return bytes(entry.text.length);
        return loaded ? bytes(Clip.fullBytes) : "--";
    }

    Chamfer { anchors.fill: parent; cut: 6; fillColor: Theme.bg }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 14

            Text {
                visible: !root.isImg
                Layout.fillWidth: true
                text: root.isColor ? root.entry.preview.toUpperCase() + "\nrgb(" + root.rgb(root.entry.preview).join(", ") + ")" : root.body
                color: Theme.ivory
                font.family: Theme.mono
                font.pixelSize: 11
                lineHeight: 1.45
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            Rectangle {
                visible: root.isColor
                implicitWidth: 112
                implicitHeight: 52
                color: root.isColor ? root.entry.preview : "transparent"
                border.width: 1
                border.color: Theme.steel
            }

            // Pictures are shrunk to a coarse grid, like cover art.
            Item {
                visible: root.isImg
                implicitWidth: 112
                implicitHeight: 63

                Image {
                    anchors.fill: parent
                    source: root.thumb !== "" ? "file://" + root.thumb : ""
                    sourceSize: Qt.size(56, 32)
                    fillMode: Image.PreserveAspectFit
                    smooth: false
                    asynchronous: true
                }
                Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Theme.steel }
            }
        }

        GridLayout {
            Layout.alignment: Qt.AlignTop
            columns: 2
            columnSpacing: 12
            rowSpacing: 5

            Lb { text: "Type" }
            Mono { Layout.alignment: Qt.AlignRight; font.pixelSize: 10; text: ({ TEXT: "Text", LINK: "Link", CODE: "Code", IMG: "Image", COLOR: "Colour" })[root.entry.kind] }
            Lb { text: "Size" }
            Mono { Layout.alignment: Qt.AlignRight; font.pixelSize: 10; text: root.sizeText }
            Lb { text: "Copied" }
            Mono { Layout.alignment: Qt.AlignRight; font.pixelSize: 10; text: root.entry.ts ? Clip.age(root.entry.ts) + " ago" : "--" }
        }
    }
}

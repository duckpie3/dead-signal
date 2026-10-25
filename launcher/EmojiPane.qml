import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.components
import qs.services

// Emoji mode: category strip, a 12 x 4 grid that scrolls by rows, and the selected emoji in detail.
ColumnLayout {
    id: root

    property var items: []
    property int sel: 0
    property string cat: "smileys"
    property string query: ""

    signal hovered(int i)
    signal activated(int i)
    signal catPicked(string id)

    readonly property int cols: 12
    readonly property int rows: 4
    readonly property int count: items.length
    readonly property int sIdx: Math.min(sel, Math.max(0, count - 1))
    readonly property int totalRows: Math.max(1, Math.ceil(count / cols))
    readonly property int rowOff: Math.max(0, Math.min(Math.floor(sIdx / cols) - (rows - 1), totalRows - rows))
    readonly property var cur: count > 0 ? items[sIdx] : null
    readonly property string catName: (Emoji.categories.find(c => c.id === cat) || { name: "" }).name

    spacing: 0
    Layout.fillWidth: true

    // ── Categories ────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        Layout.topMargin: 10
        spacing: 1
        opacity: root.query !== "" ? 0.35 : 1

        Repeater {
            model: Emoji.categories
            Item {
                id: tab
                required property var modelData
                readonly property bool active: root.query === "" && root.cat === modelData.id
                implicitWidth: 30
                implicitHeight: 28

                Rectangle { anchors.fill: parent; color: tab.active || tabMouse.containsMouse ? Theme.steel : "transparent" }
                Rectangle { visible: tab.active; width: parent.width; height: 2; color: Theme.copper }
                Glyph { anchors.centerIn: parent; path: tab.modelData.icon; size: 15; color: tab.active ? Theme.ivory : Theme.ash }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.catPicked(tab.modelData.id)
                }
            }
        }
        Item { Layout.fillWidth: true }
    }

    SectionLabel {
        leftText: root.query !== "" ? "Matches" : root.catName
        rightText: root.query !== "" ? "Name · keyword" : root.count + " emoji"
    }

    // ── Grid ──────────────────────────────────────────────
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        Layout.bottomMargin: 8
        implicitHeight: 4 * 44 + 3 * 2

        Grid {
            id: grid
            columns: root.cols
            spacing: 2

            Repeater {
                model: root.rows * root.cols

                Item {
                    id: cell
                    required property int index
                    readonly property int at: root.rowOff * root.cols + index
                    readonly property var e: at < root.count ? root.items[at] : null
                    readonly property bool on: at === root.sIdx
                    width: 44
                    height: 44

                    Rectangle { anchors.fill: parent; visible: cell.e !== null && (cell.on || cellMouse.containsMouse); color: Theme.steel }
                    Rectangle { visible: cell.e !== null && cell.on; width: parent.width; height: 2; color: Theme.copper }

                    // Colour only for the selected emoji; the rest are greyed so the grid stays quiet.
                    Text {
                        anchors.centerIn: parent
                        visible: cell.e !== null
                        text: cell.e ? Emoji.glyph(cell.e) : ""
                        font.family: "Noto Color Emoji"
                        font.pixelSize: 22
                        opacity: cell.on || cellMouse.containsMouse ? 1 : 0.72
                        layer.enabled: !(cell.on || cellMouse.containsMouse)
                        layer.effect: MultiEffect { saturation: -0.9 }
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        enabled: cell.e !== null
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: root.hovered(cell.at)
                        onClicked: root.activated(cell.at)
                    }
                }
            }
        }

        // Scroll position, 12 small segments.
        Column {
            anchors.right: parent.right
            y: 2
            spacing: 2
            opacity: root.totalRows > root.rows ? 1 : 0.35

            Repeater {
                model: 12
                Rectangle {
                    required property int index
                    readonly property int lit: root.totalRows <= root.rows ? 12 : Math.max(2, Math.round(12 * root.rows / root.totalRows))
                    readonly property int from: root.totalRows <= root.rows ? 0 : Math.round((12 - lit) * root.rowOff / (root.totalRows - root.rows))
                    width: 3
                    height: 11
                    color: index >= from && index < from + lit ? Theme.ash : Theme.steel
                }
            }
        }

        // Nothing found.
        Row {
            visible: root.count === 0
            anchors.centerIn: parent
            spacing: 10
            Mono { text: root.query !== "" ? "NO MATCH" : "EMPTY"; color: Theme.rust }
            Txt {
                text: root.query !== "" ? "no emoji named “" + root.query + "”" : "use an emoji and it shows up here"
                color: Theme.dust
            }
        }
    }

    // ── Selected ──────────────────────────────────────────
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        Layout.bottomMargin: 8
        implicitHeight: 64

        Chamfer { anchors.fill: parent; cut: 6; fillColor: Theme.bg }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 14

            Text {
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignHCenter
                text: root.cur ? Emoji.glyph(root.cur) : ""
                font.family: "Noto Color Emoji"
                font.pixelSize: 32
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Txt {
                    Layout.fillWidth: true
                    text: root.cur ? root.cur.name : "—"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
                Mono {
                    Layout.fillWidth: true
                    font.pixelSize: 10
                    color: Theme.dust
                    elide: Text.ElideRight
                    text: root.cur ? (root.cur.code !== "" ? ":" + root.cur.code + ": · " : "") + Emoji.codepoints(root.cur.ch) : ""
                }
            }

            RowLayout {
                visible: root.cur !== null && root.cur.skin
                spacing: 8

                Lb { text: "Tone" }
                Row {
                    spacing: 3
                    Repeater {
                        model: ["#8A8985", "#C9B7A0", "#B79C7E", "#9A7B5D", "#7B5B44", "#4F3A2C"]
                        Item {
                            id: tone
                            required property int index
                            required property string modelData
                            width: 16
                            height: 16
                            activeFocusOnTab: true

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.width: 1
                                border.color: Emoji.tone === tone.index ? Theme.ivory : Theme.steel
                            }
                            Rectangle { x: 2; y: 2; width: 12; height: 12; color: tone.modelData }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Emoji.setTone(tone.index)
                            }
                        }
                    }
                }
            }
        }
    }
}

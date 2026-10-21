import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Notification center: filter, do-not-disturb, grouped history.
Popup {
    id: root

    panelWidth: 400

    property string filter: "ALL"

    readonly property var shown: Notifs.records.filter(r => root.filter === "ALL" || Notifs.categoryOf(r) === root.filter)

    // Newest first; groups ordered by their newest notification.
    readonly property var groups: {
        const out = [];
        const index = {};
        shown.forEach(r => {
            const app = r.n.appName || "System";
            if (!(app in index)) {
                index[app] = out.length;
                out.push({ app: app, items: [] });
            }
            out[index[app]].items.push(r);
        });
        return out;
    }

    function count(cat) {
        return Notifs.records.filter(r => cat === "ALL" || Notifs.categoryOf(r) === cat).length;
    }

    // Blue-grey for messages, copper when anything in the group is critical, ash otherwise.
    function tint(g) {
        if (g.items.some(r => r.critical)) return Theme.copper;
        return Notifs.categoryOf(g.items[0]) === "MSG" ? Theme.teal : Theme.ash;
    }

    onOpenChanged: if (!open) filter = "ALL"

    // ── Header ────────────────────────────────────────────
    PopupHeader {
        title: "Notifications"
        tint: Theme.ash
        Layout.bottomMargin: 12

        DotText {
            text: String(Math.min(99, Notifs.total)).padStart(2, "0")
            pixel: 2
            gap: 1
            dimUntil: Notifs.total < 10 ? 1 : 0
            Layout.alignment: Qt.AlignRight
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 12
        Layout.bottomMargin: 10
        spacing: 8

        Row {
            spacing: 1
            Repeater {
                model: ["ALL", "MSG", "SYS"]
                ModeTab {
                    required property string modelData
                    label: modelData + "  " + String(root.count(modelData)).padStart(2, "0")
                    active: root.filter === modelData
                    onClicked: root.filter = modelData
                }
            }
        }

        Item { Layout.fillWidth: true }

        Lb { text: "Do not disturb" }

        Row {
            spacing: 1
            ModeTab { label: "Off"; active: !Notifs.dnd; onClicked: Notifs.dnd = false }
            ModeTab { label: "On"; active: Notifs.dnd; onClicked: Notifs.dnd = true }
        }
    }

    Divider {}

    // ── List ──────────────────────────────────────────────
    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight + 6, 470)
        contentWidth: width
        contentHeight: list.implicitHeight + 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: list
            width: parent.width
            spacing: 0

            Repeater {
                model: root.groups

                ColumnLayout {
                    id: group
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 12
                        Layout.topMargin: 10
                        Layout.bottomMargin: 2
                        spacing: 8

                        Rectangle { implicitWidth: 6; implicitHeight: 6; color: root.tint(group.modelData) }
                        Lb { text: group.modelData.app }
                        Lb { text: String(group.modelData.items.length).padStart(2, "0"); color: Theme.ash }
                        Item { Layout.fillWidth: true }

                        Item {
                            implicitWidth: clearText.implicitWidth + 12
                            implicitHeight: 18

                            Rectangle {
                                anchors.fill: parent
                                color: clearMouse.containsMouse ? Theme.steel : "transparent"
                            }
                            Lb {
                                id: clearText
                                anchors.centerIn: parent
                                text: "Clear"
                                color: clearMouse.containsMouse ? Theme.ivory : Theme.dust
                            }
                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifs.dismissApp(group.modelData.app)
                            }
                        }
                    }

                    Repeater {
                        model: group.modelData.items

                        Item {
                            id: row
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 50

                            Rectangle {
                                anchors.fill: parent
                                color: hover.hovered ? Theme.steel : "transparent"
                            }

                            // HoverHandler does not compete with the dismiss button for hover.
                            HoverHandler { id: hover }

                            // Click toggles read / unread.
                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: row.modelData.read = !row.modelData.read
                            }

                            Rectangle {
                                x: 16
                                y: 15
                                width: 4
                                height: 4
                                color: row.modelData.read ? "transparent" : root.tint(group.modelData)
                            }

                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 30
                                anchors.rightMargin: 40
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Txt {
                                        Layout.fillWidth: true
                                        text: row.modelData.n.summary
                                        color: row.modelData.read ? Theme.ash : Theme.ivory
                                        font.pixelSize: 13
                                        font.weight: row.modelData.read ? Font.Normal : Font.Medium
                                        elide: Text.ElideRight
                                    }
                                    Mono {
                                        text: Notifs.ago(row.modelData.time)
                                        color: Theme.dust
                                        font.pixelSize: 10
                                    }
                                }

                                Txt {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: Notifs.plain(row.modelData.n.body).replace(/\s+/g, " ")
                                    color: Theme.dust
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }

                            // Dismiss, visible while the row is hovered.
                            IconButton {
                                id: closeButton
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.top: parent.top
                                anchors.topMargin: 8
                                opacity: hover.hovered || activeFocus ? 1 : 0
                                path: Icons.close
                                onClicked: Notifs.dismiss(row.modelData)
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                visible: root.shown.length === 0
                Layout.fillWidth: true
                Layout.topMargin: 36
                Layout.bottomMargin: 30
                spacing: 8

                // fillWidth on the text itself: a nested layout only stretches if a child does.
                Lb {
                    text: "Clear"
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Txt {
                    text: "Nothing waiting for you."
                    color: Theme.dust
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // ── Footer ────────────────────────────────────────────
    Item {
        Layout.fillWidth: true
        implicitHeight: 36

        Chamfer {
            anchors.fill: parent
            cutTL: 0
            cutBR: 7
            fillColor: Theme.bg
        }
        Rectangle { width: parent.width; height: 1; color: Theme.steel }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 14

            Item {
                implicitWidth: clearAllText.implicitWidth + 12
                implicitHeight: 20

                Rectangle {
                    anchors.fill: parent
                    color: clearAllMouse.containsMouse ? Theme.steel : "transparent"
                }
                Lb {
                    id: clearAllText
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: clearAllMouse.containsMouse ? Theme.ivory : Theme.ash
                }
                MouseArea {
                    id: clearAllMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearAll()
                }
            }

            Item { Layout.fillWidth: true }

            Mono {
                font.pixelSize: 10
                color: Notifs.dnd ? Theme.copper : Theme.dust
                text: Notifs.dnd ? "DND ON · " + Notifs.held + " HELD" : Notifs.unread + " UNREAD"
            }
        }
    }
}

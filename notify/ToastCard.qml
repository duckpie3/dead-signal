import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// One toast: category square, app, time, title, body, actions, countdown strip.
Item {
    id: root

    required property var rec
    readonly property var n: rec.n
    readonly property string category: Notifs.categoryOf(rec)
    readonly property color tint: rec.critical ? Theme.copper : (category === "MSG" ? Theme.teal : Theme.ash)
    readonly property var actions: Array.prototype.filter.call(n.actions || [], a => a.text !== "").slice(0, 3)

    width: 360
    implicitWidth: 360
    implicitHeight: body.implicitHeight + 2

    function hide() {
        root.rec.read = true;
        root.rec.toast = false;
    }

    Chamfer { anchors.fill: parent; cut: 8; fillColor: Theme.steel }
    Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 7; fillColor: Theme.panel }

    // Hovering holds the countdown; clicking the card hides it.
    HoverHandler {
        id: hover
        onHoveredChanged: root.rec.paused = hovered
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.hide()
    }

    ColumnLayout {
        id: body
        x: 1
        y: 1
        width: parent.width - 2
        spacing: 0

        // Copper bar on critical toasts, inset past the chamfer.
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 7
            implicitHeight: 2
            color: root.rec.critical ? Theme.copper : "transparent"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 8
            Layout.topMargin: 8
            spacing: 8

            Rectangle { implicitWidth: 6; implicitHeight: 6; color: root.tint }
            Lb { text: root.n.appName || "System"; Layout.fillWidth: true; elide: Text.ElideRight }
            Lb { text: Notifs.ago(root.rec.time) }
            IconButton {
                path: Icons.close
                onClicked: root.hide()
            }
        }

        Txt {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 2
            text: root.n.summary
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Txt {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 3
            visible: text !== ""
            text: Notifs.plain(root.n.body)
            color: Theme.ash
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            lineHeight: 1.15
        }

        RowLayout {
            Layout.leftMargin: 14
            Layout.topMargin: 10
            visible: root.actions.length > 0
            spacing: 6

            Repeater {
                model: root.actions

                Item {
                    id: act
                    required property var modelData
                    required property int index

                    implicitWidth: label.implicitWidth + 18
                    implicitHeight: 22

                    Rectangle {
                        anchors.fill: parent
                        color: actMouse.containsMouse ? Theme.steel : "transparent"
                        border.width: 1
                        border.color: Theme.steel
                    }
                    Lb {
                        id: label
                        anchors.centerIn: parent
                        text: act.modelData.text
                        color: act.index === 0 || actMouse.containsMouse ? Theme.ivory : Theme.ash
                    }
                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            act.modelData.invoke();
                            root.hide();
                        }
                    }
                }
            }
        }

        // Countdown: one segment per thirtieth of the toast's life, drained from the right.
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
                        color: root.rec.duration > 0 && index < Math.ceil(root.rec.remaining / root.rec.duration * 30)
                            ? Theme.ash : Theme.steel
                    }
                }
            }

            Lb {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: root.rec.duration > 0 ? Math.ceil(root.rec.remaining / 1000) + "s" : "Hold"
                color: root.rec.duration > 0 ? Theme.dust : Theme.copper
            }
        }
    }
}

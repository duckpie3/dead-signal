import QtQuick
import QtQuick.Layouts
import qs.theme

// Popup title row: colored square marker, label, and a status on the right.
RowLayout {
    id: root

    property string title: ""
    property color tint: Theme.dust
    property string status: ""
    property color statusColor: Theme.dust

    Layout.fillWidth: true
    Layout.leftMargin: 16
    Layout.rightMargin: 16
    Layout.topMargin: 12
    Layout.bottomMargin: 10
    spacing: 8

    Rectangle { implicitWidth: 6; implicitHeight: 6; color: root.tint }
    Lb { text: root.title; Layout.fillWidth: true }
    Lb { text: root.status; color: root.statusColor }
}

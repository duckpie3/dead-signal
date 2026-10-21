import QtQuick
import QtQuick.Layouts
import qs.theme

// Key / value line used in popups.
RowLayout {
    id: root

    property string key: ""
    property string value: ""
    property color valueColor: Theme.ivory

    Layout.fillWidth: true
    Layout.leftMargin: 16
    Layout.rightMargin: 16
    spacing: 16

    Lb { text: root.key; Layout.fillWidth: true }
    Mono { text: root.value; color: root.valueColor; Layout.alignment: Qt.AlignRight }
}

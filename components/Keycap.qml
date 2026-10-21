import QtQuick
import qs.theme

// "[ENTER] OPEN" hint for the launcher footer.
Row {
    id: root

    property string key: ""
    property string label: ""

    spacing: 6

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: cap.implicitWidth + 10
        height: cap.implicitHeight + 2
        color: "transparent"
        border.width: 1
        border.color: Theme.steel

        Text {
            id: cap
            anchors.centerIn: parent
            text: root.key
            color: Theme.ash
            font.family: Theme.mono
            font.pixelSize: 9
            font.capitalization: Font.AllUppercase
        }
    }

    Lb {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
    }
}

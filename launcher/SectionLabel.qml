import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// "MATCHES ........ REL" row above a list.
Item {
    id: root

    property string leftText: ""
    property string rightText: ""
    property color leftColor: Theme.dust
    property int rightPad: 0

    Layout.fillWidth: true
    implicitHeight: 30

    Lb {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.leftText
        color: root.leftColor
    }

    Lb {
        anchors.right: parent.right
        anchors.rightMargin: 16 + root.rightPad
        anchors.verticalCenter: parent.verticalCenter
        text: root.rightText
    }
}

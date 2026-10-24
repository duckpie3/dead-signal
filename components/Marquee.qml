import QtQuick
import qs.theme

// One line of text. When it does not fit it waits, slides to its end, waits, and slides back.
// With reduced motion it is cut with an ellipsis instead. implicitWidth is the full text width,
// so layouts can cap it and the text scrolls only as much as it has to.
Item {
    id: root

    property alias text: label.text
    property alias color: label.color
    property alias font: label.font

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    clip: true

    readonly property real overflow: Math.max(0, label.implicitWidth - width)

    function sync() {
        anim.stop();
        label.x = 0;
        if (overflow > 0 && !Theme.reduceMotion && visible && width > 0) anim.start();
    }
    onOverflowChanged: sync()
    onTextChanged: sync()
    onVisibleChanged: sync()
    Component.onCompleted: sync()

    Text {
        id: label
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.reduceMotion ? root.width : implicitWidth
        elide: Theme.reduceMotion ? Text.ElideRight : Text.ElideNone
        wrapMode: Text.NoWrap
        font.family: Theme.sans
        font.pixelSize: 12
        color: Theme.ivory
    }

    SequentialAnimation {
        id: anim
        loops: Animation.Infinite
        PauseAnimation { duration: 2500 }
        NumberAnimation {
            target: label
            property: "x"
            to: -root.overflow
            duration: Math.max(1200, Math.min(6000, root.overflow * 30))
            easing.type: Easing.InOutQuad
        }
        PauseAnimation { duration: 2500 }
        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: Math.max(1200, Math.min(6000, root.overflow * 30))
            easing.type: Easing.InOutQuad
        }
    }
}

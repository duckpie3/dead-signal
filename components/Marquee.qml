import QtQuick
import qs.config

// One line of text. When it does not fit it waits, slides to its end, waits, and slides back,
// at a steady reading speed (about 22 px/s) however long the text is.
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
    readonly property int slideMs: Math.max(1500, Math.round(overflow * 45))

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
        PauseAnimation { duration: 3000 }
        NumberAnimation {
            target: label
            property: "x"
            to: -root.overflow
            duration: root.slideMs
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 3000 }
        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: root.slideMs
            easing.type: Easing.InOutSine
        }
    }
}

import QtQuick
import QtQuick.Effects
import qs.theme
import qs.components
import qs.services

// One wallpaper in the carousel. Every wallpaper keeps its own card; only its slot changes
// (0 = highlighted, ±1 next to it …), and `pos` glides to the new slot. Size, position, opacity
// and dimming are all read from `pos`, so a card in transit blends between its two slots.
Item {
    id: card

    required property int index
    required property var wp
    required property int slot             // target slot, clamped to ±5
    property bool animate: true
    property bool applied: false
    property real centerX: 0
    property real centerY: 0

    signal picked()
    signal activated()

    // Slot tables:           0     1     2     3     4     5
    readonly property var xs:  [0,   190,  330,  436,  500,  500]
    readonly property var sc:  [1,   0.74, 0.56, 0.43, 0.34, 0.34]
    readonly property var op:  [1,   0.9,  0.55, 0.22, 0,    0]
    readonly property var dim: [0,   0.3,  0.5,  0.68, 0.8,  0.8]

    function tab(arr, t) {
        const i = Math.min(Math.floor(t), arr.length - 2);
        return arr[i] + (arr[i + 1] - arr[i]) * Math.min(1, t - i);
    }

    property real pos: 0
    readonly property real a: Math.abs(pos)
    readonly property real hl: Math.max(0, 1 - a * 2)       // 1 on the highlighted card, 0 beside it

    onSlotChanged: {
        anim.stop();
        // A card wrapping from one end to the other jumps instead of sweeping across the screen.
        if (!animate || Math.abs(slot - pos) > 5.5) {
            pos = slot;
        } else {
            anim.to = slot;
            anim.start();
        }
    }
    Component.onCompleted: pos = slot

    NumberAnimation {
        id: anim
        target: card
        property: "pos"
        duration: Theme.reduceMotion ? 0 : 340
        easing.type: Easing.OutCubic
    }

    width: 336
    height: 189
    x: centerX - width / 2 + (pos < 0 ? -1 : 1) * tab(xs, a)
    y: centerY - height / 2
    scale: tab(sc, a)
    opacity: tab(op, a)
    z: 10 - Math.round(a)
    visible: opacity > 0.01

    // Frame: steel, lighter on the highlighted card.
    Chamfer {
        anchors.fill: parent
        cut: 12
        fillColor: Qt.tint(Theme.steel, Qt.rgba(Theme.ash.r, Theme.ash.g, Theme.ash.b, card.hl))
    }

    Item {
        x: 1
        y: 1
        width: parent.width - 2
        height: parent.height - 2

        Chamfer { anchors.fill: parent; cut: 11; fillColor: Theme.bg }

        Image {
            id: img
            anchors.fill: parent
            visible: false
            asynchronous: true
            cache: true
            smooth: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(672, 672)
            source: card.a < 4.2 ? Wallpapers.url(card.wp.path) : ""
        }

        // Chamfered mask for the picture.
        Item {
            id: mask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Chamfer { anchors.fill: parent; cut: 11; fillColor: "white" }
        }

        MultiEffect {
            anchors.fill: parent
            source: img
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: mask
        }

        // Flat dim that grows with distance.
        Chamfer {
            anchors.fill: parent
            cut: 11
            fillColor: Qt.rgba(0.043, 0.043, 0.043, card.tab(card.dim, card.a))
        }
    }

    // Copper bar on the highlighted card.
    Rectangle {
        x: 12
        y: 1
        width: parent.width - 13
        height: 3
        color: Theme.copper
        opacity: card.hl
    }

    // Marks the wallpaper that is currently set.
    Rectangle {
        x: 16
        y: parent.height - height - 8
        width: tag.implicitWidth + 13
        height: tag.implicitHeight + 6
        color: Theme.bg
        opacity: card.applied && card.a < 1.5 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.reduceMotion ? 0 : 340 } }

        Rectangle { x: 6; y: (parent.height - 5) / 2; width: 5; height: 5; color: Theme.teal }
        Lb { id: tag; x: 17; y: 3; text: "Active"; color: Theme.ivory }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.picked()
        onDoubleClicked: card.activated()
    }
}

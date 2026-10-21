pragma Singleton

import Quickshell
import QtQuick
import qs.theme

// What the on-screen display shows and for how long. It reacts to changes in the services,
// so it also appears for changes made elsewhere (hardware keys, pavucontrol, another script).
Singleton {
    id: root

    property bool visible: false
    property string kind: "volume"        // volume | brightness | mic | layout
    property bool ready: false            // ignore the values that arrive while starting up

    function show(k) {
        if (!root.ready) return;
        root.kind = k;
        root.visible = true;
        hold.restart();
    }

    Timer {
        id: hold
        interval: Config.osdMs
        onTriggered: root.visible = false
    }

    Timer {
        interval: 2500
        running: true
        onTriggered: root.ready = true
    }

    Connections {
        target: Audio
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
        function onMicMutedChanged() { root.show("mic"); }
    }

    Connections {
        target: Brightness
        function onPercentChanged() { root.show("brightness"); }
    }

    Connections {
        target: HyprInfo
        function onKbCodeChanged() { root.show("layout"); }
    }
}

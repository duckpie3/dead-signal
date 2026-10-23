pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

// Night light: runs Config.nightCommand (hyprsunset by default) while it is on.
// Changing the temperature restarts the command after a short pause.
Singleton {
    id: root

    property bool on: false
    property int temp: Config.nightTemp

    function setOn(v) {
        root.on = v;
        restart.restart();
    }

    function setTemp(t) {
        root.temp = Math.max(2500, Math.min(6500, Math.round(t / 100) * 100));
        if (root.on) restart.restart();
    }

    Timer {
        id: restart
        interval: 250
        onTriggered: {
            proc.running = false;
            if (root.on) kick.start();
        }
    }
    Timer { id: kick; interval: 150; onTriggered: proc.running = root.on }

    Process {
        id: proc
        command: Config.nightCommand.map(a => a.split("{temp}").join(String(root.temp)))
    }
}

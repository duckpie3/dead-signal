import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

Popup {
    id: root

    panelWidth: 200

    function run(cmd) {
        root.dismissed();
        Quickshell.execDetached(cmd);
    }

    PopupHeader {
        title: "Session"
        tint: Theme.dust
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        MenuRow {
            glyph: Icons.lock
            label: "Lock"
            onTriggered: root.run(Config.lockCommand)
        }
        MenuRow {
            glyph: Icons.moon
            label: "Suspend"
            onTriggered: root.run(Config.suspendCommand)
        }
    }

    Divider { Layout.topMargin: 8; Layout.bottomMargin: 8 }

    Lb {
        text: "End session"
        Layout.leftMargin: 16
        Layout.bottomMargin: 4
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        spacing: 1

        MenuRow {
            glyph: Icons.logout
            tint: Theme.copper
            label: "Log out"
            onTriggered: root.run(Config.logoutCommand)
        }
        MenuRow {
            glyph: Icons.reboot
            tint: Theme.rust
            label: "Reboot"
            onTriggered: root.run(Config.rebootCommand)
        }
        MenuRow {
            glyph: Icons.power
            tint: Theme.rust
            label: "Shut down"
            onTriggered: root.run(Config.shutdownCommand)
        }
    }
}

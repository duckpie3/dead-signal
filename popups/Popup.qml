import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// Base popup: a chamfered Dead Panel under the bar, right-aligned to its anchor cell.
// Closes on outside click (Hyprland focus grab) or Escape.
PopupWindow {
    id: root

    required property var bar              // the PanelWindow
    required property Item anchorItem      // the cell this popup hangs from
    property bool open: false
    property int panelWidth: 280

    default property alias content: body.data

    signal dismissed()

    anchor.item: root.anchorItem
    // Opens below a top bar, above a bottom bar.
    anchor.edges: (Config.barAtBottom ? Edges.Top : Edges.Bottom) | Edges.Right
    anchor.gravity: (Config.barAtBottom ? Edges.Top : Edges.Bottom) | Edges.Left
    anchor.margins.top: Config.barAtBottom ? 0 : 8
    anchor.margins.bottom: Config.barAtBottom ? 8 : 0

    visible: open
    color: "transparent"
    implicitWidth: panelWidth
    implicitHeight: body.implicitHeight + 2

    HyprlandFocusGrab {
        windows: [root, root.bar]
        active: root.open
        onCleared: root.dismissed()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.dismissed()

        Chamfer {
            anchors.fill: parent
            cut: 8
            fillColor: Theme.steel
        }

        Chamfer {
            anchors.fill: parent
            anchors.margins: 1
            cut: 7
            fillColor: Theme.panel
        }

        ColumnLayout {
            id: body
            x: 1
            y: 1
            width: parent.width - 2
            spacing: 0
        }
    }
}

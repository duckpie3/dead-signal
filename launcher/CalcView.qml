import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// Result block for calculator mode: dot-matrix value plus expression / hex / binary.
Item {
    id: root

    property var calc: ({ ok: false, empty: true, error: "" })
    property string expression: ""

    Layout.fillWidth: true
    Layout.leftMargin: 14
    Layout.rightMargin: 14
    implicitHeight: 90

    Chamfer {
        anchors.fill: parent
        cut: 6
        fillColor: Theme.bg
    }

    // Dot-matrix value, or plain text when it has characters the matrix can't draw (1.2e+21).
    DotText {
        id: dots
        pixel: 6
        gap: 3
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.calc.ok && supported
        text: root.calc.ok ? root.calc.text : ""
    }

    Mono {
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.calc.ok && !dots.supported
        text: root.calc.ok ? root.calc.text : ""
        color: Theme.brass
        font.pixelSize: 28
    }

    Mono {
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.calc.ok
        text: root.calc.empty ? "type an expression" : root.calc.error
        color: root.calc.empty ? Theme.dust : Theme.rust
        font.pixelSize: 12
    }

    GridLayout {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        columns: 2
        columnSpacing: 14
        rowSpacing: 6
        visible: root.calc.ok

        Lb { text: "Expr" }
        Mono { text: root.expression; color: Theme.ash }
        Lb { visible: root.calc.ok && root.calc.hex !== ""; text: "Hex" }
        Mono { visible: root.calc.ok && root.calc.hex !== ""; text: root.calc.ok ? root.calc.hex : "" }
        Lb { visible: root.calc.ok && root.calc.bin !== ""; text: "Bin" }
        Mono { visible: root.calc.ok && root.calc.bin !== ""; text: root.calc.ok ? root.calc.bin : "" }
    }
}

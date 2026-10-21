import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Keyboard layout: active layout in ivory, others in dust. Click cycles layouts.
Cell {
    id: root

    visible: Config.keyboardLayouts.length > 1
    interactive: true
    spacing: 5

    onClicked: m => HyprInfo.nextLayout()

    Repeater {
        model: Config.keyboardLayouts

        Mono {
            required property var modelData
            readonly property bool active: modelData.code === HyprInfo.kbCode
            text: modelData.code
            font.pixelSize: active ? 11 : 10
            color: active ? Theme.ivory : Theme.dust
        }
    }
}

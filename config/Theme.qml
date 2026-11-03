pragma Singleton

import Quickshell
import QtQuick

// Palette (from the active theme), type and geometry.
Singleton {
    // Colours come from the active theme (see Themes.qml). The comments name each colour's job.
    // Surfaces
    readonly property color stage: Themes.palette.stage  // Backdrop    — behind the lock screen, wallpaper picker, capture overlay
    readonly property color bg:    Themes.palette.bg     // Void        — bar background
    readonly property color panel: Themes.palette.panel  // Dead Panel  — cells and popups
    readonly property color steel: Themes.palette.steel  // Cold Steel  — hover, active, separators, empty segments

    // Text and signal
    readonly property color ivory:  Themes.palette.ivory   // Faded Ivory     — primary text, values
    readonly property color ash:    Themes.palette.ash     // Ash             — secondary text, icons
    readonly property color dust:   Themes.palette.dust    // Dust            — labels, inactive
    readonly property color copper: Themes.palette.copper  // Oxidized Copper — active mark, warning
    readonly property color teal:   Themes.palette.teal    // Dead Teal       — audio, network
    readonly property color brass:  Themes.palette.brass   // Old Brass       — clock, battery, numbers
    readonly property color sage:   Themes.palette.sage    // Faded Sage      — healthy, charging
    readonly property color rust:   Themes.palette.rust    // Rust            — errors, critical

    // The backdrop colour at a given opacity, for dimming layers.
    function dim(alpha) { return Qt.rgba(stage.r, stage.g, stage.b, alpha); }

    // Type
    readonly property string mono: "JetBrains Mono"
    readonly property string sans: "IBM Plex Sans"

    // Geometry (px)
    readonly property int margin: 0        // outer margin around the bar
    readonly property int barHeight: 36
    readonly property int barCut: 7        // chamfer on the bar shell
    readonly property int cellHeight: 26
    readonly property int cut: 4           // chamfer on cells
    readonly property int gap: 4           // spacing between cells
    readonly property int pad: 10          // horizontal padding inside a cell

    // Motion. Set DEADSIGNAL_REDUCE_MOTION=1 in the environment to disable transitions.
    readonly property bool reduceMotion: Quickshell.env("DEADSIGNAL_REDUCE_MOTION") === "1"
    readonly property int animMs: reduceMotion ? 0 : 120
}

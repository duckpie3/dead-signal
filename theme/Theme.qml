pragma Singleton

import Quickshell
import QtQuick

// Dead Signal palette, type and geometry.
Singleton {
    // Surfaces
    readonly property color bg:    "#141414"   // Void        — bar background
    readonly property color panel: "#202020"   // Dead Panel  — cells and popups
    readonly property color steel: "#303030"   // Cold Steel  — hover, active, separators, empty segments

    // Text and signal
    readonly property color ivory:  "#C3C0B8"  // Faded Ivory     — primary text, values
    readonly property color ash:    "#8A8985"  // Ash             — secondary text, icons
    readonly property color dust:   "#777773"  // Dust            — labels, inactive
    readonly property color copper: "#9C7165"  // Oxidized Copper — active mark, warning
    readonly property color teal:   "#78908B"  // Dead Teal       — audio, network
    readonly property color brass:  "#A69A79"  // Old Brass       — clock, battery, numbers
    readonly property color sage:   "#89947D"  // Faded Sage      — healthy, charging
    readonly property color rust:   "#A16E6A"  // Rust            — errors, critical

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

import QtQuick
import qs.theme

// Readout text. JetBrains Mono has fixed-width digits, so values do not jitter.
Text {
    color: Theme.ivory
    font.family: Theme.mono
    font.pixelSize: 11
}

pragma Singleton

import Quickshell
import QtQuick

// User-editable settings. Everything else in the config reads from here.
Singleton {
    // Where the bar sits: "top" or "bottom". Popups and the tray menu open away from the bar.
    readonly property string barPosition: "top"
    readonly property bool barAtBottom: barPosition === "bottom"

    // Workspaces shown as roman numerals (I … X supported).
    readonly property int workspaceCount: 6
    readonly property var roman: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

    // Host pinged for the latency sparkline.
    readonly property string pingHost: "1.1.1.1"

    // Keyboard layouts, in the order you configured them in Hyprland.
    // `match` is a case-insensitive substring of the layout name Hyprland reports.
    readonly property var keyboardLayouts: [
        { code: "EN", match: "english" },
        { code: "ES", match: "spanish" }
    ]

    // Terminal used to launch nmtui from the network popup.
    readonly property var terminal: ["alacritty", "-e"]

    // Session commands.
    readonly property var lockCommand:     ["qs", "-c", "deadsignal", "ipc", "call", "lock", "lock"]
    readonly property var suspendCommand:  ["systemctl", "suspend"]
    readonly property var logoutCommand:   ["hyprctl", "dispatch", "exit"]
    readonly property var rebootCommand:   ["systemctl", "reboot"]
    readonly property var shutdownCommand: ["systemctl", "poweroff"]

    // Launcher: apps pinned in the empty state (desktop-entry names, case-insensitive).
    // Leave empty to pin your eight most used apps instead.
    readonly property var pinned: []
    readonly property var copyCommand: ["wl-copy"]     // wl-clipboard
    readonly property var typeCommand: ["wtype"]       // wtype

    // Clipboard mode (needs cliphist and wl-clipboard). Enter copies the entry, then runs this
    // to paste it. Terminals usually want ctrl+shift+v: ["wtype","-M","ctrl","-M","shift","-k","v","-m","shift","-m","ctrl"].
    readonly property var clipPasteCommand: ["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"]
    // Run `wl-paste --watch cliphist store` from the shell. Turn off if you already start it in Hyprland.
    readonly property bool clipWatch: true

    // Opened in `terminal` from the telemetry popup.
    readonly property var monitorCommand: ["btop"]

    // ── Notifications ─────────────────────────────────────
    // Seconds a toast stays when the app does not say. Critical ones stay until dismissed.
    readonly property real toastSeconds: 8
    // An app whose name contains one of these counts as a message (MSG filter); the rest is SYS.
    readonly property var messageApps: ["signal", "telegram", "discord", "element", "matrix", "slack",
                                        "whatsapp", "mail", "thunderbird", "geary", "evolution", "fractal", "dino"]

    // ── On-screen display ─────────────────────────────────
    readonly property int osdMs: 1600                  // how long it stays
    readonly property int osdMargin: 64                // distance from the bottom edge

    // ── Weather (Open-Meteo, no key needed) ───────────────
    readonly property bool weatherEnabled: true
    readonly property real weatherLat: 19.43
    readonly property real weatherLon: -99.13
    readonly property string weatherPlace: "Mexico City"
    readonly property string weatherUnit: "celsius"    // or "fahrenheit"

    // ── Display ───────────────────────────────────────────
    // Night light runs this while it is on. {temp} is the colour temperature in kelvin.
    // hyprsunset keeps running and restores the screen when it is stopped.
    readonly property var nightCommand: ["hyprsunset", "-t", "{temp}"]
    readonly property int nightTemp: 3400

    // ── Tray ──────────────────────────────────────────────
    // Tray items whose id or title contains one of these (lowercase) are hidden, because the bar
    // already has a cell for them (Bluetooth and network have their own popups).
    readonly property var trayHidden: ["blueman", "bluetooth", "nm-applet", "networkmanager"]

    // ── Wallpapers ────────────────────────────────────────
    // Folder scanned for images (jpg, png, webp, bmp, gif, avif, jxl; one level of sub-folders).
    readonly property string wallpaperDir: "~/Pictures/Wallpapers"
    // Set again when the shell starts.
    readonly property bool wallpaperRestore: true
    // Command that sets a wallpaper. {file} and {fit} are filled in; {fit} comes from wallpaperFitNames.
    // Default is swww (start its daemon first, newer builds are called awww: change the first word).
    // For hyprpaper (0.8+) try:  ["hyprctl", "hyprpaper", "wallpaper", ",{file},{fit}"]
    // with fill -> "cover", fit -> "contain", tile -> "tile".
    // hyprpaper before 0.8 has no fit modes; use a list of commands, and only {file}:
    //   [["hyprctl", "hyprpaper", "preload", "{file}"], ["hyprctl", "hyprpaper", "wallpaper", ",{file}"]]
    // Whatever the command prints is written to the Quickshell log (qs -c deadsignal log).
    readonly property var wallpaperCommand: ["hyprctl", "hyprpaper", "wallpaper", "eDP-1,{file},{fit}"]
    // The picker's Fill / Fit / Tile as your wallpaper tool names them. swww has no tiling; "no" keeps the original size.
    readonly property var wallpaperFitNames: ({ fill: "cover", fit: "contain", tile: "tile" })

    // MPRIS players that never show up in the media cell. Matched as a lowercase substring of the
    // player's D-Bus name or identity. playerctld only mirrors the other players, so it is hidden.
    readonly property var mediaIgnore: ["playerctld"]
}

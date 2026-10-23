# Dead Signal — Quickshell bar and launcher

NASA-punk status bar for Hyprland on Arch. Chamfered cells, segmented meters,
dot-matrix clock, roman-numeral workspaces. Palette and geometry follow the
Dead Signal style guide.

## Install

```sh
sudo pacman -S quickshell wl-clipboard wtype curl ttf-jetbrains-mono ttf-ibm-plex \
    networkmanager brightnessctl upower power-profiles-daemon pipewire
# optional: hyprlock + hypridle (lock), foot (terminal for nmtui)

mkdir -p ~/.config/quickshell
cp -r deadsignal ~/.config/quickshell/
qs -c deadsignal
```

Autostart in `hyprland.conf`:

```
exec-once = qs -c deadsignal
```

Quickshell reloads on file save, so you can edit and watch it update.

## Interaction

| Module     | Left click        | Right / middle click | Scroll          |
| ---------- | ----------------- | -------------------- | --------------- |
| Workspace  | switch            |                      |                 |
| Volume     | audio popup       | mute                 | ±5 %            |
| Brightness |                   |                      | ±5 %            |
| Network    | network popup     |                      |                 |
| Battery    | power popup       |                      |                 |
| Keyboard   | next layout       |                      |                 |
| Tray       | activate          | menu / secondary     | forwarded       |
| CPU / MEM  | system popup      |                      |                 |
| Bell       | notification center |                    |                 |
| Clock      | calendar + weather |                    |                 |
| Power icon | session popup     |                      |                 |

Popups close on an outside click or Escape. Inside them: Tab / Shift+Tab to move,
Up/Down between rows, Enter or Space to activate, Left/Right on sliders.
Hover is a steel fill; keyboard focus is an ivory outline.

## Launcher

Open it by clicking the emblem on the bar, or bind a key in `hyprland.conf`:

```
bind = SUPER, space, exec, qs -c deadsignal ipc call launcher toggle
bind = SUPER, C,     exec, qs -c deadsignal ipc call launcher mode calc
```

`ipc call launcher` also accepts `open`, `close` and `mode cmd|calc|win`.
It appears on the focused monitor only; clicking outside closes it.

| Mode | Prefix | What it does |
| ---- | ------ | ------------ |
| Apps | none  | fuzzy search of desktop entries; empty query shows pinned and recent |
| Cmd  | `>`   | runs the text with `sh -c` |
| Calc | `=`   | evaluates math (`+ - * / % ^`, `sqrt`, `sin`, `log`, `pi` …), shows hex and binary |
| Win  | `@`   | focuses an open window by title |

Keys: Up/Down (or Ctrl+N/P) select, Enter opens, Tab / Shift+Tab switch mode,
Alt+1…8 launches a pinned app, Esc closes.
Calc results are copied with `wl-copy` or typed with `wtype` (change them in `Config.qml`).

Launch history is kept in `~/.local/state/deadsignal/usage.json`. It drives the
Recent list, the usage meter and, if `Config.pinned` is empty, the pinned tiles.
The category tag (NET / DEV / MEDIA / SYS) comes from the entry's `Categories`.
Row icons are letter tiles on purpose; they keep the look consistent with the bar.

## Notifications

The shell is the notification daemon, so stop `dunst` / `mako` first (only one can run).
New notifications appear as toasts at the top right, clear of the bar. The strip under a toast
is its timer; hovering pauses it, and critical ones stay until you close them.
Nothing is lost when a toast goes: everything waits in the notification center, opened from
the bell next to the clock. There you can filter (ALL / MSG / SYS), switch do not disturb,
click a row to mark it read or unread, and dismiss one, an app's group, or everything.

Do not disturb holds toasts back (critical ones still show). It can also be toggled from a key:

```
bind = SUPER, N, exec, qs -c deadsignal ipc call notifications toggleDnd
```

Which apps count as MSG is `Config.messageApps`; toast length is `Config.toastSeconds`.

## On-screen display

A small card at the bottom centre appears when the volume, brightness, microphone mute or keyboard
layout changes, whoever changed it. For instant feedback from the keyboard, point the keys at the shell:

```
bindel = , XF86AudioRaiseVolume,  exec, qs -c deadsignal ipc call osd volume up
bindel = , XF86AudioLowerVolume,  exec, qs -c deadsignal ipc call osd volume down
bindl  = , XF86AudioMute,         exec, qs -c deadsignal ipc call osd volume mute
bindl  = , XF86AudioMicMute,      exec, qs -c deadsignal ipc call osd mic mute
bindel = , XF86MonBrightnessUp,   exec, qs -c deadsignal ipc call osd brightness up
bindel = , XF86MonBrightnessDown, exec, qs -c deadsignal ipc call osd brightness down
```

Volume goes up to 150 %; the part past 100 % is copper. Duration and distance from the edge are
`Config.osdMs` and `Config.osdMargin`.

## Weather

The calendar popup shows the current weather, the next 12 hours and the next three days, from
Open-Meteo (no account or key). Set your place in `theme/Config.qml`: `weatherLat`, `weatherLon`,
`weatherPlace` and `weatherUnit` (`"celsius"` or `"fahrenheit"`). It needs `curl`, refreshes every
20 minutes and when the popup opens, and `weatherEnabled: false` removes the section.

## Configure

Edit `theme/Config.qml`: bar position (`"top"` or `"bottom"`), workspace count, ping host, keyboard layouts
(`match` is a substring of the layout name Hyprland reports), terminal,
and the lock / suspend / logout / reboot / shutdown commands.

Colors, fonts and geometry are in `theme/Theme.qml`.
Set `DEADSIGNAL_REDUCE_MOTION=1` to turn off colour transitions.

Lock uses `loginctl lock-session`, so it needs a locker bound to that event
(hypridle with `lock_cmd = pidof hyprlock || hyprlock`).

## Wallpaper picker

A full-screen overlay on the focused monitor. The highlighted wallpaper previews behind a flat dim,
and chamfered thumbnails sit in a carousel in front of it.

```
bind = SUPER, W, exec, qs -c deadsignal ipc call wallpaper toggle
bind = SUPER SHIFT, W, exec, qs -c deadsignal ipc call wallpaper random
```

`ipc call wallpaper` also accepts `open`, `close` and `random` (sets one without opening the picker).

Keys: Left/Right (or the mouse wheel) browse, Enter applies and keeps the picker open, R picks a random one,
Tab cycles Fill / Fit / Tile, Esc closes. Double-clicking a thumbnail applies it.

Set the folder and the command that applies a wallpaper in `Config.qml` (`wallpaperDir`, `wallpaperCommand`,
`wallpaperFitNames`). The default is swww, so start its daemon at login (`exec-once = swww-daemon`).
The choice is kept in `~/.local/state/deadsignal/wallpaper.json` and set again at startup.
Image sizes come from ImageMagick's `identify` when it is installed.

## Lock screen

A real Wayland session lock (`ext-session-lock`, via Quickshell's `WlSessionLock`), so nothing can be
reached until the password is accepted. The password is checked with PAM (`pam/password.conf`, your account
password only). It needs Quickshell 0.2 or newer built with PAM support (the Arch package has it).

```
bind = SUPER, L, exec, qs -c deadsignal ipc call lock lock
```

The power menu's Lock entry runs the same command (`Config.lockCommand`). For idle and suspend with hypridle:

```
general {
    lock_cmd = qs -c deadsignal ipc call lock lock
    before_sleep_cmd = qs -c deadsignal ipc call lock lock
}
listener { timeout = 300  on-timeout = loginctl lock-session }
```

Press any key to wake it, type, Enter to unlock. Esc clears. Each character fills one of twelve segments;
the scan line and the green cascade play first. The session is then released and the dim shutters open
over your real desktop, so windows fade in rather than pop up. A wrong password
flashes the segments red and fades them back. The wallpaper behind it is the one set from the picker.
Caps Lock is read from the keyboard LED in `/sys/class/leds`.

Try it with a second TTY (Ctrl+Alt+F3) logged in first. If the lock ever fails to accept your password,
run `pkill quickshell` there and start the shell again: the compositor keeps the screen locked until a
lock client unlocks it, so restart it and enter your password normally.

## Bluetooth, display, power profile, airplane mode

Each of these lives in the popup of the cell it belongs to, so nothing is controlled from two places.

- **Bluetooth cell** (after the network cell, hidden without an adapter). Click for the popup: adapter switch,
  connected / paired / available devices with battery, Scan and Stop. Scanning runs only while the popup is open.
  Click a device to connect, disconnect, or pair. Needs BlueZ running (`bluetooth.service`).
- **Brightness cell**: click for the display popup (brightness slider, night light with a temperature slider).
  Scrolling the cell and the brightness keys still adjust by 5 %. Night light runs `Config.nightCommand`,
  `hyprsunset -t {temp}` by default (install `hyprsunset`). The cell shows a moon and a brass pixel while it is on.
- **Battery popup**: Saver / Balanced / Perf selector (needs `power-profiles-daemon`; Perf only shows when the
  hardware has it).
- **Network popup**: Airplane mode switch. It runs `rfkill block|unblock wifi bluetooth`, and reads the state
  from `rfkill -J` while the popup is open.
- **Tray**: items matching `Config.trayHidden` (blueman, nm-applet by default) are hidden, since the bar has cells
  for them.

## Layout

```
shell.qml          one Bar per screen
bar/Bar.qml        window, shell shape, module order, popups
modules/           one file per bar cell
popups/            audio, network, calendar, battery, session, telemetry, notifications
notify/            ToastWindow, ToastCard
osd/               OsdWindow
wallpaper/         WallpaperWindow, WallCard
lock/              LockSurface, LockScene, UnlockOverlay
pam/               password.conf (PAM stack for the lock screen)
launcher/          LauncherWindow, ResultRow, PinTile, CalcView, Fuzzy.js, Calc.js
components/        Cell, Chamfer, SegMeter, SegSlider, Spark, DotClock, Glyph …
services/          Bt, NightLight, Airplane, Audio, Net, Stats, Brightness, HyprInfo, Time, Apps, LauncherState, Notifs, Weather, Osd, Wallpapers, LockState
theme/             Theme (tokens) and Config (your settings)
scripts/           netinfo.sh (nmcli), ping.sh, sysinfo.sh (freq, temp, disk, top), wallpapers.sh
```

## Notes

- The CPU / MEM popup reads `/proc` every second. Frequency, temperature, disk and the top
  processes are only collected while it is open (`top` takes about a second per sample).
  Temperature comes from the first `k10temp`, `coretemp`, `zenpower` or `acpitz` sensor; it is hidden if none is found.
  `procps-ng` (`top`, `ps`) is required, and `btop` for the monitor row (`Config.monitorCommand`).
- Cells that have nothing to show hide themselves (no battery, no backlight, empty tray).
- Tray icons keep their own colours; recolouring them reliably is not possible
  without per-app knowledge.
- The bar is a layer-shell surface without keyboard focus, so keyboard navigation
  applies inside popups, not on the bar itself.
- Only Hyprland is supported (workspaces, keyboard layout and focus grab use its IPC).
- Lucide icons (ISC licence) are embedded as SVG path data in `components/Icons.qml`.

## If something does not load

Run `qs -c deadsignal` in a terminal; QML errors print with file and line.

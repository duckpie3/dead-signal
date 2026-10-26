// Dead Signal — Quickshell bar, launcher, notifications and on-screen display for Hyprland
// Run with:  qs -c deadsignal      (config lives in ~/.config/quickshell/deadsignal)

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.bar
import qs.capture
import qs.launcher
import qs.lock
import qs.notify
import qs.osd
import qs.services
import qs.wallpaper

ShellRoot {
    // One bar per screen.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // One launcher window per screen; only the focused monitor shows it.
    Variants {
        model: Quickshell.screens
        LauncherWindow {}
    }

    // Toasts and the on-screen display, also on the focused monitor only.
    Variants {
        model: Quickshell.screens
        ToastWindow {}
    }

    Variants {
        model: Quickshell.screens
        OsdWindow {}
    }

    // Wallpaper picker overlay, on the focused monitor.
    Variants {
        model: Quickshell.screens
        WallpaperWindow {}
    }

    // Screenshot and colour picker overlay, on the monitor that was focused when it started.
    Variants {
        model: Quickshell.screens
        CaptureWindow {}
    }

    // Session lock: covers every screen until the password is accepted and the shutters have opened.
    WlSessionLock {
        locked: LockState.locked
        onLockedChanged: console.log("[lock] session lock requested:", locked)
        onSecureChanged: console.log("[lock] compositor reports the session as secure:", secure)
        LockSurface {}
    }

    // Dim shutters that open over the desktop right after unlocking.
    Variants {
        model: Quickshell.screens
        UnlockOverlay {}
    }

    // Hyprland:  bind = SUPER, L, exec, qs -c deadsignal ipc call lock lock
    IpcHandler {
        target: "lock"
        function lock(): void {
            console.log("[lock] ipc lock called");
            LockState.lock();
        }
        function isLocked(): bool { return LockState.locked; }
    }

    // Hyprland:  bind = SUPER, space, exec, qs -c deadsignal ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void { LauncherState.toggle(); }
        function open(): void { LauncherState.show(""); }
        function close(): void { LauncherState.hide(); }
        // e.g.  ... ipc call launcher mode calc
        function mode(name: string): void { LauncherState.show(name); }
    }

    // Hardware keys. These change the value and show the OSD straight away:
    //   bindel = , XF86AudioRaiseVolume, exec, qs -c deadsignal ipc call osd volume up
    IpcHandler {
        target: "osd"
        function volume(action: string): void {
            if (action === "mute") Audio.toggleMute();
            else if (action === "up") {
                if (Audio.muted) Audio.toggleMute();
                Audio.step(0.05);
            } else if (action === "down") Audio.step(-0.05);
            Osd.show("volume");
        }
        function brightness(action: string): void {
            Brightness.step(action === "down" ? -5 : 5);
            Osd.show("brightness");
        }
        function mic(action: string): void {
            Audio.toggleMic();
            Osd.show("mic");
        }
        function layout(): void { HyprInfo.nextLayout(); }
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { Notifs.dnd = !Notifs.dnd; }
        function clear(): void { Notifs.clearAll(); }
    }

    // bind = SUPER, W, exec, qs -c deadsignal ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { Wallpapers.toggle(); }
        function open(): void { Wallpapers.show(); }
        function close(): void { Wallpapers.hide(); }
        // Set a random wallpaper without opening the picker.
        function random(): void { Wallpapers.applyRandom(); }
    }

    // Hardware media keys (these act on the player shown in the bar):
    //   bindl = , XF86AudioPlay, exec, qs -c deadsignal ipc call media toggle
    //   bindl = , XF86AudioNext, exec, qs -c deadsignal ipc call media next
    //   bindl = , XF86AudioPrev, exec, qs -c deadsignal ipc call media previous
    IpcHandler {
        target: "media"
        function toggle(): void { Media.toggle(); }
        function next(): void { Media.next(); }
        function previous(): void { Media.prev(); }
    }
    // Screenshots:
    //   bind = , Print, exec, qs -c deadsignal ipc call capture region
    //   bind = SHIFT, Print, exec, qs -c deadsignal ipc call capture screen
    //   bind = ALT, Print, exec, qs -c deadsignal ipc call capture window
    //   bind = SUPER SHIFT, C, exec, qs -c deadsignal ipc call capture picker
    IpcHandler {
        target: "capture"
        function region(): void { Capture.screenshot("region"); }
        function screen(): void { Capture.screenshot("screen"); }
        function window(): void { Capture.screenshot("window"); }
        function picker(): void { Capture.pick(); }
    }

    // Focus timer:
    //   bind = SUPER, F, exec, qs -c deadsignal ipc call focus toggle
    IpcHandler {
        target: "focus"
        function toggle(): void { Pomodoro.toggle(); }
        function start(): void { Pomodoro.start(); }
        function pause(): void { Pomodoro.pause(); }
        function reset(): void { Pomodoro.reset(); }
        function skip(): void { Pomodoro.skip(); }
    }
}

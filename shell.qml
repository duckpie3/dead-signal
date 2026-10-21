// Dead Signal — Quickshell bar, launcher, notifications and on-screen display for Hyprland
// Run with:  qs -c deadsignal      (config lives in ~/.config/quickshell/deadsignal)

import Quickshell
import Quickshell.Io
import qs.bar
import qs.launcher
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
}

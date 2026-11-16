import Quickshell
import Quickshell.Io
import qs.Bar
import qs.Common
import qs.Pathway
import qs.Pathway.providers
import qs.Polkit

// Entry point. Loads the two surfaces and exposes Pathway over IPC; everything
// else lives in its own module.
ShellRoot {
    Bar {}

    PolkitPrompt {}

    Pathway {
        id: pathway
    }

    // Driven from Hyprland: `qs ipc call pathway toggle`. Keeping the shell
    // resident means opening is instant and frecency state stays warm.
    IpcHandler {
        target: "pathway"

        function toggle(): void {
            pathway.toggle();
        }

        function open(): void {
            pathway.show();
        }

        function close(): void {
            pathway.hide();
        }

        // SUPER+V. cliphist is re-read on every open because the history moves
        // constantly - a standing list would go stale between invocations.
        function clipboard(): void {
            ClipboardProvider.refresh();
            pathway.showScoped(ClipboardProvider, "Clipboard");
        }

        // Jumps straight to the theme list, skipping the "Theme" command row.
        // Unbound by default - the command is reachable by searching for it.
        function theme(): void {
            pathway.showScoped(ThemeProvider, "Theme");
        }

        function keybinds(): void {
            KeybindsProvider.refresh();
            pathway.showScoped(KeybindsProvider, "Keybinds");
        }

        // `screenrecord --with-webcam` with several cameras connected, between
        // picking the region and starting. See WebcamProvider for the protocol.
        function webcam(cameras: string, reply: string): void {
            WebcamProvider.ask(cameras, reply);
            pathway.showScoped(WebcamProvider, "Camera");
        }
    }

    IpcHandler {
        target: "dictation"

        function set(status: string): void {
            Dictation.set(status);
        }

        function error(message: string): void {
            Dictation.fail(message);
        }
    }
}

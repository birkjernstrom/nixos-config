import Quickshell
import Quickshell.Io
import qs.Bar
import qs.Pathway

// Entry point. Loads the two surfaces and exposes Pathway over IPC; everything
// else lives in its own module.
ShellRoot {
    Bar {}

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
    }
}

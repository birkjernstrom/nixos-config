import Quickshell.Io

// A terminal UI opened and closed from a bar icon.
//
// Toggling rather than spawning: a bar icon is a one-click target and a second
// click would otherwise stack another copy of the same window on the first.
// Holding the Process here is what makes the toggle cheap - closing is
// terminating what we started, with no window lookup and no IPC.
//
// `appId` is what hyprland's float rule matches (see the window_rule block in
// modules/nixos/hyprland/home.nix), so it has to be a valid GTK application id -
// hence the dotted form. Ghostty sizes the window itself in rows and columns,
// which is the unit a TUI actually cares about and saves the rule from carrying
// a pixel size that would be wrong on the next monitor.
Process {
    id: root

    required property string program
    required property string appId
    property int columns: 100
    property int rows: 28

    // Ghostty spawns the program directly, so it exits when the TUI does and the
    // toggle state follows along. confirm-close-surface would otherwise turn the
    // second click into a dialog asking whether we meant it.
    command: ["ghostty", `--class=${root.appId}`, `--title=${root.program}`, `--window-width=${root.columns}`, `--window-height=${root.rows}`, "--confirm-close-surface=false", "-e", root.program]

    function toggle(): void {
        root.running = !root.running;
    }
}

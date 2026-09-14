{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
in
{
  # Everything started here belongs to the Quickshell stack - the shell process
  # itself and the cliphist watchers behind Pathway's clipboard history - so it
  # is gated on that shell rather than on the session. Noctalia keeps its own
  # clipboard history and is started by its own systemd user unit off
  # hyprland-session.target (../noctalia/default.nix), so with it in charge
  # there is nothing left for this handler to do.
  config = mkIf (cfg.enable && config.userSettings.quickshell.enable) {
    wayland.windowManager.hyprland.settings = {
      # Run once, when the compositor starts (the hyprlang `exec-once`).
      #
      # Everything that talks to Wayland belongs here, not in `exec_cmd`: the
      # Lua config runs top-level `hl.exec_cmd` calls while the config is being
      # evaluated, which is before the backend is up and before WAYLAND_DISPLAY
      # exists, so those clients fail to connect and exit without a trace.
      on = [
        {
          _args = [
            "hyprland.start"
            (hypr.lua ''
              function()
                -- Bar + Pathway command menu (one resident quickshell process)
                hl.exec_cmd("qs")

                -- Start cliphist listener to store clipboard history
                hl.exec_cmd("wl-paste --type text --watch cliphist store")
                hl.exec_cmd("wl-paste --type image --watch cliphist store")
              end'')
          ];
        }
      ];
    };
  };
}

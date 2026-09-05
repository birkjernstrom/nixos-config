# What Hyprland launches when the compositor comes up.
#
# The `hl.*` helpers come from modules/desktop/_hypr.nix, which is a plain
# function rather than a module - import-tree skips it because of the `_`.
{ lib, ... }:

let
  hypr = import ./_hypr.nix { inherit lib; };
in
{
  flake.modules.homeManager.desktop = { config, pkgs, ... }: {
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

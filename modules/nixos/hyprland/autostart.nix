{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      # Run once, when the compositor starts (the hyprlang `exec-once`).
      on = [
        {
          _args = [
            "hyprland.start"
            (hypr.lua ''
              function()
                -- Start cliphist listener to store clipboard history
                hl.exec_cmd("wl-paste --type text --watch cliphist store")
                hl.exec_cmd("wl-paste --type image --watch cliphist store")
              end'')
          ];
        }
      ];

      # Run on every config load (the hyprlang `exec`).
      exec_cmd = [
        "pgrep waybar || waybar &"
      ];
    };
  };
}
